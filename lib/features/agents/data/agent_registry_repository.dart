import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/domain/agent_control_models.dart'
    as agent_control;
import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const agentControlBackendId = defaultAgentBackendId;

final agentRegistryRepositoryProvider = Provider<AgentRegistryRepository>((
  ref,
) {
  return AgentControlAgentRegistryRepository(
    ref.watch(agentControlApiClientProvider),
  );
});

abstract interface class AgentRegistryRepository {
  Future<List<Agent>> listAgents();

  Future<Agent> createAgent({required String name, String? description});

  Future<void> deleteAgent(String agentId);
}

class AgentControlAgentRegistryRepository implements AgentRegistryRepository {
  const AgentControlAgentRegistryRepository(this._api);

  final AgentControlApi _api;

  @override
  Future<List<Agent>> listAgents() async {
    final response = await _api.listAgents();
    return response.data.map(_toAgent).toList();
  }

  @override
  Future<Agent> createAgent({required String name, String? description}) async {
    final created = await _api.createAgent(
      name: name,
      description: description,
    );
    return Agent(
      id: created.name,
      name: created.name,
      backendId: agentControlBackendId,
      backendAgentId: created.name,
      status: _statusFor(created.status),
      model: created.model,
      provider: created.provider,
      workspace: created.workspaceDir,
    );
  }

  @override
  Future<void> deleteAgent(String agentId) async {
    await _api.deleteAgent(agentId);
  }

  Agent _toAgent(agent_control.AgentSummary summary) {
    return Agent(
      id: summary.name,
      name: summary.name,
      backendId: agentControlBackendId,
      backendAgentId: summary.name,
      status: _statusFor(summary.status),
      model: summary.model,
      provider: summary.provider,
      workspace: summary.workspaceDir,
    );
  }

  AgentStatus _statusFor(String status) {
    return switch (status) {
      'running' => AgentStatus.online,
      _ => AgentStatus.offline,
    };
  }
}
