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
}

class _FakeNanobotRepository implements NanobotRepositoryPort {
  final _events = StreamController<NanobotEvent>.broadcast();
  final _status = StreamController<NanobotSocketStatus>.broadcast();
  final _sessions = [
    NanobotSessionSummary(
      key: 'websocket:chat-1',
      channel: 'websocket',
      chatId: 'chat-1',
      preview: '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
  ];

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
  Future<String> newChat() async => 'chat-1';

  @override
  Future<void> sendMessage({
    required String chatId,
    required String content,
  }) async {}

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
  Future<void> dispose() async {
    await _events.close();
    await _status.close();
  }
}
