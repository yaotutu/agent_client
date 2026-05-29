import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/chat/data/agent_control_chat_repository.dart';
import 'package:agent_client/features/chat/domain/chat_event.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:agent_client/features/chat/domain/chat_session.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract interface class AgentChatRepository {
  Future<String> ensureSessionId(String agentId);

  Future<ChatSessionSummary> startNewSession(String agentId);

  Future<List<ChatSessionSummary>> listSessions(String agentId);

  Stream<ChatEvent> sendMessage(SendMessageRequest request);

  Future<void> cancelActiveResponse({
    required String agentId,
    required String sessionId,
  });

  Future<List<ChatMessage>> loadRecentMessages(
    String agentId, {
    String? sessionId,
  });
}

class SendMessageRequest {
  const SendMessageRequest({
    required this.agentId,
    required this.sessionId,
    required this.assistantMessageId,
    required this.input,
  });

  final String agentId;
  final String sessionId;
  final String assistantMessageId;
  final String input;
}

final agentChatRepositoryProvider = Provider<AgentChatRepository>((ref) {
  return AgentControlChatRepository(
    api: ref.watch(agentControlApiClientProvider),
  );
});
