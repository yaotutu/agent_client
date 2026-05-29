enum AgentStatus { online, busy, offline }

class Agent {
  const Agent({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.status = AgentStatus.online,
    this.model,
    this.provider,
    this.workspace,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final AgentStatus status;
  final String? model;
  final String? provider;
  final String? workspace;
}
