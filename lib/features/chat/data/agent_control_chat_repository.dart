import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/domain/agent_control_models.dart';
import 'package:agent_client/features/chat/data/agent_chat_repository.dart';
import 'package:agent_client/features/chat/domain/chat_event.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:agent_client/features/chat/domain/chat_session.dart';
import 'package:dio/dio.dart';

class AgentControlChatRepository implements AgentChatRepository {
  AgentControlChatRepository({
    required this.api,
    this.startupPollDelay = const Duration(milliseconds: 500),
    this.startupPollAttempts = 30,
  });

  final AgentControlApi api;
  final Duration startupPollDelay;
  final int startupPollAttempts;
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, String> _sessionIdsByAgent = {};

  @override
  Future<String> ensureSessionId(String agentId) async {
    if (_sessionIdsByAgent[agentId] case final sessionId?) {
      return sessionId;
    }

    final card = await _ensureAgentReady(agentId);
    final defaultSessionId = card.state.defaultSessionId;
    if (defaultSessionId != null && defaultSessionId.isNotEmpty) {
      _sessionIdsByAgent[agentId] = defaultSessionId;
      return defaultSessionId;
    }

    final created = await api.createSession(agentId);
    _sessionIdsByAgent[agentId] = created.sessionId;
    return created.sessionId;
  }

  @override
  Future<ChatSessionSummary> startNewSession(String agentId) async {
    await _ensureAgentReady(agentId);
    final created = await api.createSession(agentId);
    _sessionIdsByAgent[agentId] = created.sessionId;
    return _createdSessionToChatSession(created);
  }

  @override
  Future<List<ChatSessionSummary>> listSessions(String agentId) async {
    final response = await api.listSessions(agentId);
    return response.data.map(_sessionSummaryToChatSession).toList();
  }

  Future<AgentCard> _ensureAgentReady(String agentId) async {
    final card = await api.getAgentCard(agentId);
    if (_isHealthy(card)) {
      return card;
    }

    await api.startAgent(agentId);
    for (var attempt = 0; attempt < startupPollAttempts; attempt += 1) {
      if (startupPollDelay > Duration.zero) {
        await Future<void>.delayed(startupPollDelay);
      }
      final refreshed = await api.getAgentCard(agentId);
      if (_isHealthy(refreshed)) {
        return refreshed;
      }
    }

    throw AgentControlApiException(
      message: 'Agent "$agentId" did not become ready after start',
    );
  }

  bool _isHealthy(AgentCard card) => card.state.health == 'healthy';

  @override
  Future<void> cancelActiveResponse({
    required String agentId,
    required String sessionId,
  }) async {
    _cancelTokens.remove(sessionId)?.cancel('stopped by user');
    await api.stopAgentTask(agentName: agentId, sessionId: sessionId);
  }

  @override
  Future<List<ChatMessage>> loadRecentMessages(
    String agentId, {
    String? sessionId,
  }) async {
    final resolvedSessionId =
        sessionId ?? await _latestPersistedSessionId(agentId);
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

    return [
      for (var index = 0; index < history.messages.length; index += 1)
        _toChatMessage(
          agentId: agentId,
          sessionId: backendSessionId,
          index: index,
          message: history.messages[index],
        ),
    ];
  }

  Future<String?> _latestPersistedSessionId(String agentId) async {
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
    if (sessionId.isEmpty) {
      return null;
    }

    return sessionId;
  }

  @override
  Stream<ChatEvent> sendMessage(SendMessageRequest request) async* {
    final cancelToken = CancelToken();
    _cancelTokens[request.sessionId] = cancelToken;

    yield ChatEvent.messageStarted(messageId: request.assistantMessageId);

    try {
      await _ensureAgentReady(request.agentId);
      if (_sessionIdsByAgent[request.agentId] != request.sessionId) {
        await api.attachSession(
          agentName: request.agentId,
          sessionId: request.sessionId,
        );
        _sessionIdsByAgent[request.agentId] = request.sessionId;
      }

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
      );
    } finally {
      _cancelTokens.remove(request.sessionId);
    }
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

  ChatSessionSummary _createdSessionToChatSession(
    CreateSessionResponse session,
  ) {
    return ChatSessionSummary(
      id: session.sessionId,
      title: session.title.isEmpty ? 'New chat' : session.title,
      preview: session.preview,
      updatedLabel: _relativeLabel(session.updatedAt ?? session.createdAt),
      messageCount: session.messageCount,
      status: _sessionStatus(session.status),
    );
  }

  ChatSessionSummary _sessionSummaryToChatSession(SessionSummary session) {
    return ChatSessionSummary(
      id: session.sessionId,
      title: session.title.isEmpty ? 'Untitled chat' : session.title,
      preview: session.preview,
      updatedLabel: _relativeLabel(session.updatedAt ?? session.createdAt),
      messageCount: session.messageCount,
      status: _sessionStatus(session.status),
    );
  }

  ChatSessionStatus _sessionStatus(String status) {
    return switch (status) {
      'running' => ChatSessionStatus.running,
      'error' => ChatSessionStatus.error,
      _ => ChatSessionStatus.idle,
    };
  }

  String _relativeLabel(DateTime? value) {
    if (value == null) {
      return '';
    }
    final local = value.toLocal();
    final now = DateTime.now();
    final sameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    return '${local.month}/${local.day}';
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
      AgentControlStreamEventType.reasoning => ChatEvent.taskEvent(
        messageId: assistantMessageId,
        payload: {'kind': 'reasoning', 'text': event.text ?? ''},
      ),
      AgentControlStreamEventType.reasoningDone => ChatEvent.taskEvent(
        messageId: assistantMessageId,
        payload: const {'kind': 'reasoning_done'},
      ),
      AgentControlStreamEventType.progress => ChatEvent.taskEvent(
        messageId: assistantMessageId,
        payload: {'kind': 'progress', 'text': event.text ?? ''},
      ),
      AgentControlStreamEventType.toolHint => ChatEvent.toolEvent(
        messageId: assistantMessageId,
        payload: {
          'kind': 'tool_hint',
          'text': event.text ?? '',
          'toolEvents': event.toolEvents,
        },
      ),
      AgentControlStreamEventType.goalStatus => ChatEvent.taskEvent(
        messageId: assistantMessageId,
        payload: {
          'kind': 'goal_status',
          'state': event.state,
          'startedAt': event.startedAt,
        },
      ),
      AgentControlStreamEventType.goalState => ChatEvent.taskEvent(
        messageId: assistantMessageId,
        payload: {'kind': 'goal_state', 'goalState': event.goalState},
      ),
      AgentControlStreamEventType.streamEnd => ChatEvent.taskEvent(
        messageId: assistantMessageId,
        payload: const {'kind': 'stream_end'},
      ),
      AgentControlStreamEventType.done => ChatEvent.messageCompleted(
        messageId: assistantMessageId,
      ),
      AgentControlStreamEventType.error => ChatEvent.error(
        messageId: assistantMessageId,
        errorMessage: event.message ?? 'Response failed',
      ),
      AgentControlStreamEventType.doneMarker ||
      AgentControlStreamEventType.unknown => null,
    };
  }
}
