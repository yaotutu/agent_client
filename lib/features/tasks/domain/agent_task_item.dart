enum AgentTaskStatus { todo, inProgress, blocked, done }

class AgentTaskItem {
  const AgentTaskItem({
    required this.title,
    required this.status,
    required this.dueLabel,
    required this.detail,
  });

  final String title;
  final AgentTaskStatus status;
  final String dueLabel;
  final String detail;
}
