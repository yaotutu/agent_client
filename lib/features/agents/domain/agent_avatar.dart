class AgentAvatarOption {
  const AgentAvatarOption({
    required this.id,
    required this.label,
    required this.assetPath,
  });

  final String id;
  final String label;
  final String assetPath;
}

abstract final class AgentAvatarOptions {
  static const defaults = [
    AgentAvatarOption(
      id: 'coder',
      label: 'Coder',
      assetPath: 'assets/agent_avatars/coder.png',
    ),
    AgentAvatarOption(
      id: 'reviewer',
      label: 'Reviewer',
      assetPath: 'assets/agent_avatars/reviewer.png',
    ),
    AgentAvatarOption(
      id: 'researcher',
      label: 'Researcher',
      assetPath: 'assets/agent_avatars/researcher.png',
    ),
    AgentAvatarOption(
      id: 'planner',
      label: 'Planner',
      assetPath: 'assets/agent_avatars/planner.png',
    ),
    AgentAvatarOption(
      id: 'operator',
      label: 'Operator',
      assetPath: 'assets/agent_avatars/operator.png',
    ),
    AgentAvatarOption(
      id: 'designer',
      label: 'Designer',
      assetPath: 'assets/agent_avatars/designer.png',
    ),
  ];

  static bool isDefaultAssetPath(String? value) {
    if (value == null) {
      return false;
    }
    return defaults.any((option) => option.assetPath == value);
  }
}
