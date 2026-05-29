class AgentCommandItem {
  const AgentCommandItem({
    required this.command,
    required this.title,
    required this.description,
    required this.icon,
    required this.argHint,
  });

  final String command;
  final String title;
  final String description;
  final String icon;
  final String argHint;
}
