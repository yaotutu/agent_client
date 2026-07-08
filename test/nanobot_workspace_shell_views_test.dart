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
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets('sidebar utility entries switch to secondary webui surfaces', (
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

    final appsTop = tester.getTopLeft(find.text('Apps').first).dy;
    final skillsTop = tester.getTopLeft(find.text('Skills').first).dy;
    final automationsTop = tester.getTopLeft(find.text('Automations').first).dy;
    expect(appsTop, lessThan(skillsTop));
    expect(skillsTop, lessThan(automationsTop));

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('MiniMax-M3'), findsOneWidget);
    expect(find.text('openai'), findsOneWidget);

    await tester.tap(find.text('Apps'));
    await tester.pumpAndSettle();
    expect(find.text('Apps'), findsWidgets);
    expect(find.text('GIMP'), findsOneWidget);
    expect(find.text('installed'), findsOneWidget);

    await tester.tap(find.text('Automations'));
    await tester.pumpAndSettle();
    expect(find.text('Automations'), findsWidgets);
    expect(find.text('Daily ping'), findsOneWidget);
    expect(find.text('enabled'), findsOneWidget);

    await tester.tap(find.text('Skills'));
    await tester.pumpAndSettle();
    expect(find.text('Skills'), findsWidgets);
    expect(find.text('browser'), findsOneWidget);
    expect(find.text('available'), findsOneWidget);

    await tester.tap(find.text('Chats'));
    await tester.pumpAndSettle();
    final state = ProviderScope.containerOf(
      tester.element(find.byType(NanobotWorkspacePage)),
    ).read(nanobotWorkspaceControllerProvider);
    expect(state.activeView, NanobotShellView.chat);
    expect(find.text('Start a chat'), findsOneWidget);
  });

  testWidgets('automations empty surface keeps heading and webui empty copy', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(automationItems: const []);
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Automations'));
    await tester.pumpAndSettle();

    expect(find.text('Automations'), findsWidgets);
    expect(find.text('No automations yet.'), findsOneWidget);
    expect(find.text('No automations'), findsNothing);
  });
}

class _FakeNanobotRepository implements NanobotRepositoryPort {
  _FakeNanobotRepository({
    List<NanobotCatalogItem>? appItems,
    List<NanobotCatalogItem>? automationItems,
    List<NanobotCatalogItem>? skillItems,
  }) : _appItems = appItems ?? _defaultAppItems,
       _automationItems = automationItems ?? _defaultAutomationItems,
       _skillItems = skillItems ?? _defaultSkillItems;

  final _events = StreamController<NanobotEvent>.broadcast();
  final _status = StreamController<NanobotSocketStatus>.broadcast();
  final List<NanobotCatalogItem> _appItems;
  final List<NanobotCatalogItem> _automationItems;
  final List<NanobotCatalogItem> _skillItems;
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
  Future<NanobotSettingsSnapshot> fetchSettingsSnapshot() async {
    return const NanobotSettingsSnapshot(
      model: 'MiniMax-M3',
      provider: 'openai',
      totalTokens: 42,
      requiresRestart: false,
    );
  }

  @override
  Future<List<NanobotCatalogItem>> fetchAppItems() async {
    return _appItems;
  }

  @override
  Future<List<NanobotCatalogItem>> fetchAutomationItems() async {
    return _automationItems;
  }

  @override
  Future<List<NanobotCatalogItem>> fetchSkillItems() async {
    return _skillItems;
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

  static const _defaultAppItems = [
    NanobotCatalogItem(
      id: 'gimp',
      title: 'GIMP',
      subtitle: 'Image editor',
      status: 'installed',
    ),
  ];

  static const _defaultAutomationItems = [
    NanobotCatalogItem(
      id: 'job-1',
      title: 'Daily ping',
      subtitle: 'cron',
      status: 'enabled',
    ),
  ];

  static const _defaultSkillItems = [
    NanobotCatalogItem(
      id: 'browser',
      title: 'browser',
      subtitle: 'Browse',
      status: 'available',
    ),
  ];
}
