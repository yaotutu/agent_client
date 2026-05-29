import 'package:agent_client/app/agent_client_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  Future<void> pumpAppAtSize(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ProviderScope(child: AgentClientApp()));
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
        matching: find.text('General Agent'),
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

  testWidgets('phone layout switches agents from a left drawer', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(390, 844));

    await tester.tap(find.byKey(const Key('agent-navigation-button')));
    await tester.pumpAndSettle();

    expect(find.text('Agent Navigator'), findsOneWidget);
    await tester.tap(find.text('Research Agent'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('current-agent-title')),
        matching: find.text('Research Agent'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('chat-input-bar')), findsOneWidget);
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

  testWidgets('tablet layout removes the agent title above chat', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(768, 1024));

    expect(find.byKey(const Key('agent-side-rail')), findsOneWidget);
    expect(find.byKey(const Key('agent-navigation-button')), findsNothing);
    expect(find.byKey(const Key('current-agent-title')), findsNothing);
    expect(find.text('General Agent'), findsOneWidget);
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

  testWidgets('agent tabs show static files and tasks data', (tester) async {
    await pumpAppAtSize(tester, const Size(1200, 800));

    await tester.tap(find.byKey(const Key('agent-files-tab')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agent-files-list')), findsOneWidget);
    expect(find.text('Project Brief.pdf'), findsOneWidget);
    expect(find.text('Updated 09:45'), findsOneWidget);

    await tester.tap(find.byKey(const Key('agent-tasks-tab')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agent-tasks-list')), findsOneWidget);
    expect(find.text('Draft static chat UI'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
  });
}
