import 'package:agent_client/features/chat/application/chat_controller.dart';
import 'package:agent_client/features/chat/data/agent_chat_repository.dart';
import 'package:agent_client/features/chat/data/chat_cache_store.dart';
import 'package:agent_client/features/chat/domain/chat_event.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test(
    'sendMessage streams deltas into one completed assistant message',
    () async {
      final repository = _FakeAgentChatRepository([
        const ChatEvent.messageStarted(messageId: 'assistant-1'),
        const ChatEvent.textDelta(messageId: 'assistant-1', delta: 'Hello'),
        const ChatEvent.textDelta(messageId: 'assistant-1', delta: ' there'),
        const ChatEvent.messageCompleted(messageId: 'assistant-1'),
      ]);
      final cache = InMemoryChatCacheStore();
      final container = ProviderContainer(
        overrides: [
          agentChatRepositoryProvider.overrideWithValue(repository),
          chatCacheStoreProvider.overrideWithValue(cache),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(chatControllerProvider('agent-general').notifier)
          .sendMessage('Hi');

      final state = container.read(chatControllerProvider('agent-general'));
      expect(state.messages, hasLength(2));
      expect(state.messages.first.role, ChatRole.user);
      expect(state.messages.first.content, 'Hi');
      expect(state.messages.last.role, ChatRole.assistant);
      expect(state.messages.last.content, 'Hello there');
      expect(state.messages.last.status, ChatMessageStatus.completed);
      expect(state.isStreaming, isFalse);
    },
  );

  test(
    'refreshRecentMessages replaces stale static preview messages',
    () async {
      final repository = _FakeAgentChatRepository(
        const [],
        recentMessages: [
          ChatMessage(
            id: 'static-rich-message',
            agentId: 'agent-general',
            conversationId: 'conversation-agent-general',
            role: ChatRole.assistant,
            content: 'Updated **rich** preview',
            status: ChatMessageStatus.completed,
            createdAt: DateTime(2026, 5, 29),
          ),
        ],
      );
      final cache = InMemoryChatCacheStore();
      final container = ProviderContainer(
        overrides: [
          agentChatRepositoryProvider.overrideWithValue(repository),
          chatCacheStoreProvider.overrideWithValue(cache),
        ],
      );
      addTearDown(container.dispose);

      await cache.saveMessage(
        ChatMessage(
          id: 'old-message',
          agentId: 'agent-general',
          conversationId: 'conversation-agent-general',
          role: ChatRole.assistant,
          content: 'Old preview',
          status: ChatMessageStatus.completed,
          createdAt: DateTime(2026, 5, 28),
        ),
      );

      await container
          .read(chatControllerProvider('agent-general').notifier)
          .loadRecentMessages();
      expect(
        container
            .read(chatControllerProvider('agent-general'))
            .messages
            .single
            .id,
        'old-message',
      );

      await container
          .read(chatControllerProvider('agent-general').notifier)
          .refreshRecentMessages();

      final messages = container
          .read(chatControllerProvider('agent-general'))
          .messages;
      expect(messages, hasLength(1));
      expect(messages.single.id, 'static-rich-message');
      expect(messages.single.content, 'Updated **rich** preview');
    },
  );
}

class _FakeAgentChatRepository implements AgentChatRepository {
  _FakeAgentChatRepository(this.events, {this.recentMessages = const []});

  final List<ChatEvent> events;
  final List<ChatMessage> recentMessages;

  @override
  Future<void> cancelActiveResponse(String conversationId) async {}

  @override
  Future<List<ChatMessage>> loadRecentMessages(String agentId) async =>
      recentMessages;

  @override
  Stream<ChatEvent> sendMessage(SendMessageRequest request) async* {
    expect(request.agentId, 'agent-general');
    expect(request.input, 'Hi');

    for (final event in events) {
      yield event;
    }
  }
}
