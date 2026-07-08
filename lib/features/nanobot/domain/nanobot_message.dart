enum NanobotMessageRole { system, user, assistant, tool }

enum NanobotMessageStatus { streaming, completed, failed }

class NanobotMessage {
  const NanobotMessage({
    required this.id,
    required this.sessionKey,
    required this.chatId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.status = NanobotMessageStatus.completed,
    this.reasoning,
  });

  final String id;
  final String sessionKey;
  final String chatId;
  final NanobotMessageRole role;
  final String content;
  final DateTime createdAt;
  final NanobotMessageStatus status;
  final String? reasoning;

  NanobotMessage copyWith({
    String? id,
    String? sessionKey,
    String? chatId,
    NanobotMessageRole? role,
    String? content,
    DateTime? createdAt,
    NanobotMessageStatus? status,
    String? reasoning,
  }) {
    return NanobotMessage(
      id: id ?? this.id,
      sessionKey: sessionKey ?? this.sessionKey,
      chatId: chatId ?? this.chatId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      reasoning: reasoning ?? this.reasoning,
    );
  }

  factory NanobotMessage.fromWebuiJson({
    required Map<String, Object?> json,
    required String sessionKey,
    required String chatId,
  }) {
    return NanobotMessage(
      id:
          json['id'] as String? ??
          'history-${DateTime.now().microsecondsSinceEpoch}',
      sessionKey: sessionKey,
      chatId: chatId,
      role: _roleFromString(json['role'] as String?),
      content: json['content'] as String? ?? '',
      reasoning: json['reasoning'] as String?,
      createdAt: _createdAt(json['createdAt'] ?? json['created_at']),
      status: json['isStreaming'] == true
          ? NanobotMessageStatus.streaming
          : NanobotMessageStatus.completed,
    );
  }

  static NanobotMessageRole _roleFromString(String? value) {
    return switch (value) {
      'system' => NanobotMessageRole.system,
      'user' => NanobotMessageRole.user,
      'tool' => NanobotMessageRole.tool,
      _ => NanobotMessageRole.assistant,
    };
  }

  static DateTime _createdAt(Object? value) {
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
