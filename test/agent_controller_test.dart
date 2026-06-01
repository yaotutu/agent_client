import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/domain/agent_control_models.dart';
import 'package:agent_client/features/agents/application/agent_controller.dart';
import 'package:agent_client/features/agents/data/agent_avatar_store.dart';
import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:agent_client/features/agents/domain/agent_avatar.dart';
import 'package:agent_client/features/chat/application/chat_controller.dart';
import 'package:agent_client/features/chat/application/chat_sessions_controller.dart';
import 'package:agent_client/features/chat/data/chat_cache_provider.dart';
import 'package:agent_client/features/chat/data/chat_cache_store.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:agent_client/features/chat/domain/chat_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test(
    'createAgent creates through backend, refreshes list, and selects it',
    () async {
      final api = _FakeAgentControlApi([
        _agentSummary('nanobot', description: '代码审查助手'),
      ]);
      final container = ProviderContainer(
        overrides: [
          agentControlApiClientProvider.overrideWithValue(api),
          agentAvatarStoreProvider.overrideWithValue(_FakeAgentAvatarStore()),
          chatCacheStoreProvider.overrideWithValue(InMemoryChatCacheStore()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        (await container.read(agentsProvider.future)).single.id,
        'nanobot',
      );

      await container
          .read(currentAgentIdProvider.notifier)
          .createAgent(name: 'reviewer', description: '代码审查助手');

      final agents = await container.read(agentsProvider.future);
      expect(api.createdName, 'reviewer');
      expect(api.createdDescription, '代码审查助手');
      expect(agents.map((agent) => agent.id), contains('reviewer'));
      expect(
        agents.singleWhere((agent) => agent.id == 'nanobot').description,
        '代码审查助手',
      );
      expect(
        agents.singleWhere((agent) => agent.id == 'reviewer').description,
        '代码审查助手',
      );
      expect(container.read(currentAgentIdProvider), 'reviewer');
    },
  );

  test(
    'createAgent stores the selected avatar and merges it into refreshed agents',
    () async {
      final api = _FakeAgentControlApi([
        _agentSummary('nanobot', description: '代码审查助手'),
      ]);
      final avatarStore = _FakeAgentAvatarStore();
      final container = ProviderContainer(
        overrides: [
          agentControlApiClientProvider.overrideWithValue(api),
          agentAvatarStoreProvider.overrideWithValue(avatarStore),
          chatCacheStoreProvider.overrideWithValue(InMemoryChatCacheStore()),
        ],
      );
      addTearDown(container.dispose);

      final avatar = AgentAvatarOptions.defaults.first.assetPath;
      await container
          .read(currentAgentIdProvider.notifier)
          .createAgent(
            name: 'reviewer',
            description: '代码审查助手',
            avatarUrl: avatar,
          );

      final agents = await container.read(agentsProvider.future);
      expect(api.createdName, 'reviewer');
      expect(api.createdDescription, '代码审查助手');
      expect(avatarStore.avatarFor('reviewer'), avatar);
      expect(
        agents.singleWhere((agent) => agent.id == 'reviewer').avatarUrl,
        avatar,
      );
      expect(container.read(currentAgentIdProvider), 'reviewer');
    },
  );

  test(
    'deleteAgent deletes through backend and selects the first remaining agent',
    () async {
      final api = _FakeAgentControlApi([
        _agentSummary('nanobot'),
        _agentSummary('reviewer'),
      ]);
      final container = ProviderContainer(
        overrides: [
          agentControlApiClientProvider.overrideWithValue(api),
          agentAvatarStoreProvider.overrideWithValue(_FakeAgentAvatarStore()),
          chatCacheStoreProvider.overrideWithValue(InMemoryChatCacheStore()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(agentsProvider.future);
      container.read(currentAgentIdProvider.notifier).selectAgent('reviewer');

      await container
          .read(currentAgentIdProvider.notifier)
          .deleteAgent('reviewer');

      final agents = await container.read(agentsProvider.future);
      expect(api.deletedName, 'reviewer');
      expect(agents.map((agent) => agent.id), ['nanobot']);
      expect(container.read(currentAgentIdProvider), 'nanobot');
    },
  );

  test(
    'deleteAgent clears local chat cache and chat state for deleted agent',
    () async {
      final api = _FakeAgentControlApi([
        _agentSummary('nanobot'),
        _agentSummary('reviewer'),
      ]);
      final cache = InMemoryChatCacheStore();
      final container = ProviderContainer(
        overrides: [
          agentControlApiClientProvider.overrideWithValue(api),
          agentAvatarStoreProvider.overrideWithValue(_FakeAgentAvatarStore()),
          chatCacheStoreProvider.overrideWithValue(cache),
        ],
      );
      addTearDown(container.dispose);

      await cache.saveMessage(
        ChatMessage(
          id: 'reviewer-message',
          agentId: 'reviewer',
          conversationId: 'reviewer-session',
          role: ChatRole.assistant,
          content: 'Old reviewer chat',
          status: ChatMessageStatus.completed,
          createdAt: DateTime(2026, 5, 28),
        ),
      );
      await cache.saveMessage(
        ChatMessage(
          id: 'nanobot-message',
          agentId: 'nanobot',
          conversationId: 'nanobot-session',
          role: ChatRole.assistant,
          content: 'Keep nanobot chat',
          status: ChatMessageStatus.completed,
          createdAt: DateTime(2026, 5, 28, 1),
        ),
      );
      await container
          .read(chatControllerProvider('reviewer').notifier)
          .loadRecentMessages();
      container
          .read(chatSessionsProvider('reviewer').notifier)
          .insertSession(
            const ChatSessionSummary(
              id: 'reviewer-session',
              title: 'Old reviewer chat',
              preview: 'Old reviewer chat',
              messageCount: 1,
            ),
          );

      expect(
        container.read(chatControllerProvider('reviewer')).messages.single.id,
        'reviewer-message',
      );
      expect(
        container.read(chatSessionsProvider('reviewer')).sessions.single.id,
        'reviewer-session',
      );

      await container
          .read(currentAgentIdProvider.notifier)
          .deleteAgent('reviewer');

      expect(api.deletedName, 'reviewer');
      expect(await cache.loadLatestMessages('reviewer'), isEmpty);
      expect(await cache.loadLatestMessages('nanobot'), isNotEmpty);
      expect(
        container.read(chatControllerProvider('reviewer')).messages,
        isEmpty,
      );
      expect(
        container.read(chatSessionsProvider('reviewer')).sessions,
        isEmpty,
      );
    },
  );
}

AgentSummary _agentSummary(String name, {String? description}) {
  return AgentSummary(
    name: name,
    description: description,
    wsPort: 8760,
    gatewayPort: 18760,
    workspaceDir: '/workspace/$name',
    status: 'running',
    health: 'healthy',
    model: 'MiniMax-M2.7-highspeed',
    provider: 'minimax',
  );
}

class _FakeAgentControlApi extends Fake implements AgentControlApi {
  _FakeAgentControlApi(this._agents);

  final List<AgentSummary> _agents;
  String? createdName;
  String? createdDescription;
  String? deletedName;

  @override
  Future<AgentListResponse> listAgents() async {
    return AgentListResponse(object: 'list', data: List.of(_agents));
  }

  @override
  Future<CreateAgentResponse> createAgent({
    required String name,
    String? description,
  }) async {
    createdName = name;
    createdDescription = description;
    _agents.add(_agentSummary(name, description: description));
    return CreateAgentResponse(
      name: name,
      wsPort: 8761,
      gatewayPort: 18761,
      configPath: '/agents/$name/config.json',
      workspaceDir: '/workspace/$name',
      status: 'stopped',
      model: 'MiniMax-M2.7-highspeed',
      provider: 'minimax',
    );
  }

  @override
  Future<DeleteAgentResponse> deleteAgent(String agentName) async {
    deletedName = agentName;
    _agents.removeWhere((agent) => agent.name == agentName);
    return DeleteAgentResponse(deleted: true, name: agentName);
  }
}

class _FakeAgentAvatarStore implements AgentAvatarStore {
  final _avatars = <String, String>{};

  String? avatarFor(String agentId) => _avatars[agentId];

  @override
  Future<Map<String, String>> loadAvatarUrls() async {
    return Map.of(_avatars);
  }

  @override
  Future<void> saveAvatar({
    required String agentId,
    required String agentName,
    required String avatarUrl,
    required AgentStatus status,
  }) async {
    _avatars[agentId] = avatarUrl;
  }

  @override
  Future<void> deleteAvatar(String agentId) async {
    _avatars.remove(agentId);
  }
}
