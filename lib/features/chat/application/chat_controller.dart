import 'package:agent_client/features/chat/application/chat_conversation_preview_provider.dart';
import 'package:agent_client/features/chat/application/chat_state.dart';
import 'package:agent_client/features/chat/application/chat_sessions_controller.dart';
import 'package:agent_client/features/chat/data/agent_chat_repository.dart';
import 'package:agent_client/features/chat/data/agent_chat_repository_provider.dart';
import 'package:agent_client/features/chat/data/chat_cache_provider.dart';
import 'package:agent_client/features/chat/domain/chat_event.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:agent_client/features/chat/domain/chat_session.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final chatControllerProvider =
    NotifierProvider.family<ChatController, ChatState, String>(
      ChatController.new,
    );

final chatStopPollingDelayProvider = Provider<Duration>(
  (_) => const Duration(milliseconds: 400),
);

final chatStopPollingTimeoutProvider = Provider<Duration>(
  (_) => const Duration(seconds: 15),
);

class ChatController extends Notifier<ChatState> {
  ChatController(this.agentId);

  final String agentId;
  var _loadGeneration = 0;

  @override
  ChatState build() => ChatState.initial(agentId);

  Future<void> preloadCachedMessages() async {
    if (state.isStreaming || state.isStopping || state.messages.isNotEmpty) {
      return;
    }

    final selectedSessionId = ref
        .read(chatSessionsProvider(agentId))
        .selectedSessionId;
    final cachedMessages = await _cachedMessages(
      selectedSessionId ?? state.sessionId,
    );
    if (cachedMessages.isEmpty) {
      return;
    }

    state = state.copyWith(
      sessionId: _sessionIdFrom(cachedMessages) ?? selectedSessionId,
      messages: cachedMessages,
      clearError: true,
    );
  }

  Future<void> loadRecentMessages() async {
    if (state.isStreaming || state.isStopping) {
      return;
    }

    final generation = _nextLoadGeneration();
    final selectedSessionId = ref
        .read(chatSessionsProvider(agentId))
        .selectedSessionId;
    final targetSessionId = selectedSessionId ?? state.sessionId;
    var hasLocalMessages = state.messages.isNotEmpty;
    var sessionId = targetSessionId;

    if (!hasLocalMessages) {
      final cachedMessages = await _cachedMessages(sessionId);
      if (!_isActiveLoad(generation)) {
        return;
      }
      if (cachedMessages.isNotEmpty) {
        sessionId = _sessionIdFrom(cachedMessages) ?? sessionId;
        state = state.copyWith(
          sessionId: sessionId,
          messages: cachedMessages,
          clearError: true,
        );
        hasLocalMessages = true;
      }
    }

    await _replaceFromRepository(
      sessionId: sessionId,
      keepLocalOnError: hasLocalMessages,
      generation: generation,
    );
  }

  Future<void> refreshRecentMessages() async {
    if (state.isStreaming || state.isStopping) {
      return;
    }

    await _replaceFromRepository(
      sessionId: state.sessionId,
      keepLocalOnError: state.messages.isNotEmpty,
      generation: _nextLoadGeneration(),
    );
  }

  Future<void> sendMessage(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty || state.isStreaming || state.isStopping) {
      return;
    }

