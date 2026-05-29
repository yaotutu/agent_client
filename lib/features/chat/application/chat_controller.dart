import 'package:agent_client/features/chat/application/chat_state.dart';
import 'package:agent_client/features/chat/application/chat_sessions_controller.dart';
import 'package:agent_client/features/chat/data/agent_chat_repository.dart';
import 'package:agent_client/features/chat/data/chat_cache_store.dart';
import 'package:agent_client/features/chat/domain/chat_event.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:agent_client/features/chat/domain/chat_session.dart';
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
    try {
      final messages = await ref
          .read(chatCacheStoreProvider)
          .loadRecentMessages(agentId);
      if (messages.isNotEmpty) {
        state = state.copyWith(
          sessionId: messages.last.conversationId,
          messages: messages,
          clearError: true,
        );
        return;
      }

      final repositoryMessages = await ref
          .read(agentChatRepositoryProvider)
          .loadRecentMessages(agentId);
      state = state.copyWith(
        sessionId: _sessionIdFrom(repositoryMessages),
        messages: repositoryMessages,
        clearError: true,
      );
      final cache = ref.read(chatCacheStoreProvider);
      for (final message in repositoryMessages) {
        await cache.saveMessage(message);
      }
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> refreshRecentMessages() async {
    if (state.isStreaming) {
      return;
    }

    try {
      final sessionId = state.sessionId;
      final repositoryMessages = await ref
          .read(agentChatRepositoryProvider)
          .loadRecentMessages(agentId, sessionId: sessionId);
      if (repositoryMessages.isEmpty) {
        state = state.copyWith(
          sessionId: sessionId,
          messages: const [],
          clearError: true,
        );
        return;
      }

      state = state.copyWith(
        sessionId: _sessionIdFrom(repositoryMessages) ?? sessionId,
        messages: repositoryMessages,
        clearError: true,
      );
      final cache = ref.read(chatCacheStoreProvider);
      for (final message in repositoryMessages) {
        await cache.saveMessage(message);
      }
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> sendMessage(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty || state.isStreaming) {
      return;
    }

    try {
      final sessionId = await _ensureSessionId();
      final userMessage = ChatMessage(
        id: _newMessageId('user'),
        agentId: agentId,
        conversationId: sessionId,
        role: ChatRole.user,
        content: trimmed,
        status: ChatMessageStatus.completed,
        createdAt: DateTime.now(),
      );
      final assistantMessageId = _newMessageId('assistant');

      state = state.copyWith(
        messages: [...state.messages, userMessage],
        isStreaming: true,
        clearError: true,
        clearReasoning: true,
        clearProgress: true,
        clearToolHint: true,
      );
      await ref.read(chatCacheStoreProvider).saveMessage(userMessage);

      final request = SendMessageRequest(
        agentId: agentId,
        sessionId: sessionId,
        assistantMessageId: assistantMessageId,
        input: trimmed,
      );

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
    final sessionId = state.sessionId;
    if (sessionId == null) {
      return;
    }
    await ref
        .read(agentChatRepositoryProvider)
        .cancelActiveResponse(agentId: agentId, sessionId: sessionId);
    final messages = state.messages.map((message) {
      if (message.role == ChatRole.assistant &&
          message.status == ChatMessageStatus.streaming) {
        return message.copyWith(status: ChatMessageStatus.stopped);
      }
      return message;
    }).toList();
    state = state.copyWith(messages: messages, isStreaming: false);
  }

  Future<void> startNewSession() async {
    if (state.isStreaming) {
      return;
    }

    try {
      final session = await ref
          .read(agentChatRepositoryProvider)
          .startNewSession(agentId);
      ref.read(chatSessionsProvider(agentId).notifier).insertSession(session);
      await ref.read(chatCacheStoreProvider).clearMessages(agentId);
      state = ChatState(agentId: agentId, sessionId: session.id);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> startLocalSessionPreview() async {
    if (state.isStreaming) {
      return;
    }

    final sessionId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    ref
        .read(chatSessionsProvider(agentId).notifier)
        .insertNewSession(sessionId);
    state = ChatState(agentId: agentId, sessionId: sessionId);
  }

  Future<void> openSessionPreview(ChatSessionSummary session) async {
    if (state.isStreaming) {
      return;
    }

    ref.read(chatSessionsProvider(agentId).notifier).selectSession(session.id);
    final cachedMessages = await ref
        .read(chatCacheStoreProvider)
        .loadRecentMessages(agentId);
    final scopedCache = [
      for (final message in cachedMessages)
        if (message.conversationId == session.id) message,
    ];
    final messages = scopedCache.isNotEmpty
        ? scopedCache
        : await _messagesForSession(session.id);

    state = ChatState(
      agentId: agentId,
      sessionId: session.id,
      messages: messages,
    );
  }

  Future<List<ChatMessage>> _messagesForSession(String sessionId) async {
    try {
      final repositoryMessages = await ref
          .read(agentChatRepositoryProvider)
          .loadRecentMessages(agentId, sessionId: sessionId);
      if (repositoryMessages.isNotEmpty) {
        final cache = ref.read(chatCacheStoreProvider);
        for (final message in repositoryMessages) {
          await cache.saveMessage(message);
        }
        return repositoryMessages;
      }
    } catch (_) {
      return const [];
    }
    return const [];
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
        _applyToolEvent(event.payload);
      case ChatEventType.taskEvent:
        _applyTaskEvent(event.payload);
    }
  }

  void _ensureAssistantMessage(String messageId) {
    if (state.messages.any((message) => message.id == messageId)) {
      return;
    }

    final message = ChatMessage(
      id: messageId,
      agentId: agentId,
      conversationId: state.sessionId ?? '',
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
              conversationId: state.sessionId ?? '',
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

  void _applyToolEvent(Map<String, Object?> payload) {
    if (payload['kind'] == 'tool_hint') {
      state = state.copyWith(toolHintText: payload['text']?.toString());
    }
  }

  void _applyTaskEvent(Map<String, Object?> payload) {
    switch (payload['kind']) {
      case 'reasoning':
        state = state.copyWith(reasoningText: payload['text']?.toString());
      case 'reasoning_done':
        state = state.copyWith(clearReasoning: true);
      case 'progress':
        state = state.copyWith(progressText: payload['text']?.toString());
      case 'goal_status':
        state = state.copyWith(goalStatus: payload['state']?.toString());
      case 'goal_state':
        final goalState = payload['goalState'];
        if (goalState is Map<String, Object?>) {
          state = state.copyWith(goalState: goalState);
        }
    }
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

  Future<String> _ensureSessionId() async {
    if (state.sessionId case final sessionId?) {
      return sessionId;
    }
    final sessionId = await ref
        .read(agentChatRepositoryProvider)
        .ensureSessionId(agentId);
    state = state.copyWith(sessionId: sessionId, clearError: true);
    return sessionId;
  }

  String? _sessionIdFrom(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return null;
    }
    final sessionId = messages.last.conversationId;
    return sessionId.isEmpty ? null : sessionId;
  }
}
