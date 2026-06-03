import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:agent_client/features/agents/domain/agent_avatar.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:agent_client/features/chat/presentation/widgets/chat_message_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('anchors initial render at latest messages without a jump', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 220,
            child: ChatMessageList(
              messages: _manyMessages(80),
              scrollController: controller,
            ),
          ),
        ),
      ),
    );

    expect(controller.offset, 0);
    expect(find.textContaining('Message 79'), findsOneWidget);
    expect(find.textContaining('Message 0'), findsNothing);

    await tester.pump();
    await tester.pump();

    expect(controller.offset, 0);
  });

  testWidgets('keeps following latest message when a new turn is appended', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final messages = _manyMessages(24);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 220,
            child: ChatMessageList(
              messages: messages,
              scrollController: controller,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(controller.offset, 0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 220,
            child: ChatMessageList(
              messages: [
                ...messages,
                ChatMessage(
                  id: 'user-new',
                  agentId: 'agent-control',
                  conversationId: 'session-1',
                  role: ChatRole.user,
                  content: 'New request',
                  status: ChatMessageStatus.completed,
                  createdAt: DateTime(2026, 5, 29, 1),
                ),
              ],
              scrollController: controller,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(controller.offset, 0);
  });

  testWidgets('renders plain messages without markdown widgets', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageList(
            messages: [
              ChatMessage(
                id: 'plain-message',
                agentId: 'agent-control',
                conversationId: 'session-1',
                role: ChatRole.assistant,
                content: 'This is a normal chat message.',
                status: ChatMessageStatus.completed,
                createdAt: DateTime(2026, 5, 29),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('This is a normal chat message.'), findsOneWidget);
    expect(find.byKey(const Key('chat-markdown-plain-message')), findsNothing);
  });

  testWidgets('keeps markdown renderer for rich messages', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageList(
            messages: [
              ChatMessage(
                id: 'rich-message',
                agentId: 'agent-control',
                conversationId: 'session-1',
                role: ChatRole.assistant,
                content: 'This has **markdown** content.',
                status: ChatMessageStatus.completed,
                createdAt: DateTime(2026, 5, 29),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('chat-markdown-rich-message')), findsOneWidget);
  });

  testWidgets('renders the selected agent avatar for assistant messages', (
    tester,
  ) async {
    const agent = Agent(
      id: 'nanobot',
      name: 'nanobot',
      avatarUrl: 'assets/agent_avatars/planner.png',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageList(
            assistantAgent: agent,
            messages: [
              ChatMessage(
                id: 'assistant-message',
                agentId: 'nanobot',
                conversationId: 'session-1',
                role: ChatRole.assistant,
                content: 'Done.',
                status: ChatMessageStatus.completed,
                createdAt: DateTime(2026, 5, 29),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('agent-avatar-image-nanobot')), findsOneWidget);
    expect(AgentAvatarOptions.isDefaultAssetPath(agent.avatarUrl), isTrue);
  });

  testWidgets('renders streaming activity from SSE state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageList(
            messages: [
              ChatMessage(
                id: 'user-1',
                agentId: 'agent-control',
                conversationId: 'session-1',
                role: ChatRole.user,
                content: 'Review this',
                status: ChatMessageStatus.completed,
                createdAt: DateTime(2026, 5, 29),
              ),
              ChatMessage(
                id: 'assistant-1',
                agentId: 'agent-control',
                conversationId: 'session-1',
                role: ChatRole.assistant,
                content: '',
                status: ChatMessageStatus.streaming,
                createdAt: DateTime(2026, 5, 29, 0, 1),
              ),
            ],
            isStreaming: true,
            goalStatus: 'running',
            reasoningText: 'Checking the state machine.',
            progressText: 'Searching files.',
            toolHintText: 'running rg',
            fileEditText: 'modified: src/a.js\ncreated: lib/b.dart',
          ),
        ),
      ),
    );

    expect(find.text('Waiting for response'), findsNothing);
    expect(find.byKey(const Key('chat-live-activity')), findsOneWidget);
    expect(find.text('Processing'), findsOneWidget);
    expect(find.text('running'), findsOneWidget);
    expect(find.text('Thinking'), findsOneWidget);
    expect(find.text('Checking the state machine.'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Searching files.'), findsOneWidget);
    expect(find.text('Tool'), findsOneWidget);
    expect(find.text('running rg'), findsOneWidget);
    expect(find.text('Files'), findsOneWidget);
    expect(
      find.text('modified: src/a.js\ncreated: lib/b.dart'),
      findsOneWidget,
    );
  });

  testWidgets('keeps empty state when there is no active turn', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ChatMessageList(messages: [])),
      ),
    );

    expect(find.text('Start a chat'), findsOneWidget);
    expect(find.byKey(const Key('chat-live-activity')), findsNothing);
  });
}

List<ChatMessage> _manyMessages(int count) {
  return [
    for (var index = 0; index < count; index += 1)
      ChatMessage(
        id: 'message-$index',
        agentId: 'agent-control',
        conversationId: 'session-1',
        role: index.isEven ? ChatRole.user : ChatRole.assistant,
        content: 'Message $index\nwith enough text to create scroll height.',
        status: ChatMessageStatus.completed,
        createdAt: DateTime(2026, 5, 29, 0, index),
      ),
  ];
}