    _nextLoadGeneration();
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
        isStopping: false,
        clearError: true,
        clearReasoning: true,
        clearProgress: true,
        clearToolHint: true,
        clearGoalStatus: true,
        clearGoalState: true,
      );
      await ref.read(chatCacheStoreProvider).saveMessage(userMessage);
      _invalidateConversationPreview();

      final request = SendMessageRequest(
        agentId: agentId,
        sessionId: sessionId,
        assistantMessageId: assistantMessageId,
        input: trimmed,
      );

      var shouldWaitForSessionIdle = false;
      await for (final event
          in ref.read(agentChatRepositoryProvider).sendMessage(request)) {
        shouldWaitForSessionIdle =
            _applyEvent(event) || shouldWaitForSessionIdle;
      }

      if (shouldWaitForSessionIdle) {
        await _clearStoppingWhenIdle(sessionId);
      }

      if (state.isStreaming) {
        _completeAssistantMessage(assistantMessageId);
      }
    } catch (error) {
      _failAssistantMessage(error.toString());
    } finally {
      await _persistMessages();
    }
  }

  Future<void> cancelActiveResponse() async {
    final sessionId = state.sessionId;
    if (sessionId == null || state.isStopping) {
      return;
    }

    final messages = _stopStreamingAssistantMessages(state.messages);
    state = state.copyWith(
      messages: messages,
      isStreaming: false,
      isStopping: true,
      clearError: true,
      clearReasoning: true,
      clearProgress: true,
      clearToolHint: true,
      clearGoalStatus: true,
      clearGoalState: true,
    );

    try {
      await ref
          .read(agentChatRepositoryProvider)
          .cancelActiveResponse(agentId: agentId, sessionId: sessionId);
      await _clearStoppingWhenIdle(sessionId);
    } catch (error) {
      state = state.copyWith(
        isStreaming: false,
        isStopping: false,
        errorMessage: error.toString(),
      );
    }

    await _persistMessages();
  }

  Future<void> startNewSession() async {
    if (state.isStreaming || state.isStopping) {
      return;
    }

    _nextLoadGeneration();
    try {
      final session = await ref
          .read(agentChatRepositoryProvider)
          .startNewSession(agentId);
      ref.read(chatSessionsProvider(agentId).notifier).insertSession(session);
      state = ChatState(agentId: agentId, sessionId: session.id);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> openSessionPreview(ChatSessionSummary session) async {
    if (state.isStreaming || state.isStopping) {
      return;
    }

    final generation = _nextLoadGeneration();
    ref.read(chatSessionsProvider(agentId).notifier).selectSession(session.id);
    final cachedMessages = await ref
        .read(chatCacheStoreProvider)
        .loadMessages(agentId: agentId, sessionId: session.id);
    if (!_isActiveLoad(generation)) {
      return;
    }
    final messages = cachedMessages.isNotEmpty
        ? cachedMessages
        : await _messagesForSession(session.id);
    if (!_isActiveLoad(generation)) {
      return;
    }

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
        await _replaceCachedMessages(repositoryMessages);
        return repositoryMessages;
      }
    } catch (_) {
      return const [];
    }
    return const [];
  }

  bool _applyEvent(ChatEvent event) {
    switch (event.type) {
      case ChatEventType.messageStarted:
        _ensureAssistantMessage(event.messageId);
        return false;
      case ChatEventType.textDelta:
        _appendAssistantDelta(event.messageId, event.delta ?? '');
        return false;
      case ChatEventType.messageCompleted:
        _completeAssistantMessage(event.messageId);
        return false;
      case ChatEventType.error:
        if (_isSessionStateConflict(event.errorCode, event.errorMessage)) {
          _handleSessionStateConflict(event);
          return _isSessionStoppingConflict(
            event.errorCode,
            event.errorMessage,
          );
        } else {
          _failAssistantMessage(event.errorMessage ?? 'Response failed');
          return false;
        }
      case ChatEventType.activity:
        final activity = event.activity;
        if (activity != null) {
          _applyActivity(activity);
        }
        return false;
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
      isStopping: false,
      clearReasoning: true,
      clearProgress: true,
      clearToolHint: true,
      clearGoalStatus: true,
      clearGoalState: true,
    );
  }

  void _failAssistantMessage(String errorMessage) {
    final hasStreamingAssistant = state.messages.any(
      (message) =>
          message.role == ChatRole.assistant &&
          message.status == ChatMessageStatus.streaming,
    );
    final messages = hasStreamingAssistant
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
      isStopping: false,
      errorMessage: errorMessage,
      clearReasoning: true,
      clearProgress: true,
      clearToolHint: true,
      clearGoalStatus: true,
      clearGoalState: true,
    );
  }

  void _applyActivity(ChatActivity activity) {
    switch (activity.type) {
      case ChatActivityType.reasoning:
        state = state.copyWith(
          reasoningText: '${state.reasoningText ?? ''}${activity.text ?? ''}',
        );
      case ChatActivityType.reasoningDone:
        state = state.copyWith(clearReasoning: true);
      case ChatActivityType.progress:
        state = state.copyWith(progressText: activity.text);
      case ChatActivityType.toolHint:
        state = state.copyWith(toolHintText: activity.text);
      case ChatActivityType.goalStatus:
        state = state.copyWith(goalStatus: activity.state);
      case ChatActivityType.goalState:
        state = state.copyWith(goalState: activity.goalState);
      case ChatActivityType.streamEnd:
        break;
    }
  }

  List<ChatMessage> _stopStreamingAssistantMessages(
    List<ChatMessage> messages,
  ) {
    return messages.map((message) {
      if (message.role == ChatRole.assistant &&
          message.status == ChatMessageStatus.streaming) {
        return message.copyWith(status: ChatMessageStatus.stopped);
      }
      return message;
    }).toList();
  }

  void _handleSessionStateConflict(ChatEvent event) {
    final messages = <ChatMessage>[];
    for (final message in state.messages) {
      final conflictingAssistant =
          message.id == event.messageId &&
          message.role == ChatRole.assistant &&
          message.status == ChatMessageStatus.streaming;
      if (!conflictingAssistant) {
        messages.add(message);
        continue;
      }
      if (message.content.trim().isNotEmpty || message.attachments.isNotEmpty) {
        messages.add(message.copyWith(status: ChatMessageStatus.stopped));
      }
    }

    state = state.copyWith(
      messages: messages,
      isStreaming: false,
      isStopping: _isSessionStoppingConflict(
        event.errorCode,
        event.errorMessage,
      ),
      errorMessage:
          event.errorMessage ?? 'Current session is still processing.',
      clearReasoning: true,
      clearProgress: true,
      clearToolHint: true,
      clearGoalStatus: true,
      clearGoalState: true,
    );
  }

  bool _isSessionStateConflict(String? code, String? message) {
    return _isSessionBusyConflict(code, message) ||
        _isSessionStoppingConflict(code, message);
  }

  bool _isSessionBusyConflict(String? code, String? message) {
    final normalizedCode = code?.toUpperCase();
    if (normalizedCode == 'SESSION_BUSY') {
      return true;
    }
    return message?.toLowerCase().contains('session is busy') == true;
  }

  bool _isSessionStoppingConflict(String? code, String? message) {
    final normalizedCode = code?.toUpperCase();
    if (normalizedCode == 'SESSION_STOPPING') {
      return true;
    }
    return message?.toLowerCase().contains('session is stopping') == true;
  }

  Future<bool> _waitUntilSessionIdle(String sessionId) async {
    final timeout = ref.read(chatStopPollingTimeoutProvider);
    final delay = ref.read(chatStopPollingDelayProvider);
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      final sessions = await ref
          .read(agentChatRepositoryProvider)
          .listSessions(agentId);
      final session = _sessionWithId(sessions, sessionId);
      if (session == null || session.status == ChatSessionStatus.idle) {
        return true;
      }
      await Future<void>.delayed(delay);
    }

    return false;
  }

  Future<void> _clearStoppingWhenIdle(String sessionId) async {
    final idle = await _waitUntilSessionIdle(sessionId);
    state = state.copyWith(
      isStreaming: false,
      isStopping: false,
      errorMessage: idle
          ? null
          : 'Current session is still stopping. Please wait before sending.',
      clearError: idle,
    );
  }

  ChatSessionSummary? _sessionWithId(
    List<ChatSessionSummary> sessions,
    String sessionId,
  ) {
    for (final session in sessions) {
      if (session.id == sessionId) {
        return session;
      }
    }
    return null;
  }

  Future<void> _persistMessages() async {
    await _replaceCachedMessages(state.messages);
  }

  Future<List<ChatMessage>> _cachedMessages(String? sessionId) {
    final cache = ref.read(chatCacheStoreProvider);
    if (sessionId != null && sessionId.isNotEmpty) {
      return cache.loadMessages(agentId: agentId, sessionId: sessionId);
    }
    return cache.loadLatestMessages(agentId);
  }

  Future<void> _replaceFromRepository({
    required String? sessionId,
    required bool keepLocalOnError,
    required int generation,
  }) async {
    try {
      final repositoryMessages = await ref
          .read(agentChatRepositoryProvider)
          .loadRecentMessages(agentId, sessionId: sessionId);
      if (!_isActiveLoad(generation)) {
        return;
      }
      final resolvedSessionId = _sessionIdFrom(repositoryMessages) ?? sessionId;

      if (repositoryMessages.isEmpty) {
        if (resolvedSessionId != null && resolvedSessionId.isNotEmpty) {
          await ref
              .read(chatCacheStoreProvider)
              .clearSession(agentId: agentId, sessionId: resolvedSessionId);
        }
        state = state.copyWith(
          sessionId: resolvedSessionId,
          messages: const [],
          clearError: true,
        );
        _invalidateConversationPreview();
        return;
      }

      state = state.copyWith(
        sessionId: resolvedSessionId,
        messages: repositoryMessages,
        clearError: true,
      );
      await _replaceCachedMessages(repositoryMessages);
    } catch (error) {
      if (_isActiveLoad(generation) &&
          (!keepLocalOnError || state.messages.isEmpty)) {
        state = state.copyWith(errorMessage: error.toString());
      }
    }
  }

  Future<void> _replaceCachedMessages(List<ChatMessage> messages) async {
    if (messages.isEmpty) {
      return;
    }

    final sessionId = _sessionIdFrom(messages);
    if (sessionId == null || sessionId.isEmpty) {
      return;
    }

    final cache = ref.read(chatCacheStoreProvider);
    await cache.clearSession(agentId: agentId, sessionId: sessionId);
    for (final message in messages) {
      await cache.saveMessage(message);
    }
    _invalidateConversationPreview();
  }

  void _invalidateConversationPreview() {
    ref.invalidate(latestCachedChatMessageProvider(agentId));
  }

  int _nextLoadGeneration() {
    _loadGeneration += 1;
    return _loadGeneration;
  }

  bool _isActiveLoad(int generation) {
    return generation == _loadGeneration;
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
