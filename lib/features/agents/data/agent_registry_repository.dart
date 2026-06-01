import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/domain/agent_control_models.dart'
    as agent_control;
import 'package:agent_client/features/agents/data/agent_avatar_store.dart';
import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const agentControlBackendId = defaultAgentBackendId;

final agentRegistryRepositoryProvider = Provider<AgentRegistryRepository>((
  ref,
) {
  return LocalAvatarAgentRegistryRepository(
    delegate: AgentControlAgentRegistryRepository(
      ref.watch(agentControlApiClientProvider),
    ),
    avatarStore: ref.watch(agentAvatarStoreProvider),
  );
});

abstract interface class AgentRegistryRepository {
  Future<List<Agent>> listAgents();

  Future<Agent> createAgent({
    required String name,
    String? description,
    String? avatarUrl,
  });

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
  Future<Agent> createAgent({
    required String name,
    String? description,
    String? avatarUrl,
  }) async {
    final created = await _api.createAgent(
      name: name,
      description: description,
    );
    return Agent(
      id: created.name,
      name: created.name,
      description: created.description ?? description,
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
      description: summary.description,
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

class LocalAvatarAgentRegistryRepository implements AgentRegistryRepository {
  const LocalAvatarAgentRegistryRepository({
    required this.delegate,
    required this.avatarStore,
  });

  final AgentRegistryRepository delegate;
  final AgentAvatarStore avatarStore;

  @override
  Future<List<Agent>> listAgents() async {
    final agents = await delegate.listAgents();
    final avatarUrls = await avatarStore.loadAvatarUrls();
    return [
      for (final agent in agents)
        if (avatarUrls[agent.id] case final avatarUrl?)
          agent.copyWith(avatarUrl: avatarUrl)
        else
          agent,
    ];
  }

  @override
  Future<Agent> createAgent({
    required String name,
    String? description,
    String? avatarUrl,
  }) async {
    final created = await delegate.createAgent(
      name: name,
      description: description,
    );
    final trimmedAvatarUrl = avatarUrl?.trim();
    if (trimmedAvatarUrl == null || trimmedAvatarUrl.isEmpty) {
      return created;
    }

    await avatarStore.saveAvatar(
      agentId: created.id,
      agentName: created.name,
      avatarUrl: trimmedAvatarUrl,
      status: created.status,
    );
    return created.copyWith(avatarUrl: trimmedAvatarUrl);
  }

  @override
  Future<void> deleteAgent(String agentId) async {
    await delegate.deleteAgent(agentId);
    await avatarStore.deleteAvatar(agentId);
  }
}
