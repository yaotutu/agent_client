import 'package:agent_client/features/nanobot/domain/nanobot_media_attachment.dart';

enum NanobotThreadRole { system, user, assistant, tool }

enum NanobotThreadEntryKind { message, trace, fileEdit }

class NanobotThreadState {
  const NanobotThreadState({
    required this.sessionKey,
    required this.chatId,
    this.entries = const [],
    this.isStreaming = false,
    this.runStartedAt,
    this.goalState,
    this.userMessageOffset = 0,
  });

  final String sessionKey;
  final String chatId;
  final List<NanobotThreadEntry> entries;
  final bool isStreaming;
  final int? runStartedAt;
  final Map<String, Object?>? goalState;
  final int userMessageOffset;

  NanobotThreadState copyWith({
    List<NanobotThreadEntry>? entries,
    bool? isStreaming,
    int? runStartedAt,
    Map<String, Object?>? goalState,
    int? userMessageOffset,
    bool clearRunStartedAt = false,
    bool clearGoalState = false,
  }) {
    return NanobotThreadState(
      sessionKey: sessionKey,
      chatId: chatId,
      entries: entries ?? this.entries,
      isStreaming: isStreaming ?? this.isStreaming,
      runStartedAt: clearRunStartedAt
          ? null
          : runStartedAt ?? this.runStartedAt,
      goalState: clearGoalState ? null : goalState ?? this.goalState,
      userMessageOffset: userMessageOffset ?? this.userMessageOffset,
    );
  }
}

class NanobotThreadEntry {
  const NanobotThreadEntry({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.kind = NanobotThreadEntryKind.message,
    this.isStreaming = false,
    this.traces = const [],
    this.toolEvents = const [],
    this.fileEdits = const [],
    this.media = const [],
    this.reasoning,
    this.reasoningStreaming = false,
    this.latencyMs,
    this.source,
    this.agentUi,
    this.turnId,
    this.turnPhase,
    this.turnSeq,
  });

  final String id;
  final NanobotThreadRole role;
  final String content;
  final DateTime createdAt;
  final NanobotThreadEntryKind kind;
  final bool isStreaming;
  final List<String> traces;
  final List<Map<String, Object?>> toolEvents;
  final List<Map<String, Object?>> fileEdits;
  final List<NanobotMediaAttachment> media;
  final String? reasoning;
  final bool reasoningStreaming;
  final int? latencyMs;
  final Map<String, Object?>? source;
  final Map<String, Object?>? agentUi;
  final String? turnId;
  final String? turnPhase;
  final int? turnSeq;

  NanobotThreadEntry copyWith({
    String? id,
    NanobotThreadRole? role,
    String? content,
    DateTime? createdAt,
    NanobotThreadEntryKind? kind,
    bool? isStreaming,
    List<String>? traces,
    List<Map<String, Object?>>? toolEvents,
    List<Map<String, Object?>>? fileEdits,
    List<NanobotMediaAttachment>? media,
    String? reasoning,
    bool? reasoningStreaming,
    int? latencyMs,
    Map<String, Object?>? source,
    Map<String, Object?>? agentUi,
    String? turnId,
    String? turnPhase,
    int? turnSeq,
  }) {
    return NanobotThreadEntry(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      kind: kind ?? this.kind,
      isStreaming: isStreaming ?? this.isStreaming,
      traces: traces ?? this.traces,
      toolEvents: toolEvents ?? this.toolEvents,
      fileEdits: fileEdits ?? this.fileEdits,
      media: media ?? this.media,
      reasoning: reasoning ?? this.reasoning,
      reasoningStreaming: reasoningStreaming ?? this.reasoningStreaming,
      latencyMs: latencyMs ?? this.latencyMs,
      source: source ?? this.source,
      agentUi: agentUi ?? this.agentUi,
      turnId: turnId ?? this.turnId,
      turnPhase: turnPhase ?? this.turnPhase,
      turnSeq: turnSeq ?? this.turnSeq,
    );
  }
}
