import 'package:agent_client/features/nanobot/data/nanobot_ws_client.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_message.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';

class NanobotWorkspaceState {
  const NanobotWorkspaceState({
    this.sessions = const [],
    this.messages = const [],
    this.selectedSessionKey,
    this.selectedChatId,
    this.modelName,
    this.socketStatus = NanobotSocketStatus.idle,
    this.isBootstrapping = false,
    this.isLoadingThread = false,
    this.isStreaming = false,
    this.reasoningText,
    this.activityText,
    this.errorMessage,
  });

  final List<NanobotSessionSummary> sessions;
  final List<NanobotMessage> messages;
  final String? selectedSessionKey;
  final String? selectedChatId;
  final String? modelName;
  final NanobotSocketStatus socketStatus;
  final bool isBootstrapping;
  final bool isLoadingThread;
  final bool isStreaming;
  final String? reasoningText;
  final String? activityText;
  final String? errorMessage;

  NanobotSessionSummary? get selectedSession {
    final key = selectedSessionKey;
    if (key == null) {
      return null;
    }
    for (final session in sessions) {
      if (session.key == key) {
        return session;
      }
    }
    return null;
  }

  bool get canSend {
    return !isBootstrapping && !isLoadingThread;
  }

  NanobotWorkspaceState copyWith({
    List<NanobotSessionSummary>? sessions,
    List<NanobotMessage>? messages,
    String? selectedSessionKey,
    String? selectedChatId,
    String? modelName,
    NanobotSocketStatus? socketStatus,
    bool? isBootstrapping,
    bool? isLoadingThread,
    bool? isStreaming,
    String? reasoningText,
    String? activityText,
    String? errorMessage,
    bool clearSelectedSession = false,
    bool clearModelName = false,
    bool clearReasoning = false,
    bool clearActivity = false,
    bool clearError = false,
  }) {
    return NanobotWorkspaceState(
      sessions: sessions ?? this.sessions,
      messages: messages ?? this.messages,
      selectedSessionKey: clearSelectedSession
          ? null
          : selectedSessionKey ?? this.selectedSessionKey,
      selectedChatId: clearSelectedSession
          ? null
          : selectedChatId ?? this.selectedChatId,
      modelName: clearModelName ? null : modelName ?? this.modelName,
      socketStatus: socketStatus ?? this.socketStatus,
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      isLoadingThread: isLoadingThread ?? this.isLoadingThread,
      isStreaming: isStreaming ?? this.isStreaming,
      reasoningText: clearReasoning
          ? null
          : reasoningText ?? this.reasoningText,
      activityText: clearActivity ? null : activityText ?? this.activityText,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
