import 'package:agent_client/core/config/app_config.dart';
import 'package:agent_client/core/network/dio_provider.dart';
import 'package:agent_client/features/chat/data/mock_agent_chat_repository.dart';
import 'package:agent_client/features/chat/data/openai_chat_completions_agent_chat_repository.dart';
import 'package:agent_client/features/chat/domain/chat_event.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract interface class AgentChatRepository {
  Stream<ChatEvent> sendMessage(SendMessageRequest request);

  Future<void> cancelActiveResponse(String conversationId);

  Future<List<ChatMessage>> loadRecentMessages(String agentId);
}

class SendMessageRequest {
  const SendMessageRequest({
    required this.agentId,
    required this.conversationId,
    required this.input,
    this.history = const [],
  });

  final String agentId;
  final String conversationId;
  final String input;
  final List<ChatMessage> history;
}

final agentChatRepositoryProvider = Provider<AgentChatRepository>((ref) {
  return const MockAgentChatRepository();
});

final openAiChatCompletionsRepositoryProvider = Provider<AgentChatRepository>((
  ref,
) {
  return OpenAiChatCompletionsAgentChatRepository(
    dio: ref.watch(dioProvider),
    config: ref.watch(appConfigProvider),
  );
});
