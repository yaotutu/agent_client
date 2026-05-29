enum AgentStatus { online, busy, offline }

class Agent {
  const Agent({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.status = AgentStatus.online,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final AgentStatus status;
}
