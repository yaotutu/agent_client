import 'package:agent_client/features/nanobot/data/nanobot_ws_client.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_message.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_shell_models.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_thread_state.dart';

class NanobotWorkspaceState {
  const NanobotWorkspaceState({
    this.sessions = const [],
    this.messages = const [],
    this.selectedSessionKey,
    this.selectedChatId,
    this.threadState,
    this.activeView = NanobotShellView.chat,
    this.settingsSnapshot,
    this.appItems = const [],
    this.automationItems = const [],
    this.skillItems = const [],
    this.isLoadingSurface = false,
    this.sidebarState = const NanobotSidebarState(),
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
  final NanobotThreadState? threadState;
  final NanobotShellView activeView;
  final NanobotSettingsSnapshot? settingsSnapshot;
  final List<NanobotCatalogItem> appItems;
  final List<NanobotCatalogItem> automationItems;
  final List<NanobotCatalogItem> skillItems;
  final bool isLoadingSurface;
  final NanobotSidebarState sidebarState;
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

  List<NanobotSessionSummary> get visibleSessions {
    final archived = sidebarState.archivedKeys.toSet();
    final pinnedIndex = <String, int>{
      for (var i = 0; i < sidebarState.pinnedKeys.length; i += 1)
        sidebarState.pinnedKeys[i]: i,
    };
    final rows = [
      for (final session in sessions)
        if (sidebarState.showArchived || !archived.contains(session.key))
          session,
    ];
    rows.sort((a, b) {
      final aPinned = pinnedIndex[a.key];
      final bPinned = pinnedIndex[b.key];
      if (aPinned != null || bPinned != null) {
        if (aPinned == null) return 1;
        if (bPinned == null) return -1;
        return aPinned.compareTo(bPinned);
      }
      return _sessionTime(b).compareTo(_sessionTime(a));
    });
    return rows;
  }

  String displayTitleFor(NanobotSessionSummary session) {
    final override = sidebarState.titleOverrides[session.key]?.trim();
    if (override != null && override.isNotEmpty) {
      return override;
    }
    return session.displayTitle;
  }

  NanobotWorkspaceState copyWith({
    List<NanobotSessionSummary>? sessions,
    List<NanobotMessage>? messages,
    String? selectedSessionKey,
    String? selectedChatId,
    NanobotThreadState? threadState,
    NanobotShellView? activeView,
    NanobotSettingsSnapshot? settingsSnapshot,
    List<NanobotCatalogItem>? appItems,
    List<NanobotCatalogItem>? automationItems,
    List<NanobotCatalogItem>? skillItems,
    bool? isLoadingSurface,
    NanobotSidebarState? sidebarState,
    String? modelName,
    NanobotSocketStatus? socketStatus,
    bool? isBootstrapping,
    bool? isLoadingThread,
    bool? isStreaming,
    String? reasoningText,
    String? activityText,
    String? errorMessage,
    bool clearSelectedSession = false,
    bool clearThreadState = false,
    bool clearSettingsSnapshot = false,
    bool clearSurfaceItems = false,
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
      threadState: clearThreadState ? null : threadState ?? this.threadState,
      activeView: activeView ?? this.activeView,
      settingsSnapshot: clearSettingsSnapshot
          ? null
          : settingsSnapshot ?? this.settingsSnapshot,
      appItems: clearSurfaceItems ? const [] : appItems ?? this.appItems,
      automationItems: clearSurfaceItems
          ? const []
          : automationItems ?? this.automationItems,
      skillItems: clearSurfaceItems ? const [] : skillItems ?? this.skillItems,
      isLoadingSurface: isLoadingSurface ?? this.isLoadingSurface,
      sidebarState: sidebarState ?? this.sidebarState,
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

  static int _sessionTime(NanobotSessionSummary session) {
    return (session.updatedAt ?? session.createdAt)?.millisecondsSinceEpoch ??
        0;
  }
}
