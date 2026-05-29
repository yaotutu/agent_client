import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/chat/data/agent_chat_repository.dart';
import 'package:agent_client/features/chat/data/agent_control_chat_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final agentChatRepositoryProvider = Provider<AgentChatRepository>((ref) {
  return AgentControlChatRepository(
    api: ref.watch(agentControlApiClientProvider),
  );
});
