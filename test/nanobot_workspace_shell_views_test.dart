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
    expect(find.text('Daily ping'), findsWidgets);
    expect(find.text('Active'), findsOneWidget);

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

  testWidgets('automations surface shows message origin and expands details', (
    tester,
  ) async {
    const longMessage =
        'Review the release plan and prepare a concise status update.\n'
        'Include blockers, owners, follow-up dates, and risky assumptions.\n'
        'Keep the output actionable and avoid repeated context.\n'
        'Call out stale dependencies and ask for owner updates.\n'
        'This message is long enough to need progressive disclosure.';
    final repository = _FakeNanobotRepository(
      automationItems: const [
        NanobotCatalogItem(
          id: 'long-details',
          title: 'Long detail automation',
          subtitle: longMessage,
          details: 'Release prep',
          status: 'Active',
        ),
      ],
    );
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

    expect(find.text('Long detail automation'), findsWidgets);
    expect(find.text('Release prep'), findsWidgets);
    expect(find.text('Show full message'), findsWidgets);

    await tester.ensureVisible(find.text('Show full message').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show full message').first);
    await tester.pumpAndSettle();

    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('automations surface filters by message and linked chat', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      automationItems: const [
        NanobotCatalogItem(
          id: 'repo-check',
          title: 'Daily repo check',
          subtitle: 'Check the repo status',
          details: 'Release prep',
          status: 'Active',
        ),
        NanobotCatalogItem(
          id: 'wechat-quiz',
          title: 'WeChat quiz',
          subtitle: 'Send a quiz',
          details: 'WeChat',
          status: 'Active',
        ),
      ],
    );
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

    final search = find.widgetWithText(
      TextField,
      'Search task, message, linked chat, or schedule',
    );
    expect(search, findsOneWidget);

    await tester.enterText(search, 'Release');
    await tester.pumpAndSettle();

    expect(find.text('Daily repo check'), findsWidgets);
    expect(find.text('WeChat quiz'), findsNothing);

    await tester.enterText(search, 'quiz');
    await tester.pumpAndSettle();

    expect(find.text('Daily repo check'), findsNothing);
    expect(find.text('WeChat quiz'), findsWidgets);
  });

  testWidgets('automations search supports webui field prefixes', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      automationItems: const [
        NanobotCatalogItem(
          id: 'paused',
          title: 'Paused job',
          subtitle: 'every',
          details: 'Release prep',
          status: 'Paused',
          filterKeys: ['paused'],
        ),
        NanobotCatalogItem(
          id: 'cron',
          title: 'Cron job',
          subtitle: 'cron',
          details: 'WeChat',
          status: 'Active',
          filterKeys: ['active'],
        ),
      ],
    );
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

    final search = find.widgetWithText(
      TextField,
      'Search task, message, linked chat, or schedule',
    );

    await tester.enterText(search, 'status:paused');
    await tester.pumpAndSettle();

    expect(find.text('Paused job'), findsWidgets);
    expect(find.text('Cron job'), findsNothing);

    await tester.enterText(search, 'schedule:cron');
    await tester.pumpAndSettle();

    expect(find.text('Paused job'), findsNothing);
    expect(find.text('Cron job'), findsWidgets);
  });

  testWidgets('automations surface filter chips narrow by status', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      automationItems: const [
        NanobotCatalogItem(
          id: 'active',
          title: 'Active job',
          status: 'Active',
          filterKeys: ['active'],
        ),
        NanobotCatalogItem(
          id: 'paused',
          title: 'Paused job',
          status: 'Paused',
          filterKeys: ['paused'],
        ),
        NanobotCatalogItem(
          id: 'failed',
          title: 'Failed job',
          status: 'Active',
          filterKeys: ['failed'],
        ),
        NanobotCatalogItem(
          id: 'system',
          title: 'System job',
          status: 'Active',
          filterKeys: ['system'],
        ),
      ],
    );
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

    expect(find.text('All 4'), findsOneWidget);
    expect(find.text('Active 1'), findsOneWidget);
    expect(find.text('Paused 1'), findsOneWidget);
    expect(find.text('Needs attention 1'), findsOneWidget);
    expect(find.text('System 1'), findsOneWidget);

    await tester.tap(find.text('Paused 1'));
    await tester.pumpAndSettle();

    expect(find.text('Paused job'), findsWidgets);
    expect(find.text('Active job'), findsNothing);
    expect(find.text('Failed job'), findsNothing);

    await tester.tap(find.text('Needs attention 1'));
    await tester.pumpAndSettle();

    expect(find.text('Failed job'), findsWidgets);
    expect(find.text('Paused job'), findsNothing);
  });

  testWidgets('automations surface sorts by next run and name', (tester) async {
    final repository = _FakeNanobotRepository(
      automationItems: const [
        NanobotCatalogItem(
          id: 'zeta',
          title: 'Zeta job',
          status: 'Active',
          filterKeys: ['active'],
          nextRunAtMs: 1000,
        ),
        NanobotCatalogItem(
          id: 'alpha',
          title: 'Alpha job',
          status: 'Active',
          filterKeys: ['active'],
          nextRunAtMs: 2000,
        ),
      ],
    );
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

    expect(_isAbove(tester, 'Zeta job', 'Alpha job'), isTrue);

    await tester.tap(find.text('Next run'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name').last);
    await tester.pumpAndSettle();

    expect(_isAbove(tester, 'Alpha job', 'Zeta job'), isTrue);
  });

  testWidgets('automations action buttons refresh action results', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      automationItems: const [
        NanobotCatalogItem(
          id: 'job-1',
          title: 'Daily job',
          status: 'Active',
          filterKeys: ['active'],
        ),
      ],
      actionAutomationItems: const [
        NanobotCatalogItem(
          id: 'job-1',
          title: 'Daily job',
          status: 'Paused',
          filterKeys: ['paused'],
        ),
      ],
    );
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

    expect(find.text('Active'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause').last);
    await tester.pumpAndSettle();

    expect(repository.actionRequests, [
      (action: NanobotAutomationAction.disable, id: 'job-1'),
    ]);
    expect(find.text('Paused'), findsWidgets);
  });

  testWidgets('automations delete action asks for confirmation first', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      automationItems: const [
        NanobotCatalogItem(
          id: 'job-1',
          title: 'Daily job',
          status: 'Active',
          filterKeys: ['active'],
        ),
      ],
      actionAutomationItems: const [],
    );
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

    await tester.tap(find.byTooltip('Automation actions').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(repository.actionRequests, isEmpty);
    expect(find.text('Delete automation'), findsOneWidget);
    expect(
      find.text(
        'This removes Daily job from automations. '
        'Past chat messages stay in the session.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(repository.actionRequests, [
      (action: NanobotAutomationAction.delete, id: 'job-1'),
    ]);
  });

  testWidgets('automations surface shows queue and selected detail panel', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      automationItems: const [
        NanobotCatalogItem(
          id: 'job-1',
          title: 'Daily job',
          subtitle: 'Check the repo status',
          details: 'Release prep',
          status: 'Active',
          filterKeys: ['active'],
          scheduleLabel: 'Every 2 hours',
          originLabel: 'Release prep',
          originSessionKey: 'websocket:chat-1',
          nextRunAtMs: 1000,
          createdAtMs: 500,
          updatedAtMs: 900,
          lastError: 'Timed out',
        ),
        NanobotCatalogItem(
          id: 'job-2',
          title: 'Second job',
          subtitle: 'Send summary',
          details: 'WeChat',
          status: 'Active',
          filterKeys: ['active'],
          scheduleLabel: 'Cron 0 * * * *',
          originLabel: 'WeChat',
        ),
      ],
    );
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

    expect(find.text('Queue'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Daily job'), findsWidgets);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Linked chat'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Created'), findsOneWidget);
    expect(find.text('Updated'), findsOneWidget);
    expect(find.text('Every 2 hours'), findsWidgets);
    expect(find.text('Release prep'), findsWidgets);
    expect(find.text('Timed out'), findsOneWidget);

    await tester.ensureVisible(find.text('Second job').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Second job').first);
    await tester.pumpAndSettle();

    expect(find.text('Cron 0 * * * *'), findsWidgets);
    expect(find.text('Timed out'), findsNothing);
  });

  testWidgets('automations surface mirrors webui status and schedule copy', (
    tester,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final repository = _FakeNanobotRepository(
      automationItems: [
        NanobotCatalogItem(
          id: 'active',
          title: 'Active job',
          subtitle: 'Send summary',
          status: 'Active',
          filterKeys: const ['active'],
          nextRunAtMs: now + const Duration(minutes: 5).inMilliseconds,
          scheduleLabel: 'Daily at 09:00',
          originLabel: 'Roadmap',
        ),
        const NanobotCatalogItem(
          id: 'running',
          title: 'Running job',
          subtitle: 'Check progress',
          status: 'Running now',
          filterKeys: ['active'],
          isPending: true,
          scheduleLabel: 'Hourly at :15',
          originLabel: 'Builds',
        ),
        const NanobotCatalogItem(
          id: 'failed',
          title: 'Failed job',
          subtitle: 'Retry deployment',
          status: 'Failed',
          filterKeys: ['failed'],
          lastError: 'boom',
          scheduleLabel: 'Cron */5 * * * *',
        ),
        const NanobotCatalogItem(
          id: 'idle',
          title: 'Idle job',
          subtitle: 'No future run',
          status: 'No schedule',
          filterKeys: ['active'],
          scheduleLabel: 'Custom schedule',
        ),
        const NanobotCatalogItem(
          id: 'system',
          title: 'System job',
          subtitle: 'heartbeat',
          status: 'System',
          filterKeys: ['system'],
          isProtected: true,
          scheduleLabel: 'Every 2 hours',
        ),
      ],
    );
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

    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Running now'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('No schedule'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Protected'), findsOneWidget);

    expect(find.text('Daily at 09:00'), findsWidgets);
    await tester.ensureVisible(find.text('Running job').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Running job').first);
    await tester.pumpAndSettle();
    expect(find.text('Hourly at :15'), findsWidgets);
    await tester.ensureVisible(find.text('System job').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('System job').first);
    await tester.pumpAndSettle();
    expect(find.text('Every 2 hours'), findsWidgets);
    await tester.ensureVisible(find.text('Idle job').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Idle job').first);
    await tester.pumpAndSettle();
    expect(find.text('No next run'), findsOneWidget);
    expect(find.textContaining('2026-'), findsNothing);
  });

  testWidgets('skills surface opens unavailable skill details', (tester) async {
    final repository = _FakeNanobotRepository(
      skillItems: const [
        NanobotCatalogItem(
          id: 'github',
          title: 'github',
          subtitle: 'Work with GitHub.',
          status: 'Missing: CLI: gh',
        ),
      ],
      skillDetails: const {
        'github': NanobotSkillDetail(
          name: 'github',
          description: 'Work with GitHub.',
          source: 'builtin',
          available: false,
          unavailableReason: 'CLI: gh',
          bins: ['gh'],
          missingBins: ['gh'],
          rawMarkdown: '# GitHub',
        ),
      },
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skills'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('github').last);
    await tester.pumpAndSettle();

    expect(repository.requestedSkillDetails, ['github']);
    expect(find.text('Unavailable reason'), findsOneWidget);
    expect(find.text('CLI: gh'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Work with GitHub.'), findsWidgets);
    expect(find.text('Requirements'), findsOneWidget);
    expect(find.text('Missing CLI'), findsOneWidget);
    expect(find.text('Raw SKILL.md'), findsOneWidget);
    await tester.tap(find.text('Raw SKILL.md'));
    await tester.pumpAndSettle();
    expect(find.text('# GitHub'), findsOneWidget);
  });
}

bool _isAbove(WidgetTester tester, String upperText, String lowerText) {
  final upperTop = tester.getTopLeft(find.text(upperText).first).dy;
  final lowerTop = tester.getTopLeft(find.text(lowerText).first).dy;
  return upperTop < lowerTop;
}

class _FakeNanobotRepository implements NanobotRepositoryPort {
  _FakeNanobotRepository({
    List<NanobotCatalogItem>? appItems,
    List<NanobotCatalogItem>? automationItems,
    List<NanobotCatalogItem>? actionAutomationItems,
    List<NanobotCatalogItem>? skillItems,
    Map<String, NanobotSkillDetail>? skillDetails,
  }) : _appItems = appItems ?? _defaultAppItems,
       _automationItems = automationItems ?? _defaultAutomationItems,
       _actionAutomationItems = actionAutomationItems ?? automationItems,
       _skillItems = skillItems ?? _defaultSkillItems,
       _skillDetails = skillDetails ?? const {};

  final _events = StreamController<NanobotEvent>.broadcast();
  final _status = StreamController<NanobotSocketStatus>.broadcast();
  final List<NanobotCatalogItem> _appItems;
  final List<NanobotCatalogItem> _automationItems;
  final List<NanobotCatalogItem>? _actionAutomationItems;
  final List<NanobotCatalogItem> _skillItems;
  final Map<String, NanobotSkillDetail> _skillDetails;
  final requestedSkillDetails = <String>[];
  final actionRequests = <({NanobotAutomationAction action, String id})>[];
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
  Future<List<NanobotCatalogItem>> runAutomationAction({
    required NanobotAutomationAction action,
    required String id,
  }) async {
    actionRequests.add((action: action, id: id));
    return _actionAutomationItems ?? _automationItems;
  }

  @override
  Future<List<NanobotCatalogItem>> updateAutomation({
    required String id,
    required Map<String, Object?> values,
  }) async {
    return _automationItems;
  }

  @override
  Future<List<NanobotCatalogItem>> fetchSkillItems() async {
    return _skillItems;
  }

  @override
  Future<NanobotSkillDetail> fetchSkillDetail(String name) async {
    requestedSkillDetails.add(name);
    final detail = _skillDetails[name];
    if (detail == null) {
      throw StateError('Missing skill detail: $name');
    }
    return detail;
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
      status: 'Active',
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
