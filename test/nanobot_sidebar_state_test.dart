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
import 'package:agent_client/features/nanobot/presentation/nanobot_workspace_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets('session list applies and persists sidebar server state', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pinned Roadmap'), findsOneWidget);
    expect(find.text('Active Chat'), findsWidgets);
    expect(find.text('Archived Chat'), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NanobotWorkspacePage)),
    );
    expect(
      container
          .read(nanobotWorkspaceControllerProvider)
          .visibleSessions
          .map((session) => session.key),
      ['websocket:chat-2', 'websocket:chat-1'],
    );

    await tester.tap(find.text('Show archived'));
    await tester.pumpAndSettle();

    expect(find.text('Archived Chat'), findsOneWidget);
    expect(repository.persistedSidebarState?.showArchived, isTrue);

    await container
        .read(nanobotWorkspaceControllerProvider.notifier)
        .toggleSessionPinned('websocket:chat-1');

    expect(repository.persistedSidebarState?.pinnedKeys, [
      'websocket:chat-2',
      'websocket:chat-1',
    ]);
  });
}

class _FakeNanobotRepository implements NanobotRepositoryPort {
  final _events = StreamController<NanobotEvent>.broadcast();
  final _status = StreamController<NanobotSocketStatus>.broadcast();
  NanobotSidebarState? persistedSidebarState;

  final _sessions = [
    NanobotSessionSummary(
      key: 'websocket:chat-1',
      channel: 'websocket',
      chatId: 'chat-1',
      title: 'Active Chat',
      preview: 'Active preview',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(3000),
    ),
    NanobotSessionSummary(
      key: 'websocket:chat-2',
      channel: 'websocket',
      chatId: 'chat-2',
      title: 'Roadmap',
      preview: 'Roadmap preview',
      createdAt: DateTime.fromMillisecondsSinceEpoch(2000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(2000),
    ),
    NanobotSessionSummary(
      key: 'websocket:chat-3',
      channel: 'websocket',
      chatId: 'chat-3',
      title: 'Archived Chat',
      preview: 'Archived preview',
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

  @override
  Future<NanobotBootstrap> bootstrap({bool forceRefresh = false}) async {
    return NanobotBootstrap(
      token: 'token',
      wsPath: '/',
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      modelName: 'MiniMax-M3',
    );
  }

  @override
  Future<void> connect() async {}

  @override
  Future<List<NanobotSessionSummary>> listSessions() async => _sessions;

  @override
  Future<List<NanobotMessage>> fetchThread(
    NanobotSessionSummary session,
  ) async {
    return const [];
  }

  @override
  Future<String> newChat() async => 'chat-1';

  @override
  Future<void> attach(String chatId) async {}

  @override
  Future<void> sendMessage({
    required String chatId,
    required String content,
  }) async {}

  @override
  Future<NanobotSidebarState> fetchSidebarState() async {
    return const NanobotSidebarState(
      pinnedKeys: ['websocket:chat-2'],
      archivedKeys: ['websocket:chat-3'],
      titleOverrides: {'websocket:chat-2': 'Pinned Roadmap'},
    );
  }

  @override
  Future<NanobotSidebarState> updateSidebarState(
    NanobotSidebarState state,
  ) async {
    persistedSidebarState = state;
    return state;
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
  Future<void> dispose() async {
    await _events.close();
    await _status.close();
  }
}
