import 'dart:async';

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
  testWidgets('composer workspace scope mirrors webui access controls', (
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

    expect(find.text('nanobot'), findsOneWidget);
    expect(find.text('Default Permission'), findsOneWidget);

    await tester.tap(find.text('Default Permission'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full Access').last);
    await tester.pumpAndSettle();

    expect(repository.workspaceChatId, 'chat-1');
    expect(repository.workspaceScope?['access_mode'], 'full');
    expect(repository.workspaceScope?['restrict_to_workspace'], isFalse);
    expect(find.text('Full Access'), findsOneWidget);

    repository.emit({
      'event': 'error',
      'detail': 'workspace_scope_rejected',
      'reason': 'outside workspace',
    });
    await tester.pumpAndSettle();

    expect(
      find.text('Workspace scope was rejected. Choose another project.'),
      findsOneWidget,
    );
  });

  testWidgets('workspace project picker validates and applies manual paths', (
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

    await tester.tap(find.text('nanobot'));
    await tester.pumpAndSettle();

    expect(find.text('Default workspace'), findsOneWidget);
    expect(find.text('/home/yaotutu/Desktop/code/nanobot'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'relative/path');
    await tester.tap(find.text('Use Path'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter an absolute folder path on this machine.'),
      findsOneWidget,
    );
    expect(repository.workspaceScope, isNull);

    await tester.enterText(find.byType(TextField).last, '/tmp/nanobot-app');
    await tester.tap(find.text('Use Path'));
    await tester.pumpAndSettle();

    expect(repository.workspaceChatId, 'chat-1');
    expect(repository.workspaceScope?['project_path'], '/tmp/nanobot-app');
    expect(repository.workspaceScope?['project_name'], 'nanobot-app');
    expect(repository.workspaceScope?['access_mode'], 'restricted');
    expect(repository.workspaceScope?['restrict_to_workspace'], isTrue);
    expect(find.text('nanobot-app'), findsOneWidget);
  });
}

class _FakeNanobotRepository implements NanobotRepositoryPort {
  final _events = StreamController<NanobotEvent>.broadcast();
  final _status = StreamController<NanobotSocketStatus>.broadcast();
  String? workspaceChatId;
  Map<String, Object?>? workspaceScope;

  final _sessions = [
    NanobotSessionSummary(
      key: 'websocket:chat-1',
      channel: 'websocket',
      chatId: 'chat-1',
      title: 'Workspace Chat',
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
  Future<NanobotWorkspaceSnapshot> fetchWorkspacesSnapshot() async {
    return const NanobotWorkspaceSnapshot(
      defaultScope: NanobotWorkspaceScope(
        projectPath: '/home/yaotutu/Desktop/code/nanobot',
        projectName: 'nanobot',
        accessMode: 'restricted',
        restrictToWorkspace: true,
      ),
      controls: {'can_change_project': true, 'can_use_full_access': true},
    );
  }

  @override
  Future<void> setWorkspaceScope({
    required String chatId,
    required NanobotWorkspaceScope workspaceScope,
  }) async {
    workspaceChatId = chatId;
    this.workspaceScope = workspaceScope.toJson();
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
    return const NanobotSettingsSnapshot();
  }

  @override
  Future<NanobotVersionCheckResult> checkVersion() async {
    return const NanobotVersionCheckResult.upToDate();
  }

  @override
  Future<NanobotSettingsSnapshot> saveWebSearchSettings({
    required String provider,
    required int maxResults,
    required int timeoutSeconds,
    required bool useJinaReader,
  }) async {
    return const NanobotSettingsSnapshot();
  }

  @override
  Future<NanobotSettingsSnapshot> saveImageGenerationSettings({
    required bool enabled,
    required String provider,
    required String model,
    required String defaultAspectRatio,
    required String defaultImageSize,
    required int maxImagesPerTurn,
  }) async {
    return const NanobotSettingsSnapshot();
  }

  @override
  Future<List<NanobotCatalogItem>> fetchAppItems() async {
    return const [];
  }

  @override
  Future<NanobotAppsActionResult> runCliAppAction({
    required String action,
    required String name,
  }) async {
    return const NanobotAppsActionResult(items: []);
  }

  @override
  Future<NanobotAppsActionResult> runNanobotFeatureAction({
    required String action,
    required String name,
  }) async {
    return const NanobotAppsActionResult(items: []);
  }

  @override
  Future<NanobotAppsActionResult> runMcpPresetAction({
    required String action,
    required String name,
    Map<String, Object?> values = const {},
  }) async {
    return const NanobotAppsActionResult(items: []);
  }

  @override
  Future<NanobotAppsActionResult> updateMcpServerTools({
    required String name,
    required List<String> enabledTools,
  }) async {
    return const NanobotAppsActionResult(items: []);
  }

  @override
  Future<NanobotAppsActionResult> saveCustomMcpServer({
    required Map<String, Object?> values,
  }) async {
    return const NanobotAppsActionResult(items: []);
  }

  @override
  Future<NanobotAppsActionResult> importMcpConfig(String config) async {
    return const NanobotAppsActionResult(items: []);
  }

  @override
  Future<List<NanobotCatalogItem>> fetchAutomationItems() async {
    return const [];
  }

  @override
  Future<List<NanobotCatalogItem>> runAutomationAction({
    required NanobotAutomationAction action,
    required String id,
  }) async {
    return const [];
  }

  @override
  Future<List<NanobotCatalogItem>> updateAutomation({
    required String id,
    required Map<String, Object?> values,
  }) async {
    return const [];
  }

  @override
  Future<List<NanobotCatalogItem>> fetchSkillItems() async {
    return const [];
  }

  @override
  Future<NanobotSkillDetail> fetchSkillDetail(String name) async {
    return NanobotSkillDetail(
      name: name,
      description: '',
      source: 'builtin',
      available: true,
    );
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
