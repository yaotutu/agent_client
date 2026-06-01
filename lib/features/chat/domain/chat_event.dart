enum ChatEventType {
  messageStarted,
  textDelta,
  messageCompleted,
  activity,
  error,
}

enum ChatActivityType {
  reasoning,
  reasoningDone,
  progress,
  toolHint,
  goalStatus,
  goalState,
  streamEnd,
}

class ChatActivity {
  const ChatActivity._({
    required this.type,
    this.text,
    this.state,
    this.startedAt,
    this.goalState,
    this.toolEvents,
  });

  const ChatActivity.reasoning(String text)
    : this._(type: ChatActivityType.reasoning, text: text);

  const ChatActivity.reasoningDone()
    : this._(type: ChatActivityType.reasoningDone);

  const ChatActivity.progress(String text)
    : this._(type: ChatActivityType.progress, text: text);

  const ChatActivity.toolHint({required String text, List<Object?>? toolEvents})
    : this._(
        type: ChatActivityType.toolHint,
        text: text,
        toolEvents: toolEvents,
      );

  const ChatActivity.goalStatus({String? state, double? startedAt})
    : this._(
        type: ChatActivityType.goalStatus,
        state: state,
        startedAt: startedAt,
      );

  const ChatActivity.goalState(Map<String, Object?>? goalState)
    : this._(type: ChatActivityType.goalState, goalState: goalState);

  const ChatActivity.streamEnd() : this._(type: ChatActivityType.streamEnd);

  final ChatActivityType type;
  final String? text;
  final String? state;
  final double? startedAt;
  final Map<String, Object?>? goalState;
  final List<Object?>? toolEvents;

  @override
  bool operator ==(Object other) {
    if (other is! ChatActivity) {
      return false;
    }
    return other.type == type &&
        other.text == text &&
        other.state == state &&
        other.startedAt == startedAt &&
        _mapEquals(other.goalState, goalState) &&
        _listEquals(other.toolEvents, toolEvents);
  }

  @override
  int get hashCode => Object.hash(
    type,
    text,
    state,
    startedAt,
    _mapHash(goalState),
    _listHash(toolEvents),
  );
}

class ChatEvent {
  const ChatEvent._({
    required this.type,
    required this.messageId,
    this.delta,
    this.activity,
    this.errorMessage,
    this.errorCode,
  });

  const ChatEvent.messageStarted({required String messageId})
    : this._(type: ChatEventType.messageStarted, messageId: messageId);

  const ChatEvent.textDelta({required String messageId, required String delta})
    : this._(type: ChatEventType.textDelta, messageId: messageId, delta: delta);

  const ChatEvent.messageCompleted({required String messageId})
    : this._(type: ChatEventType.messageCompleted, messageId: messageId);

  const ChatEvent.activity({
    required String messageId,
    required ChatActivity activity,
  }) : this._(
         type: ChatEventType.activity,
         messageId: messageId,
         activity: activity,
       );

  const ChatEvent.error({
    required String messageId,
    required String errorMessage,
    String? code,
  }) : this._(
         type: ChatEventType.error,
         messageId: messageId,
         errorMessage: errorMessage,
         errorCode: code,
       );

  final ChatEventType type;
  final String messageId;
  final String? delta;
  final ChatActivity? activity;
  final String? errorMessage;
  final String? errorCode;

  @override
  bool operator ==(Object other) {
    return other is ChatEvent &&
        other.type == type &&
        other.messageId == messageId &&
        other.delta == delta &&
        other.activity == activity &&
        other.errorMessage == errorMessage &&
        other.errorCode == errorCode;
  }

  @override
  int get hashCode =>
      Object.hash(type, messageId, delta, activity, errorMessage, errorCode);

  @override
  String toString() {
    return 'ChatEvent($type, messageId: $messageId, delta: $delta)';
  }
}

bool _mapEquals(Map<String, Object?>? left, Map<String, Object?>? right) {
  if (identical(left, right)) {
    return true;
  }
  if (left == null || right == null || left.length != right.length) {
    return false;
  }
  for (final entry in left.entries) {
    if (!_deepEquals(entry.value, right[entry.key])) {
      return false;
    }
  }
  return true;
}

bool _listEquals(List<Object?>? left, List<Object?>? right) {
  if (identical(left, right)) {
    return true;
  }
  if (left == null || right == null || left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (!_deepEquals(left[index], right[index])) {
      return false;
    }
  }
  return true;
}

bool _deepEquals(Object? left, Object? right) {
  if (left is Map<String, Object?> && right is Map<String, Object?>) {
    return _mapEquals(left, right);
  }
  if (left is List<Object?> && right is List<Object?>) {
    return _listEquals(left, right);
  }
  return left == right;
}

int _mapHash(Map<String, Object?>? value) {
  if (value == null) {
    return 0;
  }
  return Object.hashAllUnordered(
    value.entries.map(
      (entry) => Object.hash(entry.key, _deepHash(entry.value)),
    ),
  );
}

int _listHash(List<Object?>? value) {
  if (value == null) {
    return 0;
  }
  return Object.hashAll(value.map(_deepHash));
}

int _deepHash(Object? value) {
  if (value is Map<String, Object?>) {
    return _mapHash(value);
  }
  if (value is List<Object?>) {
    return _listHash(value);
  }
  return value.hashCode;
}
