import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy messages with null attachments expose an empty list', () {
    final message =
        (ChatMessage.new as dynamic)(
              id: 'legacy-message',
              agentId: 'agent-general',
              conversationId: 'conversation-agent-general',
              role: ChatRole.assistant,
              content: 'Legacy hot reload state',
              status: ChatMessageStatus.completed,
              createdAt: DateTime(2026, 5, 29),
              attachments: null,
            )
            as ChatMessage;

    expect(message.attachments, isEmpty);
  });
}
