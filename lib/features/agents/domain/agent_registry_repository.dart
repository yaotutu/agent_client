import 'package:agent_client/features/agents/domain/agent.dart';

abstract interface class AgentRegistryRepository {
  Future<List<Agent>> listAgents();

  Future<Agent> createAgent({
    required String name,
    String? description,
    String? avatarUrl,
  });

  Future<void> updateAgentAvatar({
    required Agent agent,
    required String avatarUrl,
  });

  Future<void> deleteAgent(String agentId);
}
