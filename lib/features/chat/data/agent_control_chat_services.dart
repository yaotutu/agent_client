import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/domain/agent_control_models.dart';
import 'package:agent_client/features/chat/data/agent_chat_repository.dart';
import 'package:agent_client/features/chat/domain/chat_event.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:agent_client/features/chat/domain/chat_session.dart';
import 'package:dio/dio.dart';

class AgentReadinessService {
  const AgentReadinessService({
    required this.api,
    this.startupPollDelay = const Duration(milliseconds: 500),
    this.startupPollAttempts = 30,
  });

  final AgentControlApi api;
  final Duration startupPollDelay;
  final int startupPollAttempts;

  Future<AgentCard> ensureReady(String agentId) async {
    final card = await api.getAgentCard(agentId);
    if (isReady(card)) {
      return card;
    }

    await api.startAgent(agentId);
    for (var attempt = 0; attempt < startupPollAttempts; attempt += 1) {
      if (startupPollDelay > Duration.zero) {
        await Future<void>.delayed(startupPollDelay);
      }
      final refreshed = await api.getAgentCard(agentId);
      if (isReady(refreshed)) {
        return refreshed;
      }
    }

    throw AgentControlApiException(
      message: 'Agent "$agentId" did not become ready after start',
    );
  }

  bool isReady(AgentCard card) {
    return switch (card.state.health.toLowerCase()) {
      'healthy' || 'ok' => true,
      _ => false,
    };
  }
}

class AgentSessionService {
  AgentSessionService({required this.api, required this.readiness});

  final AgentControlApi api;
  final AgentReadinessService readiness;
  final Map<String, String> _activeSessionIdsByAgent = {};

  Future<String> ensureSessionId(String agentId) async {
    if (_activeSessionIdsByAgent[agentId] case final sessionId?) {
      return sessionId;
    }

    final card = await readiness.ensureReady(agentId);
    final defaultSessionId = card.state.defaultSessionId;
    if (defaultSessionId != null && defaultSessionId.isNotEmpty) {
      remember(agentId: agentId, sessionId: defaultSessionId);
      return defaultSessionId;
    }

    final created = await api.createSession(agentId);
    remember(agentId: agentId, sessionId: created.sessionId);
    return created.sessionId;
  }

  Future<ChatSessionSummary> startNewSession(String agentId) async {
    await readiness.ensureReady(agentId);
    final created = await api.createSession(agentId);
    remember(agentId: agentId, sessionId: created.sessionId);
    return _createdSessionToChatSession(created);
  }

  Future<List<ChatSessionSummary>> listSessions(String agentId) async {
    final response = await api.listSessions(agentId);
    return response.data.map(_sessionSummaryToChatSession).toList();
  }

  Future<void> attachIfNeeded({
    required String agentId,
    required String sessionId,
  }) async {
    if (_activeSessionIdsByAgent[agentId] == sessionId) {
      return;
    }
    await api.attachSession(agentName: agentId, sessionId: sessionId);
    remember(agentId: agentId, sessionId: sessionId);
  }

  Future<String?> latestPersistedSessionId(String agentId) async {
    final sessions = await api.listSessions(agentId);
    if (sessions.data.isEmpty) {
      return null;
    }

    final ordered = List<SessionSummary>.of(sessions.data)
      ..sort((left, right) {
        final leftDate = left.updatedAt ?? left.createdAt ?? DateTime(0);
        final rightDate = right.updatedAt ?? right.createdAt ?? DateTime(0);
        return rightDate.compareTo(leftDate);
      });
    final sessionId = ordered.first.sessionId;
    return sessionId.isEmpty ? null : sessionId;
  }

  void remember({required String agentId, required String sessionId}) {
    _activeSessionIdsByAgent[agentId] = sessionId;
  }

  ChatSessionSummary _createdSessionToChatSession(
    CreateSessionResponse session,
  ) {
    return ChatSessionSummary(
      id: session.sessionId,
      title: session.title.isEmpty ? 'New chat' : session.title,
      preview: session.preview,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
      messageCount: session.messageCount,
      status: _sessionStatus(session.status),
    );
  }

  ChatSessionSummary _sessionSummaryToChatSession(SessionSummary session) {
    return ChatSessionSummary(
      id: session.sessionId,
      title: session.title.isEmpty ? 'Untitled chat' : session.title,
      preview: session.preview,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
      messageCount: session.messageCount,
      status: _sessionStatus(session.status),
    );
  }

  ChatSessionStatus _sessionStatus(String status) {
    return switch (status) {
      'running' => ChatSessionStatus.running,
      'stopping' => ChatSessionStatus.stopping,
      'error' => ChatSessionStatus.error,
      _ => ChatSessionStatus.idle,
    };
  }
}

class AgentChatHistoryService {
  const AgentChatHistoryService({required this.api, required this.sessions});

  final AgentControlApi api;
  final AgentSessionService sessions;
  static const _recentMessageWindowSize = 50;

