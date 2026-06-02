import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/data/agent_control_agent_registry_repository.dart';
import 'package:agent_client/features/agents/data/agent_avatar_store.dart';
import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:agent_client/features/agents/domain/agent_registry_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final agentRegistryRepositoryProvider = Provider<AgentRegistryRepository>((
  ref,
) {
  return LocalAvatarAgentRegistryRepository(
    delegate: AgentControlAgentRegistryRepository(
      ref.watch(agentControlApiClientProvider),
    ),
    avatarStore: ref.watch(agentAvatarStoreProvider),
  );
});

class LocalAvatarAgentRegistryRepository implements AgentRegistryRepository {
  const LocalAvatarAgentRegistryRepository({
    required this.delegate,
    required this.avatarStore,
  });

  final AgentRegistryRepository delegate;
  final AgentAvatarStore avatarStore;

  @override
  Future<List<Agent>> listAgents() async {
    final agents = await delegate.listAgents();
    final avatarUrls = await avatarStore.loadAvatarUrls();
    return [
      for (final agent in agents)
        if (avatarUrls[agent.id] case final avatarUrl?)
          agent.copyWith(avatarUrl: avatarUrl)
        else
          agent,
    ];
  }

  @override
  Future<Agent> createAgent({
    required String name,
    String? description,
    String? avatarUrl,
  }) async {
    final created = await delegate.createAgent(
      name: name,
      description: description,
    );
    final trimmedAvatarUrl = avatarUrl?.trim();
    if (trimmedAvatarUrl == null || trimmedAvatarUrl.isEmpty) {
      return created;
    }

    await avatarStore.saveAvatar(
      agentId: created.id,
      agentName: created.name,
      avatarUrl: trimmedAvatarUrl,
      status: created.status,
    );
    return created.copyWith(avatarUrl: trimmedAvatarUrl);
  }

  @override
  Future<void> updateAgentAvatar({
    required Agent agent,
    required String avatarUrl,
  }) async {
    await delegate.updateAgentAvatar(agent: agent, avatarUrl: avatarUrl);
    final trimmedAvatarUrl = avatarUrl.trim();
    if (trimmedAvatarUrl.isEmpty) {
      return;
    }
    await avatarStore.saveAvatar(
      agentId: agent.id,
      agentName: agent.name,
      avatarUrl: trimmedAvatarUrl,
      status: agent.status,
    );
  }

  @override
  Future<void> deleteAgent(String agentId) async {
    await delegate.deleteAgent(agentId);
    await avatarStore.deleteAvatar(agentId);
  }
}
