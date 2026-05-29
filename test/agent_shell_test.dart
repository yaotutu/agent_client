import 'package:agent_client/app/agent_client_app.dart';
import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/domain/agent_control_models.dart';
import 'package:agent_client/features/agents/application/agent_controller.dart';
import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:agent_client/features/chat/data/agent_chat_repository.dart';
import 'package:agent_client/features/chat/data/chat_cache_store.dart';
import 'package:agent_client/features/chat/domain/chat_attachment.dart';
import 'package:agent_client/features/chat/domain/chat_event.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:agent_client/features/chat/domain/chat_session.dart';
import 'package:agent_client/features/files/application/agent_files_provider.dart';
import 'package:agent_client/features/files/data/agent_resources_repository.dart';
import 'package:agent_client/features/files/domain/agent_file_item.dart';
import 'package:agent_client/features/files/presentation/files_panel.dart';
import 'package:agent_client/features/settings/data/agent_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  Future<void> pumpAppAtSize(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentsProvider.overrideWith((ref) async => _agents),
          agentChatRepositoryProvider.overrideWithValue(
            _FakeAgentChatRepository(),
          ),
          chatCacheStoreProvider.overrideWithValue(InMemoryChatCacheStore()),
          agentFilesProvider.overrideWith((ref, query) async => _files),
          agentCommandsProvider.overrideWith((ref, agentId) async => const []),
        ],
        child: const AgentClientApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpAppWithAgentApi(
    WidgetTester tester,
    Size size,
    _FakeAgentControlApi api,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentControlApiClientProvider.overrideWithValue(api),
          agentChatRepositoryProvider.overrideWithValue(
            _FakeAgentChatRepository(),
          ),
          chatCacheStoreProvider.overrideWithValue(InMemoryChatCacheStore()),
          agentFilesProvider.overrideWith((ref, query) async => _files),
          agentCommandsProvider.overrideWith((ref, agentId) async => const []),
        ],
        child: const AgentClientApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('phone layout prioritizes chat and keeps input at the bottom', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(390, 844));

    expect(find.byKey(const Key('agent-chat-tab')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('current-agent-title')),
        matching: find.text('nanobot'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('chat-message-list')), findsOneWidget);
    expect(find.text('Review the mobile chat layout'), findsOneWidget);
    expect(find.textContaining('I found three UI priorities'), findsOneWidget);
    expect(find.byKey(const Key('chat-input-bar')), findsOneWidget);
    expect(find.byKey(const Key('bottom-navigation')), findsNothing);

    final inputRect = tester.getRect(find.byKey(const Key('chat-input-bar')));
    expect(inputRect.bottom, moreOrLessEquals(844, epsilon: 1));
    expect(inputRect.height, greaterThan(48));

    final tabRect = tester.getRect(find.byKey(const Key('agent-tab-bar')));
    expect(tabRect.top, lessThan(inputRect.top));
  });

  testWidgets('phone layout opens backend agent from a left drawer', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(390, 844));

    await tester.tap(find.byKey(const Key('agent-navigation-button')));
    await tester.pumpAndSettle();

    expect(find.text('Agent Navigator'), findsOneWidget);
    expect(find.text('nanobot'), findsWidgets);

    expect(
      find.descendant(
        of: find.byKey(const Key('current-agent-title')),
        matching: find.text('nanobot'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('chat-input-bar')), findsOneWidget);
  });

  testWidgets('phone chat switches conversations from a bottom sheet', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(390, 844));

    expect(find.byKey(const Key('chat-session-rail')), findsNothing);
    expect(find.byKey(const Key('chat-session-picker-button')), findsNothing);
    expect(find.byKey(const Key('chat-session-switch-button')), findsOneWidget);
    expect(find.text('Backend layout review'), findsNothing);

    await tester.tap(find.byKey(const Key('chat-session-switch-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-session-sheet')), findsOneWidget);
    expect(find.text('Conversations'), findsOneWidget);
    expect(find.text('Backend flaky test'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-session-session-flaky-test')));
    await tester.pumpAndSettle();

    expect(
      find.text('The failing test is tied to session restore.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('chat-session-sheet')), findsNothing);
  });

  testWidgets('phone conversation sheet creates a new session', (tester) async {
    await pumpAppAtSize(tester, const Size(390, 844));

    await tester.tap(find.byKey(const Key('chat-session-switch-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-session-sheet-new-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-session-sheet')), findsNothing);
    expect(find.text('Start a chat'), findsOneWidget);
  });

  testWidgets('desktop layout uses side rail while keeping chat input bottom', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(1200, 800));

    expect(find.byKey(const Key('agent-side-rail')), findsOneWidget);
    expect(find.byKey(const Key('agent-navigation-button')), findsNothing);
    expect(find.text('Agent Navigator'), findsNothing);
    expect(find.byKey(const Key('chat-input-bar')), findsOneWidget);

    final inputRect = tester.getRect(find.byKey(const Key('chat-input-bar')));
    expect(inputRect.bottom, moreOrLessEquals(800, epsilon: 1));
  });

  testWidgets('desktop agent navigator creates an agent and selects it', (
    tester,
  ) async {
    final api = _FakeAgentControlApi([_agentSummary('nanobot')]);
    await pumpAppWithAgentApi(tester, const Size(1200, 800), api);

    await tester.tap(find.byKey(const Key('agent-create-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('agent-create-name-field')),
      'reviewer',
    );
    await tester.enterText(
      find.byKey(const Key('agent-create-description-field')),
      '代码审查助手',
    );
    await tester.tap(find.byKey(const Key('agent-create-submit-button')));
    await tester.pumpAndSettle();

    expect(api.createdName, 'reviewer');
    expect(api.createdDescription, '代码审查助手');
    expect(find.byKey(const Key('agent-tile-reviewer')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('agent-tile-reviewer')),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });

  testWidgets('desktop agent navigator deletes the current agent', (
    tester,
  ) async {
    final api = _FakeAgentControlApi([
      _agentSummary('nanobot'),
      _agentSummary('reviewer'),
    ]);
    await pumpAppWithAgentApi(tester, const Size(1200, 800), api);

    await tester.tap(find.byKey(const Key('agent-tile-reviewer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('agent-menu-reviewer')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete agent'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('agent-delete-confirm-button')));
    await tester.pumpAndSettle();

    expect(api.deletedName, 'reviewer');
    expect(find.byKey(const Key('agent-tile-reviewer')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('agent-tile-nanobot')),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });

  testWidgets('desktop chat shows mock conversations and switches sessions', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(1200, 800));

    expect(find.byKey(const Key('chat-session-rail')), findsOneWidget);
    expect(find.text('Conversations'), findsOneWidget);
    expect(find.text('Backend layout review'), findsOneWidget);
    expect(find.text('Backend flaky test'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-session-session-flaky-test')));
    await tester.pumpAndSettle();

    expect(
      find.text('The failing test is tied to session restore.'),
      findsOneWidget,
    );
    expect(find.text('Review the mobile chat layout'), findsNothing);
  });

  testWidgets('desktop conversation rail inserts a new local session', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(1200, 800));

    await tester.tap(find.byKey(const Key('chat-session-new-button')));
    await tester.pumpAndSettle();

    expect(find.text('New chat'), findsOneWidget);
    expect(find.text('Start a chat'), findsOneWidget);
  });

  testWidgets('desktop input switch button opens the session sheet', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(1200, 800));

    await tester.tap(find.byKey(const Key('chat-session-switch-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-session-sheet')), findsOneWidget);
    expect(find.text('Backend layout review'), findsWidgets);
  });

  testWidgets('backend outage still shows the chat workspace', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentsProvider.overrideWith((ref) async => throw Exception('down')),
          agentChatRepositoryProvider.overrideWithValue(
            _FakeAgentChatRepository(),
          ),
          chatCacheStoreProvider.overrideWithValue(InMemoryChatCacheStore()),
          agentFilesProvider.overrideWith((ref, query) async => _files),
          agentCommandsProvider.overrideWith((ref, agentId) async => const []),
        ],
        child: const AgentClientApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agent-tab-bar')), findsOneWidget);
    expect(find.byKey(const Key('chat-message-list')), findsOneWidget);
    expect(find.byKey(const Key('chat-input-bar')), findsOneWidget);
    expect(find.text('Backend offline'), findsOneWidget);
    expect(find.textContaining('Unable to load agent'), findsNothing);
  });

  testWidgets('tablet layout removes the agent title above chat', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(768, 1024));

    expect(find.byKey(const Key('agent-side-rail')), findsOneWidget);
    expect(find.byKey(const Key('agent-navigation-button')), findsNothing);
    expect(find.byKey(const Key('current-agent-title')), findsNothing);
    expect(find.text('nanobot'), findsOneWidget);
    expect(find.byKey(const Key('agent-tab-bar')), findsOneWidget);
    expect(find.byKey(const Key('chat-message-list')), findsOneWidget);
  });

  testWidgets('chat bubbles render markdown, files, and images', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(390, 844));

    expect(
      find.byKey(const Key('chat-markdown-mock-assistant-rich-content')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('chat-file-ui-spec-file')), findsOneWidget);
    expect(find.text('UI-specification.md'), findsOneWidget);
    expect(find.text('18 KB · Markdown'), findsOneWidget);
    expect(
      find.byKey(const Key('chat-image-tablet-layout-preview')),
      findsOneWidget,
    );
    expect(find.text('Tablet layout preview'), findsOneWidget);
  });

  testWidgets('agent tabs show workspace files and live task data', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(1200, 800));

    await tester.tap(find.byKey(const Key('agent-files-tab')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agent-files-list')), findsOneWidget);
    expect(find.text('AGENTS.md'), findsWidgets);
    expect(find.text('workspace'), findsOneWidget);

    await tester.tap(find.byKey(const Key('agent-tasks-tab')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agent-tasks-list')), findsOneWidget);
    expect(find.text('No active task'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('files panel opens folders and saves edited files', (
    tester,
  ) async {
    final resources = _FakeResourcesRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentResourcesRepositoryProvider.overrideWithValue(resources),
        ],
        child: const MaterialApp(
          home: Scaffold(body: FilesPanel(agentId: 'nanobot')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Workspace'), findsOneWidget);
    expect(find.byKey(const Key('agent-file-row-notes')), findsOneWidget);

    await tester.tap(find.byKey(const Key('agent-file-row-notes')));
    await tester.pumpAndSettle();

    expect(find.text('Workspace / notes'), findsOneWidget);
    expect(find.text('TODO.md'), findsOneWidget);

    await tester.tap(find.byKey(const Key('agent-file-row-notes/TODO.md')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agent-file-editor-title')), findsOneWidget);
    final editor = tester.widget<TextField>(
      find.byKey(const Key('agent-file-editor-field')),
    );
    expect(editor.controller?.text, contains('# Todo'));

    await tester.enterText(
      find.byKey(const Key('agent-file-editor-field')),
      '# Todo\n- saved from test\n',
    );
    await tester.tap(find.byKey(const Key('agent-file-save-button')));
    await tester.pumpAndSettle();

    expect(
      resources.savedContentByPath['notes/TODO.md'],
      '# Todo\n- saved from test\n',
    );
    expect(find.byKey(const Key('agent-file-editor-title')), findsNothing);
  });
}

const _agents = [
  Agent(
    id: 'nanobot',
    name: 'nanobot',
    model: 'MiniMax-M2.7-highspeed',
    provider: 'minimax',
    workspace: '/workspace',
  ),
];

AgentSummary _agentSummary(String name) {
  return AgentSummary(
    name: name,
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
    _agents.add(_agentSummary(name));
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

class _FakeResourcesRepository extends AgentResourcesRepository {
  _FakeResourcesRepository() : super(_FakeAgentControlApi(<AgentSummary>[]));

  final savedContentByPath = <String, String>{};

  @override
  Future<List<AgentFileItem>> listWorkspaceDirectory(
    String agentName, {
    String path = '.',
  }) async {
    if (path == 'notes') {
      return const [
        AgentFileItem(
          name: 'TODO.md',
          path: 'notes/TODO.md',
          kind: AgentFileKind.document,
          sizeLabel: 'file',
          updatedLabel: 'notes/TODO.md',
          owner: 'workspace',
        ),
      ];
    }
    return const [
      AgentFileItem(
        name: 'notes',
        path: 'notes',
        kind: AgentFileKind.directory,
        sizeLabel: 'directory',
        updatedLabel: 'notes',
        owner: 'workspace',
      ),
      AgentFileItem(
        name: 'AGENTS.md',
        path: 'AGENTS.md',
        kind: AgentFileKind.document,
        sizeLabel: 'file',
        updatedLabel: 'AGENTS.md',
        owner: 'workspace',
      ),
    ];
  }

  @override
  Future<ResourceFile> readFile({
    required String agentName,
    required String path,
  }) async {
    final content = savedContentByPath[path] ?? '# Todo\n- write tests\n';
    return ResourceFile(
      object: 'resources.file',
      path: path,
      size: content.length,
      mtimeMs: 1,
      content: content,
    );
  }

  @override
  Future<ResourceFileWriteResult> writeFile({
    required String agentName,
    required String path,
    required String content,
  }) async {
    savedContentByPath[path] = content;
    return ResourceFileWriteResult(
      object: 'resources.file',
      path: path,
      size: content.length,
      mtimeMs: 2,
    );
  }
}

const _files = [
  AgentFileItem(
    name: 'AGENTS.md',
    path: 'AGENTS.md',
    kind: AgentFileKind.document,
    sizeLabel: 'file',
    updatedLabel: 'AGENTS.md',
    owner: 'workspace',
  ),
];

class _FakeAgentChatRepository implements AgentChatRepository {
  @override
  Future<String> ensureSessionId(String agentId) async => 'session-1';

  @override
  Future<ChatSessionSummary> startNewSession(String agentId) async {
    return const ChatSessionSummary(
      id: 'session-new',
      title: 'New chat',
      preview: '',
      updatedLabel: 'Now',
      messageCount: 0,
    );
  }

  @override
  Future<List<ChatSessionSummary>> listSessions(String agentId) async {
    return const [
      ChatSessionSummary(
        id: 'session-1',
        title: 'Backend layout review',
        preview: 'I found three UI priorities.',
        updatedLabel: '09:01',
        messageCount: 2,
      ),
      ChatSessionSummary(
        id: 'session-flaky-test',
        title: 'Backend flaky test',
        preview: 'Session restore looks suspicious.',
        updatedLabel: 'Yesterday',
        messageCount: 4,
        status: ChatSessionStatus.running,
      ),
      ChatSessionSummary(
        id: 'session-api3',
        title: 'API3 migration',
        preview: 'Align sessions, attach, and SSE.',
        updatedLabel: 'Mon',
        messageCount: 6,
      ),
    ];
  }

  @override
  Future<void> cancelActiveResponse({
    required String agentId,
    required String sessionId,
  }) async {}

  @override
  Future<List<ChatMessage>> loadRecentMessages(
    String agentId, {
    String? sessionId,
  }) async {
    if (sessionId == 'session-flaky-test') {
      return [
        ChatMessage(
          id: 'session-flaky-test-user',
          agentId: agentId,
          conversationId: sessionId!,
          role: ChatRole.user,
          content: 'Why is the restore test flaky?',
          status: ChatMessageStatus.completed,
          createdAt: DateTime(2026, 5, 28, 16),
        ),
        ChatMessage(
          id: 'session-flaky-test-assistant',
          agentId: agentId,
          conversationId: sessionId,
          role: ChatRole.assistant,
          content: 'The failing test is tied to session restore.',
          status: ChatMessageStatus.completed,
          createdAt: DateTime(2026, 5, 28, 16, 1),
        ),
      ];
    }
    if (sessionId != null && sessionId != 'session-1') {
      return const [];
    }
    return [
      ChatMessage(
        id: 'mock-user-layout-request',
        agentId: agentId,
        conversationId: 'session-1',
        role: ChatRole.user,
        content: 'Review the mobile chat layout',
        status: ChatMessageStatus.completed,
        createdAt: DateTime(2026, 5, 29, 9),
      ),
      ChatMessage(
        id: 'mock-assistant-rich-content',
        agentId: agentId,
        conversationId: 'session-1',
        role: ChatRole.assistant,
        content: 'I found three UI priorities:\n\n- Keep chat primary.',
        status: ChatMessageStatus.completed,
        createdAt: DateTime(2026, 5, 29, 9, 1),
        attachments: const [
          ChatAttachment(
            id: 'ui-spec-file',
            kind: ChatAttachmentKind.file,
            name: 'UI-specification.md',
            sizeLabel: '18 KB',
            typeLabel: 'Markdown',
          ),
          ChatAttachment(
            id: 'tablet-layout-preview',
            kind: ChatAttachmentKind.image,
            name: 'Tablet layout preview',
            sizeLabel: '1.1 MB',
            typeLabel: 'PNG',
          ),
        ],
      ),
    ];
  }

  @override
  Stream<ChatEvent> sendMessage(SendMessageRequest request) async* {}
}
