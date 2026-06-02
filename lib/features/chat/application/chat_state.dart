import 'package:agent_client/features/chat/domain/chat_message.dart';

class ChatState {
  const ChatState({
    required this.agentId,
    this.sessionId,
    this.messages = const [],
    this.isStreaming = false,
    this.isStopping = false,
    this.errorMessage,
    this.reasoningText,
    this.progressText,
    this.toolHintText,
    this.fileEditText,
    this.goalStatus,
    this.goalState,
  });

  factory ChatState.initial(String agentId) {
    return ChatState(agentId: agentId);
  }

  final String agentId;
  final String? sessionId;
  final List<ChatMessage> messages;
  final bool isStreaming;
  final bool isStopping;
  final String? errorMessage;
  final String? reasoningText;
  final String? progressText;
  final String? toolHintText;
  final String? fileEditText;
  final String? goalStatus;
  final Map<String, Object?>? goalState;

  ChatState copyWith({
    String? agentId,
    String? sessionId,
    List<ChatMessage>? messages,
    bool? isStreaming,
    bool? isStopping,
    String? errorMessage,
    String? reasoningText,
    String? progressText,
    String? toolHintText,
    String? fileEditText,
    String? goalStatus,
    Map<String, Object?>? goalState,
    bool clearError = false,
    bool clearReasoning = false,
    bool clearProgress = false,
    bool clearToolHint = false,
    bool clearFileEdits = false,
    bool clearGoalStatus = false,
    bool clearGoalState = false,
  }) {
    return ChatState(
      agentId: agentId ?? this.agentId,
      sessionId: sessionId ?? this.sessionId,
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      isStopping: isStopping ?? this.isStopping,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      reasoningText: clearReasoning
          ? null
          : reasoningText ?? this.reasoningText,
      progressText: clearProgress ? null : progressText ?? this.progressText,
      toolHintText: clearToolHint ? null : toolHintText ?? this.toolHintText,
      fileEditText: clearFileEdits ? null : fileEditText ?? this.fileEditText,
      goalStatus: clearGoalStatus ? null : goalStatus ?? this.goalStatus,
      goalState: clearGoalState ? null : goalState ?? this.goalState,
    );
  }
}
