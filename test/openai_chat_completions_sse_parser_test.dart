import 'package:agent_client/features/chat/data/openai_chat_completions_agent_chat_repository.dart';
import 'package:agent_client/features/chat/data/openai_chat_completions_sse_parser.dart';
import 'package:agent_client/features/chat/data/agent_chat_repository.dart';
import 'package:agent_client/features/chat/domain/chat_event.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses Chat Completions delta chunks and done marker', () {
    final parser = OpenAiChatCompletionsSseParser();

    final events = parser.parseChunk('''
data: {"id":"chatcmpl-1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"role":"assistant"},"finish_reason":null}]}

data: {"id":"chatcmpl-1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"Hel"},"finish_reason":null}]}

data: {"id":"chatcmpl-1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"lo"},"finish_reason":null}]}

data: {"id":"chatcmpl-1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{},"finish_reason":"stop"}]}

data: [DONE]

''');

    expect(events, hasLength(4));
    expect(events[0], const ChatEvent.messageStarted(messageId: 'chatcmpl-1'));
    expect(
      events[1],
      const ChatEvent.textDelta(messageId: 'chatcmpl-1', delta: 'Hel'),
    );
    expect(
      events[2],
      const ChatEvent.textDelta(messageId: 'chatcmpl-1', delta: 'lo'),
    );
    expect(
      events[3],
      const ChatEvent.messageCompleted(messageId: 'chatcmpl-1'),
    );
  });

  test('builds Chat Completions payload from current input and history', () {
    final body = OpenAiChatCompletionsAgentChatRepository.buildRequestBody(
      request: SendMessageRequest(
        agentId: 'agent-general',
        conversationId: 'conversation-agent-general',
        input: 'What is next?',
        history: [
          ChatMessage(
            id: 'user-1',
            agentId: 'agent-general',
            conversationId: 'conversation-agent-general',
            role: ChatRole.user,
            content: 'Hi',
            status: ChatMessageStatus.completed,
            createdAt: DateTime(2026),
          ),
          ChatMessage(
            id: 'assistant-1',
            agentId: 'agent-general',
            conversationId: 'conversation-agent-general',
            role: ChatRole.assistant,
            content: 'Hello',
            status: ChatMessageStatus.completed,
            createdAt: DateTime(2026),
          ),
        ],
      ),
      model: 'agent-model',
    );

    expect(body['model'], 'agent-model');
    expect(body['stream'], isTrue);
    expect(body['metadata'], {
      'agent_id': 'agent-general',
      'conversation_id': 'conversation-agent-general',
    });
    expect(body['messages'], [
      {'role': 'user', 'content': 'Hi'},
      {'role': 'assistant', 'content': 'Hello'},
      {'role': 'user', 'content': 'What is next?'},
    ]);
  });
}
