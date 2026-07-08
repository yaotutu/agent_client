enum NanobotEventKind {
  ready,
  attached,
  message,
  delta,
  streamEnd,
  reasoningDelta,
  reasoningEnd,
  fileEdit,
  goalStatus,
  goalState,
  turnEnd,
  sessionUpdated,
  runtimeModelUpdated,
  error,
  unknown,
}

class NanobotEvent {
  const NanobotEvent({
    required this.kind,
    required this.rawEvent,
    this.chatId,
    this.text,
    this.detail,
    this.reason,
    this.modelName,
    this.startedAt,
    this.status,
  });

  final NanobotEventKind kind;
  final String rawEvent;
  final String? chatId;
  final String? text;
  final String? detail;
  final String? reason;
  final String? modelName;
  final int? startedAt;
  final String? status;

  factory NanobotEvent.fromJson(Map<String, Object?> json) {
    final event = json['event'] as String? ?? '';
    return NanobotEvent(
      kind: _kindFrom(event),
      rawEvent: event,
      chatId: json['chat_id'] as String?,
      text: json['text'] as String?,
      detail: json['detail'] as String?,
      reason: json['reason'] as String?,
      modelName: json['model_name'] as String?,
      startedAt: json['started_at'] is num
          ? (json['started_at'] as num).toInt()
          : null,
      status: json['status'] as String?,
    );
  }

  static NanobotEventKind _kindFrom(String value) {
    return switch (value) {
      'ready' => NanobotEventKind.ready,
      'attached' => NanobotEventKind.attached,
      'message' => NanobotEventKind.message,
      'delta' => NanobotEventKind.delta,
      'stream_end' => NanobotEventKind.streamEnd,
      'reasoning_delta' => NanobotEventKind.reasoningDelta,
      'reasoning_end' => NanobotEventKind.reasoningEnd,
      'file_edit' => NanobotEventKind.fileEdit,
      'goal_status' => NanobotEventKind.goalStatus,
      'goal_state' => NanobotEventKind.goalState,
      'turn_end' => NanobotEventKind.turnEnd,
      'session_updated' => NanobotEventKind.sessionUpdated,
      'runtime_model_updated' => NanobotEventKind.runtimeModelUpdated,
      'error' => NanobotEventKind.error,
      _ => NanobotEventKind.unknown,
    };
  }
}
