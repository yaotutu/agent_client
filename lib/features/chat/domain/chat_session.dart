enum ChatSessionStatus { idle, running, stopping, error }

class ChatSessionSummary {
  const ChatSessionSummary({
    required this.id,
    required this.title,
    required this.preview,
    required this.messageCount,
    this.createdAt,
    this.updatedAt,
    this.status = ChatSessionStatus.idle,
  });

  final String id;
  final String title;
  final String preview;
  final int messageCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ChatSessionStatus status;

  DateTime? get activityAt => updatedAt ?? createdAt;

  String get updatedLabel => _relativeLabel(activityAt);
}

String _relativeLabel(DateTime? value) {
  if (value == null) {
    return '';
  }
  final local = value.toLocal();
  final now = DateTime.now();
  final sameDay =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  if (sameDay) {
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
  return '${local.month}/${local.day}';
}
