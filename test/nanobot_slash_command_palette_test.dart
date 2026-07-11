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
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets('composer slash command palette inserts a selected command', (
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

    await tester.enterText(find.byType(TextField).last, '/');
    await tester.pumpAndSettle();

    expect(find.text('Stop current task'), findsOneWidget);
    expect(find.text('Cancel the active agent turn.'), findsOneWidget);
    expect(find.text('/stop'), findsOneWidget);

    await tester.tap(find.text('Stop current task'));
    await tester.pumpAndSettle();

    final input = tester.widget<TextField>(find.byType(TextField).last);
    expect(input.controller?.text, '/stop');
  });

  testWidgets('composer skill palette inserts a selected skill mention', (
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

    await tester.enterText(find.byType(TextField).last, r'$');
    await tester.pumpAndSettle();

    expect(find.text('browser'), findsOneWidget);
    expect(find.text('Search and inspect pages.'), findsOneWidget);
    expect(find.text(r'$browser'), findsOneWidget);

    await tester.tap(find.text('browser'));
    await tester.pumpAndSettle();

    final input = tester.widget<TextField>(find.byType(TextField).last);
    expect(input.controller?.text, r'$browser ');
  });

  testWidgets('composer capability palette inserts a selected CLI mention', (
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

    await tester.enterText(find.byType(TextField).last, '@g');
    await tester.pumpAndSettle();

    expect(find.text('GIMP'), findsOneWidget);
    expect(find.text('Image editing'), findsOneWidget);
    expect(find.text('@gimp'), findsOneWidget);
    expect(find.text('CLI'), findsOneWidget);
    expect(find.text('Krita'), findsNothing);

    await tester.tap(find.text('GIMP'));
    await tester.pumpAndSettle();

    final input = tester.widget<TextField>(find.byType(TextField).last);
    expect(input.controller?.text, '@gimp ');
  });

  testWidgets('composer slash palette supports arrow and enter selection', (
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

    await tester.enterText(find.byType(TextField).last, '/');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    final input = tester.widget<TextField>(find.byType(TextField).last);
    expect(input.controller?.text, '/history ');
  });

  testWidgets('composer mention palettes support tab completion', (
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

    await tester.enterText(find.byType(TextField).last, r'$br');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    var input = tester.widget<TextField>(find.byType(TextField).last);
    expect(input.controller?.text, r'$browser ');

    await tester.enterText(find.byType(TextField).last, '@bro');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    input = tester.widget<TextField>(find.byType(TextField).last);
    expect(input.controller?.text, '@browserbase ');
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
    return const [
      NanobotSlashCommand(
        command: '/stop',
        title: 'Stop current task',
        description: 'Cancel the active agent turn.',
        icon: 'square',
        lifecycle: 'stop_active_turn',
      ),
      NanobotSlashCommand(
        command: '/history',
        title: 'Show conversation history',
        description: 'Print the last N persisted messages.',
        icon: 'history',
        argHint: '[n]',
        lifecycle: 'side_channel',
        acceptsArgs: true,
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
  Future<NanobotProviderModelCatalog> fetchProviderModels(
    String provider,
  ) async {
    return NanobotProviderModelCatalog(
      provider: provider,
      label: provider,
      status: 'available',
      catalogKind: 'official',
    );
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
  Future<NanobotSettingsSnapshot> saveTranscriptionSettings({
    required bool enabled,
    required String provider,
    required String model,
    required String language,
    required int maxDurationSec,
    required int maxUploadMb,
  }) async {
    return const NanobotSettingsSnapshot();
  }

  @override
  Future<NanobotSettingsSnapshot> saveNetworkSafetySettings({
    required bool webuiAllowLocalServiceAccess,
    required String webuiDefaultAccessMode,
  }) async {
    return const NanobotSettingsSnapshot();
  }

  @override
  Future<NanobotSettingsSnapshot> saveRuntimeSettings({
    required String timezone,
    required String botName,
    required String botIcon,
  }) async {
    return const NanobotSettingsSnapshot();
  }

  @override
  Future<NanobotSettingsSnapshot> saveModelSettings({
    required String modelPreset,
    String? model,
    String? provider,
    int? contextWindowTokens,
  }) async {
    return const NanobotSettingsSnapshot();
  }

  @override
  Future<NanobotSettingsSnapshot> createModelConfiguration({
    required String label,
    required String provider,
    required String model,
  }) async {
    return const NanobotSettingsSnapshot();
  }

  @override
  Future<NanobotSettingsSnapshot> updateModelConfiguration({
    required String name,
    required String label,
    required String provider,
    required String model,
    int? contextWindowTokens,
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
    return const [
      NanobotCatalogItem(
        id: 'browser',
        title: 'browser',
        subtitle: 'Search and inspect pages.',
        status: 'available',
      ),
    ];
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
        kind: NanobotCapabilityMentionKind.cli,
        name: 'krita',
        displayName: 'Krita',
        category: 'image',
        description: 'Painting',
        entryPoint: 'cli-anything-krita',
        installed: false,
        status: 'not_installed',
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
      ),
    ];
  }

  @override
  Future<void> dispose() async {
    await _events.close();
    await _status.close();
  }
}