  Future<List<ChatMessage>> loadRecentMessages(
    String agentId, {
    String? sessionId,
  }) async {
    final resolvedSessionId =
        sessionId ?? await sessions.latestPersistedSessionId(agentId);
    if (resolvedSessionId == null || resolvedSessionId.isEmpty) {
      return const [];
    }

    final history = await api.getSessionMessages(
      agentName: agentId,
      sessionId: resolvedSessionId,
    );
    final backendSessionId = history.sessionId.isNotEmpty
        ? history.sessionId
        : resolvedSessionId;

    final startIndex = history.messages.length > _recentMessageWindowSize
        ? history.messages.length - _recentMessageWindowSize
        : 0;

    return [
      for (var index = startIndex; index < history.messages.length; index += 1)
        _toChatMessage(
          agentId: agentId,
          sessionId: backendSessionId,
          index: index,
          message: history.messages[index],
        ),
    ];
  }

  ChatMessage _toChatMessage({
    required String agentId,
    required String sessionId,
    required int index,
    required SessionMessage message,
  }) {
    final createdAt = message.timestamp ?? DateTime.now();
    return ChatMessage(
      id: '$sessionId-$index-${createdAt.microsecondsSinceEpoch}',
      agentId: agentId,
      conversationId: sessionId,
      role: _role(message.role),
      content: message.content,
      status: ChatMessageStatus.completed,
      createdAt: createdAt,
    );
  }

  ChatRole _role(String role) {
    return switch (role) {
      'system' => ChatRole.system,
      'user' => ChatRole.user,
      'assistant' => ChatRole.assistant,
      _ => ChatRole.tool,
    };
  }
}

class AgentChatTurnService {
  AgentChatTurnService({
    required this.api,
    required this.readiness,
    required this.sessions,
  });

  final AgentControlApi api;
  final AgentReadinessService readiness;
  final AgentSessionService sessions;
  final Map<String, CancelToken> _cancelTokens = {};

  Future<void> cancelActiveResponse({
    required String agentId,
    required String sessionId,
  }) async {
    _cancelTokens
        .remove(_turnKey(agentId, sessionId))
        ?.cancel('stopped by user');
    await api.stopAgentTask(agentName: agentId, sessionId: sessionId);
  }

  Stream<ChatEvent> sendMessage(SendMessageRequest request) async* {
    final cancelToken = CancelToken();
    _cancelTokens[_turnKey(request.agentId, request.sessionId)] = cancelToken;

    yield ChatEvent.messageStarted(messageId: request.assistantMessageId);

    try {
      await readiness.ensureReady(request.agentId);
      await sessions.attachIfNeeded(
        agentId: request.agentId,
        sessionId: request.sessionId,
      );

      await for (final event in api.sendMessageStream(
        agentName: request.agentId,
        sessionId: request.sessionId,
        content: request.input,
        cancelToken: cancelToken,
      )) {
        final chatEvent = _toChatEvent(event, request.assistantMessageId);
        if (chatEvent != null) {
          yield chatEvent;
        }
      }
    } on DioException catch (error) {
      if (!CancelToken.isCancel(error)) {
        yield ChatEvent.error(
          messageId: request.assistantMessageId,
          errorMessage: error.message ?? 'Network request failed',
        );
      }
    } on AgentControlApiException catch (error) {
      yield ChatEvent.error(
        messageId: request.assistantMessageId,
        errorMessage: error.message,
        code: error.code,
      );
    } finally {
      _cancelTokens.remove(_turnKey(request.agentId, request.sessionId));
    }
  }

  ChatEvent? _toChatEvent(
    AgentControlStreamEvent event,
    String assistantMessageId,
  ) {
    return switch (event.type) {
      AgentControlStreamEventType.text => ChatEvent.textDelta(
        messageId: assistantMessageId,
        delta: event.text ?? '',
      ),
      AgentControlStreamEventType.reasoning => ChatEvent.activity(
        messageId: assistantMessageId,
        activity: ChatActivity.reasoning(event.text ?? ''),
      ),
      AgentControlStreamEventType.reasoningDone => ChatEvent.activity(
        messageId: assistantMessageId,
        activity: const ChatActivity.reasoningDone(),
      ),
      AgentControlStreamEventType.progress => ChatEvent.activity(
        messageId: assistantMessageId,
        activity: ChatActivity.progress(event.text ?? ''),
      ),
      AgentControlStreamEventType.toolHint => ChatEvent.activity(
        messageId: assistantMessageId,
        activity: ChatActivity.toolHint(
          text: event.text ?? '',
          toolEvents: event.toolEvents,
        ),
      ),
      AgentControlStreamEventType.goalStatus => ChatEvent.activity(
        messageId: assistantMessageId,
        activity: ChatActivity.goalStatus(
          state: event.state,
          startedAt: event.startedAt,
        ),
      ),
      AgentControlStreamEventType.goalState => ChatEvent.activity(
        messageId: assistantMessageId,
        activity: ChatActivity.goalState(event.goalState),
      ),
      AgentControlStreamEventType.streamEnd => ChatEvent.activity(
        messageId: assistantMessageId,
        activity: const ChatActivity.streamEnd(),
      ),
      AgentControlStreamEventType.done => ChatEvent.messageCompleted(
        messageId: assistantMessageId,
      ),
      AgentControlStreamEventType.error => ChatEvent.error(
        messageId: assistantMessageId,
        errorMessage: event.message ?? 'Response failed',
        code: event.code,
      ),
      AgentControlStreamEventType.doneMarker ||
      AgentControlStreamEventType.unknown => null,
    };
  }

  String _turnKey(String agentId, String sessionId) => '$agentId::$sessionId';
}
