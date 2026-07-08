import 'package:agent_client/features/nanobot/data/protocol/nanobot_ws_envelope.dart';

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
  transcriptionResult,
  transcriptionError,
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
    this.provider,
    this.modelName,
    this.modelPreset,
    this.clientId,
    this.requestId,
    this.streamId,
    this.kindLabel,
    this.startedAt,
    this.latencyMs,
    this.turnSeq,
    this.status,
    this.scope,
    this.replyTo,
    this.turnId,
    this.turnPhase,
    this.media = const [],
    this.mediaUrls = const [],
    this.toolEvents = const [],
    this.fileEdits = const [],
    this.source,
    this.agentUi,
    this.goalState,
    this.workspaceScope,
  });

  final NanobotEventKind kind;
  final String rawEvent;
  final String? chatId;
  final String? text;
  final String? detail;
  final String? reason;
  final String? provider;
  final String? modelName;
  final String? modelPreset;
  final String? clientId;
  final String? requestId;
  final String? streamId;
  final String? kindLabel;
  final int? startedAt;
  final int? latencyMs;
  final int? turnSeq;
  final String? status;
  final String? scope;
  final String? replyTo;
  final String? turnId;
  final String? turnPhase;
  final List<String> media;
  final List<Map<String, Object?>> mediaUrls;
  final List<Map<String, Object?>> toolEvents;
  final List<Map<String, Object?>> fileEdits;
  final Map<String, Object?>? source;
  final Map<String, Object?>? agentUi;
  final Map<String, Object?>? goalState;
  final Map<String, Object?>? workspaceScope;

  factory NanobotEvent.fromJson(Map<String, Object?> json) {
    final envelope = NanobotInboundEnvelope.fromJson(json);
    return NanobotEvent(
      kind: _kindFrom(envelope.type),
      rawEvent: envelope.rawEvent,
      chatId: envelope.chatId,
      text: envelope.text,
      detail: envelope.detail,
      reason: envelope.reason,
      provider: envelope.provider,
      modelName: envelope.modelName,
      modelPreset: envelope.modelPreset,
      clientId: envelope.clientId,
      requestId: envelope.requestId,
      streamId: envelope.streamId,
      kindLabel: envelope.kind,
      startedAt: envelope.startedAt,
      latencyMs: envelope.latencyMs,
      turnSeq: envelope.turnSeq,
      status: envelope.status,
      scope: envelope.scope,
      replyTo: envelope.replyTo,
      turnId: envelope.turnId,
      turnPhase: envelope.turnPhase,
      media: envelope.media,
      mediaUrls: envelope.mediaUrls,
      toolEvents: envelope.toolEvents,
      fileEdits: envelope.fileEdits,
      source: envelope.source,
      agentUi: envelope.agentUi,
      goalState: envelope.goalState,
      workspaceScope: envelope.workspaceScope,
    );
  }

  static NanobotEventKind _kindFrom(NanobotInboundEventType value) {
    return switch (value) {
      NanobotInboundEventType.ready => NanobotEventKind.ready,
      NanobotInboundEventType.attached => NanobotEventKind.attached,
      NanobotInboundEventType.message => NanobotEventKind.message,
      NanobotInboundEventType.delta => NanobotEventKind.delta,
      NanobotInboundEventType.streamEnd => NanobotEventKind.streamEnd,
      NanobotInboundEventType.reasoningDelta => NanobotEventKind.reasoningDelta,
      NanobotInboundEventType.reasoningEnd => NanobotEventKind.reasoningEnd,
      NanobotInboundEventType.fileEdit => NanobotEventKind.fileEdit,
      NanobotInboundEventType.goalStatus => NanobotEventKind.goalStatus,
      NanobotInboundEventType.goalState => NanobotEventKind.goalState,
      NanobotInboundEventType.turnEnd => NanobotEventKind.turnEnd,
      NanobotInboundEventType.sessionUpdated => NanobotEventKind.sessionUpdated,
      NanobotInboundEventType.runtimeModelUpdated =>
        NanobotEventKind.runtimeModelUpdated,
      NanobotInboundEventType.transcriptionResult =>
        NanobotEventKind.transcriptionResult,
      NanobotInboundEventType.transcriptionError =>
        NanobotEventKind.transcriptionError,
      NanobotInboundEventType.error => NanobotEventKind.error,
      _ => NanobotEventKind.unknown,
    };
  }
}
