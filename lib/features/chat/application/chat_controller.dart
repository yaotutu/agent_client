import 'package:agent_client/features/chat/application/chat_state.dart';
import 'package:agent_client/features/chat/data/agent_chat_repository.dart';
import 'package:agent_client/features/chat/data/chat_cache_store.dart';
import 'package:agent_client/features/chat/domain/chat_event.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final chatControllerProvider =
    NotifierProvider.family<ChatController, ChatState, String>(
      ChatController.new,
    );

class ChatController extends Notifier<ChatState> {
  ChatController(this.agentId);

  final String agentId;

  @override
  ChatState build() => ChatState.initial(agentId);

  Future<void> loadRecentMessages() async {
    if (state.messages.isNotEmpty) {
      return;
    }
    final messages = await ref
        .read(chatCacheStoreProvider)
        .loadRecentMessages(agentId);
    if (messages.isNotEmpty) {
      state = state.copyWith(messages: messages);
      return;
    }

    final repositoryMessages = await ref
        .read(agentChatRepositoryProvider)
        .loadRecentMessages(agentId);
    state = state.copyWith(messages: repositoryMessages);
    final cache = ref.read(chatCacheStoreProvider);
    for (final message in repositoryMessages) {
      await cache.saveMessage(message);
    }
  }

  Future<void> refreshRecentMessages() async {
    if (state.isStreaming) {
      return;
    }

    final repositoryMessages = await ref
        .read(agentChatRepositoryProvider)
        .loadRecentMessages(agentId);
    if (repositoryMessages.isEmpty) {
      await loadRecentMessages();
      return;
    }

    state = state.copyWith(messages: repositoryMessages, clearError: true);
    final cache = ref.read(chatCacheStoreProvider);
    for (final message in repositoryMessages) {
      await cache.saveMessage(message);
    }
  }

  Future<void> sendMessage(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty || state.isStreaming) {
      return;
    }

    final userMessage = ChatMessage(
      id: _newMessageId('user'),
      agentId: agentId,
      conversationId: state.conversationId,
      role: ChatRole.user,
      content: trimmed,
      status: ChatMessageStatus.completed,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isStreaming: true,
      clearError: true,
    );
    await ref.read(chatCacheStoreProvider).saveMessage(userMessage);

    final request = SendMessageRequest(
      agentId: agentId,
      conversationId: state.conversationId,
      input: trimmed,
      history: state.messages,
    );

    try {
      await for (final event
          in ref.read(agentChatRepositoryProvider).sendMessage(request)) {
        _applyEvent(event);
      }

      if (state.isStreaming) {
        _completeAssistantMessage('assistant');
      }
    } catch (error) {
      _failAssistantMessage(error.toString());
    } finally {
      await _persistMessages();
    }
  }

  Future<void> cancelActiveResponse() async {
    await ref
        .read(agentChatRepositoryProvider)
        .cancelActiveResponse(state.conversationId);
    final messages = state.messages.map((message) {
      if (message.role == ChatRole.assistant &&
          message.status == ChatMessageStatus.streaming) {
        return message.copyWith(status: ChatMessageStatus.stopped);
      }
      return message;
    }).toList();
    state = state.copyWith(messages: messages, isStreaming: false);
  }

  void _applyEvent(ChatEvent event) {
    switch (event.type) {
      case ChatEventType.messageStarted:
        _ensureAssistantMessage(event.messageId);
      case ChatEventType.textDelta:
        _appendAssistantDelta(event.messageId, event.delta ?? '');
      case ChatEventType.messageCompleted:
        _completeAssistantMessage(event.messageId);
      case ChatEventType.error:
        _failAssistantMessage(event.errorMessage ?? 'Response failed');
      case ChatEventType.toolEvent:
      case ChatEventType.taskEvent:
        _ensureAssistantMessage(event.messageId);
    }
  }

  void _ensureAssistantMessage(String messageId) {
    if (state.messages.any((message) => message.id == messageId)) {
      return;
    }

    final message = ChatMessage(
      id: messageId,
      agentId: agentId,
      conversationId: state.conversationId,
      role: ChatRole.assistant,
      content: '',
      status: ChatMessageStatus.streaming,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, message]);
  }

  void _appendAssistantDelta(String messageId, String delta) {
    _ensureAssistantMessage(messageId);
    state = state.copyWith(
      messages: [
        for (final message in state.messages)
          if (message.id == messageId)
            message.copyWith(
              content: '${message.content}$delta',
              status: ChatMessageStatus.streaming,
            )
          else
            message,
      ],
    );
  }

  void _completeAssistantMessage(String messageId) {
    state = state.copyWith(
      messages: [
        for (final message in state.messages)
          if (message.id == messageId ||
              (messageId == 'assistant' &&
                  message.role == ChatRole.assistant &&
                  message.status == ChatMessageStatus.streaming))
            message.copyWith(status: ChatMessageStatus.completed)
          else
            message,
      ],
      isStreaming: false,
    );
  }

  void _failAssistantMessage(String errorMessage) {
    final hasAssistant = state.messages.any(
      (message) => message.role == ChatRole.assistant,
    );
    final messages = hasAssistant
        ? [
            for (final message in state.messages)
              if (message.role == ChatRole.assistant &&
                  message.status == ChatMessageStatus.streaming)
                message.copyWith(status: ChatMessageStatus.failed)
              else
                message,
          ]
        : [
            ...state.messages,
            ChatMessage(
              id: _newMessageId('assistant'),
              agentId: agentId,
              conversationId: state.conversationId,
              role: ChatRole.assistant,
              content: errorMessage,
              status: ChatMessageStatus.failed,
              createdAt: DateTime.now(),
            ),
          ];

    state = state.copyWith(
      messages: messages,
      isStreaming: false,
      errorMessage: errorMessage,
    );
  }

  Future<void> _persistMessages() async {
    final cache = ref.read(chatCacheStoreProvider);
    for (final message in state.messages) {
      await cache.saveMessage(message);
    }
  }

  String _newMessageId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }
}
