import 'dart:async';

import 'package:agent_client/features/nanobot/application/nanobot_workspace_controller.dart';
import 'package:agent_client/features/nanobot/data/nanobot_providers.dart';
import 'package:agent_client/features/nanobot/data/nanobot_repository.dart';
import 'package:agent_client/features/nanobot/data/nanobot_ws_client.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_bootstrap.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_event.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_message.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_shell_models.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_thread_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('workspace controller reduces live events into thread state', () async {
    final repository = _FakeNanobotRepository();
    final container = ProviderContainer(
      overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    addTearDown(repository.dispose);

    container.read(nanobotWorkspaceControllerProvider);
    await pumpEventQueue();

    repository.emit({
      'event': 'reasoning_delta',
      'chat_id': 'chat-1',
      'text': 'think',
      'turn_id': 'turn-1',
    });
    repository.emit({
      'event': 'delta',
      'chat_id': 'chat-1',
      'text': 'answer',
      'turn_id': 'turn-1',
    });
    repository.emit({
      'event': 'message',
      'chat_id': 'chat-1',
      'kind': 'tool_hint',
      'text': 'read file',
      'tool_events': [
        {'name': 'read_file', 'phase': 'start'},
      ],
    });
    repository.emit({
      'event': 'turn_end',
      'chat_id': 'chat-1',
      'latency_ms': 77,
    });
    await pumpEventQueue();

    final state = container.read(nanobotWorkspaceControllerProvider);
    expect(state.threadState?.isStreaming, isFalse);
    expect(state.threadState?.entries, hasLength(2));
    expect(state.threadState?.entries.first.reasoning, 'think');
    expect(state.threadState?.entries.first.content, 'answer');
    expect(state.threadState?.entries.first.latencyMs, 77);
    expect(state.threadState?.entries.last.kind, NanobotThreadEntryKind.trace);
    expect(state.threadState?.entries.last.traces, ['read file']);
    expect(state.messages, hasLength(1));
    expect(state.messages.single.content, 'answer');
    expect(state.messages.single.reasoning, 'think');
    expect(state.isStreaming, isFalse);
  });

  test(
    'workspace controller sends draft workspace scope with new chat',
    () async {
      final repository = _FakeNanobotRepository(sessions: const []);
      final container = ProviderContainer(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      final controller = container.read(
        nanobotWorkspaceControllerProvider.notifier,
      );
      container.read(nanobotWorkspaceControllerProvider);
      await pumpEventQueue();

      await controller.applyWorkspaceProjectPath('/tmp/custom-project');
      await controller.sendMessage('hello');

      expect(
        repository.newChatWorkspaceScope?['project_path'],
        '/tmp/custom-project',
      );
      expect(
        repository.newChatWorkspaceScope?['project_name'],
        'custom-project',
      );
      expect(repository.newChatWorkspaceScope?['access_mode'], 'restricted');
      expect(
        repository.newChatWorkspaceScope?['restrict_to_workspace'],
        isTrue,
      );
      expect(repository.sentChatId, 'chat-1');
      expect(repository.sentContent, 'hello');
    },
  );

  test('workspace controller sends capability mention metadata', () async {
    final repository = _FakeNanobotRepository();
    final container = ProviderContainer(
      overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    addTearDown(repository.dispose);

    final controller = container.read(
      nanobotWorkspaceControllerProvider.notifier,
    );
    container.read(nanobotWorkspaceControllerProvider);
    await pumpEventQueue();

    await controller.sendMessage('use @gimp with @browserbase and @gimp');

    expect(repository.sentContent, 'use @gimp with @browserbase and @gimp');
    expect(repository.sentCliApps, hasLength(1));
    expect(repository.sentCliApps.single.name, 'gimp');
    expect(repository.sentCliApps.single.displayName, 'GIMP');
    expect(repository.sentCliApps.single.category, 'image');
    expect(repository.sentCliApps.single.entryPoint, 'cli-anything-gimp');
    expect(repository.sentCliApps.single.status, 'installed');
    expect(repository.sentCliApps.single.brandColor, '#5C5543');
    expect(repository.sentMcpPresets, hasLength(1));
    expect(repository.sentMcpPresets.single.name, 'browserbase');
    expect(repository.sentMcpPresets.single.displayName, 'Browserbase');
    expect(repository.sentMcpPresets.single.category, 'browser');
    expect(repository.sentMcpPresets.single.transport, 'streamableHttp');
    expect(repository.sentMcpPresets.single.status, 'configured');
    expect(repository.sentMcpPresets.single.configured, isTrue);
    expect(
      repository.sentMcpPresets.single.logoUrl,
      'https://example.invalid/browserbase.svg',
    );
    expect(repository.sentMcpPresets.single.brandColor, '#111827');
  });

  test(
    'side-channel slash commands do not mark the workspace streaming',
    () async {
      final repository = _FakeNanobotRepository();
      final container = ProviderContainer(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      final controller = container.read(
        nanobotWorkspaceControllerProvider.notifier,
      );
      container.read(nanobotWorkspaceControllerProvider);
      await pumpEventQueue();

      await controller.sendMessage('/history');

      final state = container.read(nanobotWorkspaceControllerProvider);
      expect(repository.sentContent, '/history');
      expect(state.messages.last.content, '/history');
      expect(state.isStreaming, isFalse);
      expect(state.threadState?.isStreaming, isFalse);
    },
  );

  test('finalizing slash commands close the active UI turn', () async {
    final repository = _FakeNanobotRepository();
    final container = ProviderContainer(
      overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    addTearDown(repository.dispose);

    final controller = container.read(
      nanobotWorkspaceControllerProvider.notifier,
    );
    container.read(nanobotWorkspaceControllerProvider);
    await pumpEventQueue();

    await controller.sendMessage('long task');
    expect(
      container.read(nanobotWorkspaceControllerProvider).isStreaming,
      isTrue,
    );

    await controller.sendMessage('/new');

    final state = container.read(nanobotWorkspaceControllerProvider);
    expect(repository.sentContent, '/new');
    expect(state.messages.map((message) => message.content), [
      'long task',
      '/new',
    ]);
    expect(state.isStreaming, isFalse);
    expect(state.threadState?.isStreaming, isFalse);
  });

  test('stop slash command uses stop flow while streaming', () async {
    final repository = _FakeNanobotRepository();
    final container = ProviderContainer(
      overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    addTearDown(repository.dispose);

    final controller = container.read(
      nanobotWorkspaceControllerProvider.notifier,
    );
    container.read(nanobotWorkspaceControllerProvider);
    await pumpEventQueue();

    await controller.sendMessage('long task');
    await controller.sendMessage('/stop');

    final state = container.read(nanobotWorkspaceControllerProvider);
    expect(repository.sentContent, '/stop');
    expect(
      state.messages.map((message) => message.content),
      isNot(contains('/stop')),
    );
    expect(state.isStreaming, isFalse);
  });
}

class _FakeNanobotRepository implements NanobotRepositoryPort {
  _FakeNanobotRepository({List<NanobotSessionSummary>? sessions})
    : _sessions =
          sessions ??
          [
            NanobotSessionSummary(
              key: 'websocket:chat-1',
              channel: 'websocket',
              chatId: 'chat-1',
              preview: '',
              createdAt: DateTime.fromMillisecondsSinceEpoch(0),
              updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
            ),
          ];

  final _events = StreamController<NanobotEvent>.broadcast();
  final _status = StreamController<NanobotSocketStatus>.broadcast();
  final List<NanobotSessionSummary> _sessions;
  Map<String, Object?>? newChatWorkspaceScope;
  String? sentChatId;
  String? sentContent;
  List<NanobotCapabilityMention> sentCliApps = const [];
  List<NanobotCapabilityMention> sentMcpPresets = const [];

  @override
  Stream<NanobotEvent> get events => _events.stream;

  @override
  Stream<NanobotSocketStatus> get status => _status.stream;

  @override
  NanobotSocketStatus get currentStatus => NanobotSocketStatus.open;

  void emit(Map<String, Object?> frame) {
    _events.add(NanobotEvent.fromJson(frame));
  }

  @override
  Future<NanobotBootstrap> bootstrap({bool forceRefresh = false}) async {
    return NanobotBootstrap(
      token: 'token',
      wsPath: '/ws',
      expiresAt: DateTime.fromMillisecondsSinceEpoch(1000),
      modelName: 'model',
    );
  }

  @override
  Future<void> connect() async {}

  @override
  Future<List<NanobotSessionSummary>> listSessions() async => _sessions;

  @override
  Future<List<NanobotSlashCommand>> listSlashCommands() async {
    return const [
      NanobotSlashCommand(
        command: '/history',
        title: 'Show conversation history',
        description: 'Print the last N persisted messages.',
        icon: 'history',
        lifecycle: 'side_channel',
        acceptsArgs: true,
      ),
      NanobotSlashCommand(
        command: '/new',
        title: 'Start new task',
        description: 'Finalize the active turn and begin a new task.',
        icon: 'plus',
        lifecycle: 'finalize_active_turn',
      ),
      NanobotSlashCommand(
        command: '/stop',
        title: 'Stop current task',
        description: 'Cancel the active agent turn.',
        icon: 'square',
        lifecycle: 'stop_active_turn',
      ),
    ];
  }

  @override
  Future<NanobotSidebarState> fetchSidebarState() async {
    return const NanobotSidebarState();
  }

  @override
  Future<NanobotSidebarState> updateSidebarState(
    NanobotSidebarState state,
  ) async {
    return state;
  }

  @override
  Future<NanobotSessionDeleteResult> deleteSession({
    required String sessionKey,
    bool deleteAutomations = false,
  }) async {
    return const NanobotSessionDeleteResult(deleted: true);
  }

  @override
  Future<NanobotWorkspaceSnapshot> fetchWorkspacesSnapshot() async {
    return const NanobotWorkspaceSnapshot(
      defaultScope: NanobotWorkspaceScope(
        projectPath: '/tmp/project',
        accessMode: 'restricted',
      ),
    );
  }

  @override
  Future<void> setWorkspaceScope({
    required String chatId,
    required NanobotWorkspaceScope workspaceScope,
  }) async {}

  @override
  Future<void> attach(String chatId) async {}

  @override
  Future<List<NanobotMessage>> fetchThread(
    NanobotSessionSummary session,
  ) async {
    return const [];
  }

  @override
  Future<String> newChat({NanobotWorkspaceScope? workspaceScope}) async {
    newChatWorkspaceScope = workspaceScope?.toJson();
    return 'chat-1';
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String content,
    List<NanobotCapabilityMention> cliApps = const [],
    List<NanobotCapabilityMention> mcpPresets = const [],
  }) async {
    sentChatId = chatId;
    sentContent = content;
    sentCliApps = cliApps;
    sentMcpPresets = mcpPresets;
  }

  @override
  Future<NanobotSettingsSnapshot> fetchSettingsSnapshot() async {
    return const NanobotSettingsSnapshot();
  }

  @override
  Future<List<NanobotCatalogItem>> fetchAppItems() async {
    return const [];
  }

  @override
  Future<List<NanobotCatalogItem>> fetchAutomationItems() async {
    return const [];
  }

  @override
  Future<List<NanobotCatalogItem>> fetchSkillItems() async {
    return const [];
  }

  @override
  Future<List<NanobotCapabilityMention>> fetchCapabilityMentions() async {
    return const [
      NanobotCapabilityMention(
        kind: NanobotCapabilityMentionKind.cli,
        name: 'gimp',
        displayName: 'GIMP',
        category: 'image',
        description: 'Image editing',
        entryPoint: 'cli-anything-gimp',
        installed: true,
        status: 'installed',
        brandColor: '#5C5543',
      ),
      NanobotCapabilityMention(
        kind: NanobotCapabilityMentionKind.mcp,
        name: 'browserbase',
        displayName: 'Browserbase',
        category: 'browser',
        description: 'Cloud browser automation',
        transport: 'streamableHttp',
        installed: true,
        configured: true,
        status: 'configured',
        logoUrl: 'https://example.invalid/browserbase.svg',
        brandColor: '#111827',
      ),
      NanobotCapabilityMention(
        kind: NanobotCapabilityMentionKind.mcp,
        name: 'figma',
        displayName: 'Figma',
        category: 'design',
        description: 'Design context',
        transport: 'streamableHttp',
        installed: true,
        configured: false,
        status: 'missing_credentials',
      ),
    ];
  }

  @override
  Future<void> dispose() async {
    await _events.close();
    await _status.close();
  }
}
