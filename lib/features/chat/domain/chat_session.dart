enum ChatSessionStatus { idle, running, error }

class ChatSessionSummary {
  const ChatSessionSummary({
    required this.id,
    required this.title,
    required this.preview,
    required this.updatedLabel,
    required this.messageCount,
    this.status = ChatSessionStatus.idle,
  });

  final String id;
  final String title;
  final String preview;
  final String updatedLabel;
  final int messageCount;
  final ChatSessionStatus status;
}
