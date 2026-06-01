enum AgentStatus { online, busy, offline }

const defaultAgentBackendId = 'agent-control';

class Agent {
  const Agent({
    required this.id,
    required this.name,
    this.description,
    this.backendId = defaultAgentBackendId,
    String? backendAgentId,
    this.avatarUrl,
    this.status = AgentStatus.online,
    this.model,
    this.provider,
    this.workspace,
  }) : backendAgentId = backendAgentId ?? id;

  final String id;
  final String name;
  final String? description;
  final String backendId;
  final String backendAgentId;
  final String? avatarUrl;
  final AgentStatus status;
  final String? model;
  final String? provider;
  final String? workspace;

  Agent copyWith({String? avatarUrl}) {
    return Agent(
      id: id,
      name: name,
      description: description,
      backendId: backendId,
      backendAgentId: backendAgentId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status,
      model: model,
      provider: provider,
      workspace: workspace,
    );
  }
}
