import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/data/agent_control_chat_services.dart';
import 'package:agent_client/features/chat/data/agent_chat_repository.dart';
import 'package:agent_client/features/chat/domain/chat_event.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:agent_client/features/chat/domain/chat_session.dart';

class AgentControlChatRepository implements AgentChatRepository {
  AgentControlChatRepository({
    required this.api,
    this.startupPollDelay = const Duration(milliseconds: 500),
    this.startupPollAttempts = 30,
  }) {
    final readiness = AgentReadinessService(
      api: api,
      startupPollDelay: startupPollDelay,
      startupPollAttempts: startupPollAttempts,
    );
    final sessions = AgentSessionService(api: api, readiness: readiness);
    _sessions = sessions;
    _history = AgentChatHistoryService(api: api, sessions: sessions);
    _turns = AgentChatTurnService(
      api: api,
      readiness: readiness,
      sessions: sessions,
    );
  }

  final AgentControlApi api;
  final Duration startupPollDelay;
  final int startupPollAttempts;
  late final AgentSessionService _sessions;
  late final AgentChatHistoryService _history;
  late final AgentChatTurnService _turns;

  @override
  Future<String> ensureSessionId(String agentId) =>
      _sessions.ensureSessionId(agentId);

  @override
  Future<ChatSessionSummary> startNewSession(String agentId) =>
      _sessions.startNewSession(agentId);

  @override
  Future<List<ChatSessionSummary>> listSessions(String agentId) =>
      _sessions.listSessions(agentId);

  @override
  Future<void> cancelActiveResponse({
    required String agentId,
    required String sessionId,
  }) => _turns.cancelActiveResponse(agentId: agentId, sessionId: sessionId);

  @override
  Future<List<ChatMessage>> loadRecentMessages(
    String agentId, {
    String? sessionId,
  }) => _history.loadRecentMessages(agentId, sessionId: sessionId);

  @override
  Stream<ChatEvent> sendMessage(SendMessageRequest request) =>
      _turns.sendMessage(request);
}
