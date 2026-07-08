import 'dart:async';

import 'package:agent_client/features/nanobot/application/nanobot_workspace_controller.dart';
import 'package:agent_client/features/nanobot/data/nanobot_providers.dart';
import 'package:agent_client/features/nanobot/data/nanobot_repository.dart';
import 'package:agent_client/features/nanobot/data/nanobot_ws_client.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_bootstrap.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_event.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_media_attachment.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_message.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_shell_models.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_thread_page.dart';
import 'package:agent_client/features/nanobot/presentation/nanobot_workspace_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('session action menu persists pin archive and rename', (
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
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NanobotWorkspacePage)),
    );

    await tester.tap(find.byTooltip('Actions for Active Chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pin'));
    await tester.pumpAndSettle();

    expect(repository.persistedSidebarState?.pinnedKeys, [
      'websocket:chat-2',
      'websocket:chat-1',
    ]);

    await tester.tap(find.byTooltip('Actions for Active Chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(repository.persistedSidebarState?.pinnedKeys, ['websocket:chat-2']);
    expect(repository.persistedSidebarState?.archivedKeys, [
      'websocket:chat-3',
      'websocket:chat-1',
    ]);
    expect(
      container.read(nanobotWorkspaceControllerProvider).selectedSessionKey,
      'websocket:chat-2',
    );

    await tester.tap(find.byTooltip('Actions for Pinned Roadmap'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    expect(find.text('Rename chat'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Roadmap v2');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.persistedSidebarState?.titleOverrides, {
      'websocket:chat-2': 'Roadmap v2',
    });
    expect(find.text('Roadmap v2'), findsOneWidget);
  });

  testWidgets('session action menu confirms and deletes a session', (
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
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NanobotWorkspacePage)),
    );

    await tester.tap(find.byTooltip('Actions for Active Chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete this chat?'), findsOneWidget);
    expect(find.text('This action cannot be undone.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repository.deletedSessionKey, 'websocket:chat-1');
    expect(find.text('Active Chat'), findsNothing);
    expect(
      container.read(nanobotWorkspaceControllerProvider).selectedSessionKey,
      'websocket:chat-2',
    );
  });

  testWidgets('sidebar search filters sessions and selects a result', (
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
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NanobotWorkspacePage)),
    );

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(find.text('Recent'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'road');
    await tester.pumpAndSettle();

    expect(find.text('Results'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Pinned Roadmap'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Active Chat'), findsNothing);

    await tester.tap(find.text('Pinned Roadmap').last);
    await tester.pumpAndSettle();

    expect(find.text('Results'), findsNothing);
    expect(
      container.read(nanobotWorkspaceControllerProvider).selectedSessionKey,
      'websocket:chat-2',
    );
  });

  testWidgets('session search opens from ctrl k keyboard shortcut', (
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

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.text('Recent'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'road');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Pinned Roadmap'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Active Chat'), findsNothing);
  });
}

class _FakeNanobotRepository implements NanobotRepositoryPort {
  final _events = StreamController<NanobotEvent>.broadcast();
  final _status = StreamController<NanobotSocketStatus>.broadcast();
  NanobotSidebarState? persistedSidebarState;
  String? deletedSessionKey;

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
  Future<List<NanobotSlashCommand>> listSlashCommands() async {
    return const [];
  }

  @override
  Future<List<NanobotMessage>> fetchThread(
    NanobotSessionSummary session,
  ) async {
    return const [];
  }

  @override
  Future<NanobotThreadPage> fetchThreadPage(
    NanobotSessionSummary session, {
    int limit = 120,
    String? before,
  }) async {
    return NanobotThreadPage(messages: await fetchThread(session));
  }

  @override
  Future<NanobotFilePreview> fetchFilePreview({
    required String sessionKey,
    required String path,
  }) async {
    return NanobotFilePreview(
      path: path,
      displayPath: path,
      projectPath: '',
      language: '',
      content: '',
      size: 0,
      truncated: false,
    );
  }

  @override
  Future<String> newChat({NanobotWorkspaceScope? workspaceScope}) async =>
      'chat-1';

  @override
  Future<void> attach(String chatId) async {}

  @override
  Future<void> sendMessage({
    required String chatId,
    required String content,
    List<NanobotSendMedia> media = const [],
    List<NanobotCapabilityMention> cliApps = const [],
    List<NanobotCapabilityMention> mcpPresets = const [],
  }) async {}

  @override
  Future<String> forkChat({
    required String sourceChatId,
    required int beforeUserIndex,
    String? title,
  }) async {
    return 'chat-fork';
  }

  @override
  Future<String> transcribeAudio({
    required String requestId,
    required String dataUrl,
    int? durationMs,
  }) async {
    return '';
  }

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
  Future<NanobotSessionDeleteResult> deleteSession({
    required String sessionKey,
    bool deleteAutomations = false,
  }) async {
    deletedSessionKey = sessionKey;
    _sessions.removeWhere((session) => session.key == sessionKey);
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
    return const [];
  }

  @override
  Future<void> dispose() async {
    await _events.close();
    await _status.close();
  }
}
