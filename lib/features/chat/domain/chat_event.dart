import 'package:collection/collection.dart';

enum ChatEventType {
  messageStarted,
  textDelta,
  messageCompleted,
  toolEvent,
  taskEvent,
  error,
}

class ChatEvent {
  const ChatEvent._({
    required this.type,
    required this.messageId,
    this.delta,
    this.payload = const {},
    this.errorMessage,
  });

  const ChatEvent.messageStarted({required String messageId})
    : this._(type: ChatEventType.messageStarted, messageId: messageId);

  const ChatEvent.textDelta({required String messageId, required String delta})
    : this._(type: ChatEventType.textDelta, messageId: messageId, delta: delta);

  const ChatEvent.messageCompleted({required String messageId})
    : this._(type: ChatEventType.messageCompleted, messageId: messageId);

  const ChatEvent.toolEvent({
    required String messageId,
    required Map<String, Object?> payload,
  }) : this._(
         type: ChatEventType.toolEvent,
         messageId: messageId,
         payload: payload,
       );

  const ChatEvent.taskEvent({
    required String messageId,
    required Map<String, Object?> payload,
  }) : this._(
         type: ChatEventType.taskEvent,
         messageId: messageId,
         payload: payload,
       );

  const ChatEvent.error({
    required String messageId,
    required String errorMessage,
  }) : this._(
         type: ChatEventType.error,
         messageId: messageId,
         errorMessage: errorMessage,
       );

  final ChatEventType type;
  final String messageId;
  final String? delta;
  final Map<String, Object?> payload;
  final String? errorMessage;

  @override
  bool operator ==(Object other) {
    return other is ChatEvent &&
        other.type == type &&
        other.messageId == messageId &&
        other.delta == delta &&
        const DeepCollectionEquality().equals(other.payload, payload) &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
    type,
    messageId,
    delta,
    const DeepCollectionEquality().hash(payload),
    errorMessage,
  );

  @override
  String toString() {
    return 'ChatEvent($type, messageId: $messageId, delta: $delta)';
  }
}
