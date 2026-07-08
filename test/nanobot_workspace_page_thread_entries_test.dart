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
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

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

  testWidgets('message inline code renders code spans', (tester) async {
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
      'text': 'Check `src/**/*.json` before continuing.',
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('`'), findsNothing);
    expect(_richTextWithCodeSpan('src/**/*.json'), findsOneWidget);
    expect(repository.previewPath, isNull);
  });

  testWidgets('message strikethrough markdown renders deleted spans', (
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
      'text': 'Use ~~old gateway~~ new gateway.',
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('~~'), findsNothing);
    expect(
      _richTextWithDecoration('old gateway', TextDecoration.lineThrough),
      findsOneWidget,
    );
  });

  testWidgets('message safe inline html renders styled spans', (tester) async {
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
      'text': '<mark>高亮文本</mark> x<sup>2</sup> H<sub>2</sub>O',
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('<mark>'), findsNothing);
    expect(find.textContaining('<sup>'), findsNothing);
    expect(find.textContaining('<sub>'), findsNothing);
    expect(_richTextWithBackground('高亮文本'), findsOneWidget);
    expect(_richTextWithSmallSpanCount('2', 2), findsOneWidget);
  });

  testWidgets('message safe details html renders expandable markdown', (
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
          '<details><summary>点击展开更多内容</summary>\n\n'
          '这里是被折叠的内容。\n\n'
          '- **可以放列表**\n\n'
          '</details>',
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('<details'), findsNothing);
    expect(find.textContaining('<summary'), findsNothing);
    expect(find.textContaining('</details>'), findsNothing);
    expect(
      find.byKey(const ValueKey('nanobot-markdown-details')),
      findsOneWidget,
    );
    expect(find.text('点击展开更多内容'), findsOneWidget);
    expect(find.text('这里是被折叠的内容。'), findsNothing);

    await tester.tap(find.text('点击展开更多内容'));
    await tester.pumpAndSettle();

    expect(find.text('这里是被折叠的内容。'), findsOneWidget);
    expect(find.text('•'), findsOneWidget);
    expect(_richTextWithBoldSpan('可以放列表'), findsOneWidget);
  });

  testWidgets('message markdown bullet lists render list rows', (tester) async {
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
      'text': 'Found addresses:\n- **192.168.200.149**\n- `198.18.0.1`',
    });
    await tester.pumpAndSettle();

    expect(find.text('Found addresses:'), findsOneWidget);
    expect(find.text('•'), findsNWidgets(2));
    expect(_richTextWithBoldSpan('192.168.200.149'), findsOneWidget);
    expect(_richTextWithCodeSpan('198.18.0.1'), findsOneWidget);
    expect(find.textContaining('- **'), findsNothing);
  });

  testWidgets('message markdown ordered lists render numbered rows', (
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
      'text': 'Steps:\n1. **Open** settings\n2. Run `test`',
    });
    await tester.pumpAndSettle();

    expect(find.text('Steps:'), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
    expect(_richTextWithBoldSpan('Open'), findsOneWidget);
    expect(_richTextWithCodeSpan('test'), findsOneWidget);
    expect(find.textContaining('1. **'), findsNothing);
  });

  testWidgets('message markdown task lists render checkbox rows', (
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
      'text': 'Checklist:\n- [x] **Connected**\n- [ ] Run `tests`',
    });
    await tester.pumpAndSettle();

    expect(find.text('Checklist:'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(2));
    expect(_checkboxWithValue(true), findsOneWidget);
    expect(_checkboxWithValue(false), findsOneWidget);
    expect(_richTextWithBoldSpan('Connected'), findsOneWidget);
    expect(_richTextWithCodeSpan('tests'), findsOneWidget);
    expect(find.textContaining('[x]'), findsNothing);
    expect(find.textContaining('[ ]'), findsNothing);
  });

  testWidgets('message markdown blockquotes render quote blocks', (
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
      'text': '> Important\n> Check `gateway` first.',
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('>'), findsNothing);
    expect(find.text('Important\nCheck gateway first.'), findsNothing);
    expect(find.text('Important'), findsOneWidget);
    expect(_richTextWithCodeSpan('gateway'), findsOneWidget);
    expect(_containerWithLeftBorder(), findsOneWidget);
  });

  testWidgets('message markdown pipe tables render table cells', (
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
          '| Name | Status |\n'
          '| --- | --- |\n'
          '| Gateway | **Connected** |\n'
          '| Tests | `passing` |',
    });
    await tester.pumpAndSettle();

    expect(find.byType(Table), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Gateway'), findsOneWidget);
    expect(_richTextWithBoldSpan('Connected'), findsOneWidget);
    expect(_richTextWithCodeSpan('passing'), findsOneWidget);
    expect(find.textContaining('| Name |'), findsNothing);
  });

  testWidgets('message markdown horizontal rules render dividers', (
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
      'text': 'Before\n\n---\n\nAfter',
    });
    await tester.pumpAndSettle();

    expect(find.text('Before'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('nanobot-markdown-horizontal-rule')),
      findsOneWidget,
    );
    expect(find.text('After'), findsOneWidget);
    expect(find.text('---'), findsNothing);
  });

  testWidgets('message markdown headings render heading text', (tester) async {
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
      'text': '## Network result\n\nDetails follow.',
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('##'), findsNothing);
    expect(_textWithWeight('Network result', FontWeight.w700), findsOneWidget);
    expect(find.text('Details follow.'), findsOneWidget);
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

  testWidgets('message markdown videos render inline players', (tester) async {
    final platform = _FakeVideoPlayerPlatform();
    final previousPlatform = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = platform;
    addTearDown(() {
      VideoPlayerPlatform.instance = previousPlatform;
      platform.disposeStreams();
    });
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
      'text': 'Watch ![nanobot-intro.mp4](/api/media/sig/video)',
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('Watch'), findsOneWidget);
    expect(find.byKey(const ValueKey('nanobot-markdown-video')), findsOneWidget);
    expect(find.byType(Texture), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsNothing);
    expect(platform.dataSources, hasLength(1));
    expect(platform.dataSources.single.sourceType, DataSourceType.network);
    expect(platform.dataSources.single.uri, endsWith('/api/media/sig/video'));
  });

  testWidgets('message markdown file attachments expose file semantics', (
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
      'text': 'Download ![index.html](/api/media/sig/html)',
    });
    await tester.pumpAndSettle();

    expect(_semanticsLabel('File attachment'), findsOneWidget);
    expect(find.text('index.html'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('message markdown source links render compact link rows', (
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
          'Sources:\n\n'
          '- Polymarket — “When will GPT-5.6 be released?”\n'
          '  https://polymarket.com/event/when-will-gpt-5pt6-be-released',
    });
    await tester.pumpAndSettle();

    expect(find.text('Sources:'), findsOneWidget);
    expect(
      _semanticsLabel('Open link: Polymarket — When will GPT-5.6 be released?'),
      findsOneWidget,
    );
    expect(find.text('Polymarket — When will GPT-5.6 be released?'), findsOneWidget);
    expect(find.textContaining('https://polymarket.com'), findsNothing);
    expect(find.text('•'), findsNothing);
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

class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final dataSources = <DataSource>[];
  final streams = <int, StreamController<VideoEvent>>{};
  var nextPlayerId = 1;

  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) async {
    return createWithOptions(
      VideoCreationOptions(
        dataSource: dataSource,
        viewType: VideoViewType.textureView,
      ),
    );
  }

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final playerId = nextPlayerId;
    nextPlayerId += 1;
    dataSources.add(options.dataSource);
    final stream = StreamController<VideoEvent>();
    streams[playerId] = stream;
    stream.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        size: const Size(320, 180),
        duration: const Duration(seconds: 8),
      ),
    );
    return playerId;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    return streams[playerId]!.stream;
  }

  @override
  Future<void> dispose(int playerId) async {
    await streams.remove(playerId)?.close();
  }

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Widget buildView(int playerId) {
    return Texture(textureId: playerId);
  }

  void disposeStreams() {
    for (final stream in streams.values) {
      stream.close();
    }
    streams.clear();
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

Finder _richTextWithCodeSpan(String text) {
  return find.byWidgetPredicate((widget) {
    if (widget is! RichText) {
      return false;
    }
    var found = false;
    void visit(InlineSpan span) {
      if (span is TextSpan) {
        if (span.text == text && span.style?.fontFamily == 'monospace') {
          found = true;
        }
        span.children?.forEach(visit);
      }
    }

    visit(widget.text);
    return found;
  });
}

Finder _richTextWithDecoration(String text, TextDecoration decoration) {
  return find.byWidgetPredicate((widget) {
    if (widget is! RichText) {
      return false;
    }
    var found = false;
    void visit(InlineSpan span) {
      if (span is TextSpan) {
        if (span.text == text && span.style?.decoration == decoration) {
          found = true;
        }
        span.children?.forEach(visit);
      }
    }

    visit(widget.text);
    return found;
  });
}

Finder _richTextWithBackground(String text) {
  return find.byWidgetPredicate((widget) {
    if (widget is! RichText) {
      return false;
    }
    var found = false;
    void visit(InlineSpan span) {
      if (span is TextSpan) {
        if (span.text == text && span.style?.backgroundColor != null) {
          found = true;
        }
        span.children?.forEach(visit);
      }
    }

    visit(widget.text);
    return found;
  });
}

Finder _richTextWithSmallSpanCount(String text, int count) {
  return find.byWidgetPredicate((widget) {
    if (widget is! RichText) {
      return false;
    }
    var found = 0;
    void visit(InlineSpan span) {
      if (span is TextSpan) {
        final fontSize = span.style?.fontSize;
        if (span.text == text && fontSize != null && fontSize < 12) {
          found += 1;
        }
        span.children?.forEach(visit);
      }
    }

    visit(widget.text);
    return found == count;
  });
}

Finder _semanticsLabel(String label) {
  return find.byWidgetPredicate((widget) {
    return widget is Semantics && widget.properties.label == label;
  });
}

Finder _textWithWeight(String text, FontWeight weight) {
  return find.byWidgetPredicate((widget) {
    if (widget is Text) {
      return widget.data == text && widget.style?.fontWeight == weight;
    }
    return false;
  });
}

Finder _checkboxWithValue(bool value) {
  return find.byWidgetPredicate((widget) {
    return widget is Checkbox &&
        widget.value == value &&
        widget.onChanged == null;
  });
}

Finder _containerWithLeftBorder() {
  return find.byWidgetPredicate((widget) {
    if (widget is! Container) {
      return false;
    }
    final decoration = widget.decoration;
    if (decoration is! BoxDecoration) {
      return false;
    }
    final border = decoration.border;
    return border is Border && border.left.width >= 3;
  });
}
