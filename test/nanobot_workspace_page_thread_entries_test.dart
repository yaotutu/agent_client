import 'dart:async';

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
  testWidgets('renders persisted trace and file edit thread entries', (
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
      'event': 'file_edit',
      'chat_id': 'chat-1',
      'edits': [
        {
          'call_id': 'call-1',
          'tool': 'write_file',
          'path': 'lib/main.dart',
          'added': 3,
          'deleted': 1,
          'status': 'done',
        },
      ],
    });
    repository.emit({'event': 'turn_end', 'chat_id': 'chat-1'});
    await tester.pumpAndSettle();

    expect(find.text('answer'), findsOneWidget);
    expect(find.text('read file'), findsOneWidget);
    expect(find.text('lib/main.dart'), findsOneWidget);
    expect(find.text('+3 -1'), findsOneWidget);
  });

  testWidgets('file edit rows open a file preview panel', (tester) async {
    final repository = _FakeNanobotRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    repository.emit({
      'event': 'file_edit',
      'chat_id': 'chat-1',
      'edits': [
        {'path': 'lib/main.dart', 'added': 3, 'deleted': 1, 'status': 'done'},
      ],
    });
    await tester.pumpAndSettle();

    await tester.tap(find.text('lib/main.dart'));
    await tester.pumpAndSettle();

    expect(repository.previewSessionKey, 'websocket:chat-1');
    expect(repository.previewPath, 'lib/main.dart');
    expect(find.text('File preview'), findsOneWidget);
    expect(find.text('lib/main.dart'), findsWidgets);
    expect(find.text('void main() {}'), findsOneWidget);
    expect(find.text('Preview truncated'), findsOneWidget);
  });

  testWidgets('message markdown file links open a file preview panel', (
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

    repository.emit({
      'event': 'message',
      'chat_id': 'chat-1',
      'text': 'Edited [main.dart](lib/main.dart:12)',
    });
    await tester.pumpAndSettle();

    await tester.tap(find.text('main.dart'));
    await tester.pumpAndSettle();

    expect(repository.previewPath, 'lib/main.dart');
    expect(find.text('File preview'), findsOneWidget);
    expect(find.text('void main() {}'), findsOneWidget);
  });

  testWidgets('message markdown non-file links render labels without preview', (
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

    repository.emit({
      'event': 'message',
      'chat_id': 'chat-1',
      'text':
          'Download [index.html](/api/media/sig/html) and inspect [*.json](*.json).',
    });
    await tester.pumpAndSettle();

    expect(find.text('index.html'), findsOneWidget);
    expect(find.text('*.json'), findsOneWidget);
    expect(find.textContaining('[index.html]'), findsNothing);
    expect(find.textContaining('[*.json]'), findsNothing);

    await tester.tap(find.text('index.html'));
    await tester.pumpAndSettle();

    expect(repository.previewPath, isNull);
    expect(find.text('File preview'), findsNothing);
  });

  testWidgets('message bold markdown renders emphasized spans', (tester) async {
    final repository = _FakeNanobotRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    repository.emit({
      'event': 'message',
      'chat_id': 'chat-1',
      'text': 'Primary **192.168.200.149** address',
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('**'), findsNothing);
    expect(_richTextWithBoldSpan('192.168.200.149'), findsOneWidget);
  });

  testWidgets('message markdown images render inline previews', (tester) async {
    final repository = _FakeNanobotRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    repository.emit({
      'event': 'message',
      'chat_id': 'chat-1',
      'text':
          'Preview ![Diagram](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEA'
          'AAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==)',
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('Preview'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.bySemanticsLabel('Diagram'), findsOneWidget);
    expect(find.text('Diagram'), findsNothing);
  });

  testWidgets('message fenced code blocks render code panels', (tester) async {
    final repository = _FakeNanobotRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    repository.emit({
      'event': 'message',
      'chat_id': 'chat-1',
      'text': 'Run this:\n\n```sh\nls -la\n```',
    });
    await tester.pumpAndSettle();

    expect(find.text('Run this:'), findsOneWidget);
    expect(find.text('sh'), findsOneWidget);
    expect(find.text('ls -la'), findsOneWidget);
    expect(find.byTooltip('Copy code'), findsOneWidget);
  });

  testWidgets('message media attachments render attachment tiles', (
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

    repository.emit({
      'event': 'message',
      'chat_id': 'chat-1',
      'text': 'See diagram',
      'media_urls': [
        {'kind': 'image', 'url': '/api/media/sig/payload', 'name': 'Diagram'},
      ],
    });
    await tester.pumpAndSettle();

    expect(find.text('See diagram'), findsOneWidget);
    expect(find.text('Diagram'), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });

  testWidgets('image media attachments render inline previews', (tester) async {
    final repository = _FakeNanobotRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    repository.emit({
      'event': 'message',
      'chat_id': 'chat-1',
      'text': 'See diagram',
      'media_urls': [
        {
          'kind': 'image',
          'url':
              'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
              'AAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
          'name': 'Diagram',
        },
      ],
    });
    await tester.pumpAndSettle();

    expect(find.text('See diagram'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.bySemanticsLabel('Diagram'), findsOneWidget);
  });

  testWidgets('image media previews open a larger preview dialog', (
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

    repository.emit({
      'event': 'message',
      'chat_id': 'chat-1',
      'text': 'See diagram',
      'media_urls': [
        {
          'kind': 'image',
          'url':
              'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
              'AAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
          'name': 'Diagram',
        },
      ],
    });
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Diagram'));
    await tester.pumpAndSettle();

    expect(find.text('Image preview'), findsOneWidget);
    expect(find.bySemanticsLabel('Diagram'), findsNWidgets(2));
  });

  testWidgets('message too large stream errors show a dismissible alert', (
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

    repository.emit({'event': 'error', 'detail': 'message_too_big'});
    await tester.pumpAndSettle();

    expect(find.text('Message too large'), findsOneWidget);
    expect(
      find.textContaining('Remove some images or try smaller files'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pumpAndSettle();

    expect(find.text('Message too large'), findsNothing);
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
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      modelName: 'model',
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

  String? previewSessionKey;
  String? previewPath;

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
  Future<NanobotFilePreview> fetchFilePreview({
    required String sessionKey,
    required String path,
  }) async {
    previewSessionKey = sessionKey;
    previewPath = path;
    return const NanobotFilePreview(
      path: 'lib/main.dart',
      displayPath: 'lib/main.dart',
      projectPath: '/tmp/project',
      language: 'dart',
      content: 'void main() {}',
      size: 2048,
      truncated: true,
    );
  }

  @override
  Future<String> newChat({NanobotWorkspaceScope? workspaceScope}) async =>
      'chat-1';

  @override
  Future<void> sendMessage({
    required String chatId,
    required String content,
    List<NanobotCapabilityMention> cliApps = const [],
    List<NanobotCapabilityMention> mcpPresets = const [],
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

Finder _richTextWithBoldSpan(String text) {
  return find.byWidgetPredicate((widget) {
    if (widget is! RichText) {
      return false;
    }
    var found = false;
    void visit(InlineSpan span) {
      if (span is TextSpan) {
        if (span.text == text && span.style?.fontWeight == FontWeight.w700) {
          found = true;
        }
        span.children?.forEach(visit);
      }
    }

    visit(widget.text);
    return found;
  });
}
