import 'package:agent_client/features/nanobot/data/nanobot_ws_client.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_message.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_shell_models.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_thread_state.dart';

enum NanobotStreamErrorKind { messageTooBig }

class NanobotStreamError {
  const NanobotStreamError({required this.kind});

  final NanobotStreamErrorKind kind;
}

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
    this.appActionMessage,
    this.appRequiresRestart = false,
    this.automationItems = const [],
    this.skillItems = const [],
    this.selectedSkillItem,
    this.selectedSkillDetail,
    this.isLoadingSkillDetail = false,
    this.skillDetailError,
    this.capabilityMentions = const [],
    this.slashCommands = const [],
    this.isLoadingSurface = false,
    this.sidebarState = const NanobotSidebarState(),
    this.workspacesSnapshot,
    this.draftWorkspaceScope,
    this.workspaceError,
    this.filePreviewPath,
    this.filePreview,
    this.filePreviewError,
    this.modelName,
    this.socketStatus = NanobotSocketStatus.idle,
    this.isBootstrapping = false,
    this.isLoadingThread = false,
    this.isLoadingFilePreview = false,
    this.isStreaming = false,
    this.reasoningText,
    this.activityText,
    this.errorMessage,
    this.streamError,
  });

  final List<NanobotSessionSummary> sessions;
  final List<NanobotMessage> messages;
  final String? selectedSessionKey;
  final String? selectedChatId;
  final NanobotThreadState? threadState;
  final NanobotShellView activeView;
  final NanobotSettingsSnapshot? settingsSnapshot;
  final List<NanobotCatalogItem> appItems;
  final String? appActionMessage;
  final bool appRequiresRestart;
  final List<NanobotCatalogItem> automationItems;
  final List<NanobotCatalogItem> skillItems;
  final NanobotCatalogItem? selectedSkillItem;
  final NanobotSkillDetail? selectedSkillDetail;
  final bool isLoadingSkillDetail;
  final String? skillDetailError;
  final List<NanobotCapabilityMention> capabilityMentions;
  final List<NanobotSlashCommand> slashCommands;
  final bool isLoadingSurface;
  final NanobotSidebarState sidebarState;
  final NanobotWorkspaceSnapshot? workspacesSnapshot;
  final NanobotWorkspaceScope? draftWorkspaceScope;
  final String? workspaceError;
  final String? filePreviewPath;
  final NanobotFilePreview? filePreview;
  final String? filePreviewError;
  final String? modelName;
  final NanobotSocketStatus socketStatus;
  final bool isBootstrapping;
  final bool isLoadingThread;
  final bool isLoadingFilePreview;
  final bool isStreaming;
  final String? reasoningText;
  final String? activityText;
  final String? errorMessage;
  final NanobotStreamError? streamError;

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

  NanobotWorkspaceScope? get activeWorkspaceScope {
    return selectedSession?.workspaceScope ??
        draftWorkspaceScope ??
        workspacesSnapshot?.defaultScope;
  }

  bool get canUseFullWorkspaceAccess {
    return workspacesSnapshot?.canUseFullAccess ?? true;
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
      if (sidebarState.sort == 'title_asc') {
        final titleOrder = _compareNaturalTitles(
          displayTitleFor(a),
          displayTitleFor(b),
        );
        if (titleOrder != 0) {
          return titleOrder;
        }
        return _sessionTime(b).compareTo(_sessionTime(a));
      }
      if (sidebarState.sort == 'created_desc') {
        return _createdTime(b).compareTo(_createdTime(a));
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
    String? appActionMessage,
    bool? appRequiresRestart,
    List<NanobotCatalogItem>? automationItems,
    List<NanobotCatalogItem>? skillItems,
    NanobotCatalogItem? selectedSkillItem,
    NanobotSkillDetail? selectedSkillDetail,
    bool? isLoadingSkillDetail,
    String? skillDetailError,
    List<NanobotCapabilityMention>? capabilityMentions,
    List<NanobotSlashCommand>? slashCommands,
    bool? isLoadingSurface,
    NanobotSidebarState? sidebarState,
    NanobotWorkspaceSnapshot? workspacesSnapshot,
    NanobotWorkspaceScope? draftWorkspaceScope,
    String? workspaceError,
    String? filePreviewPath,
    NanobotFilePreview? filePreview,
    String? filePreviewError,
    String? modelName,
    NanobotSocketStatus? socketStatus,
    bool? isBootstrapping,
    bool? isLoadingThread,
    bool? isLoadingFilePreview,
    bool? isStreaming,
    String? reasoningText,
    String? activityText,
    String? errorMessage,
    NanobotStreamError? streamError,
    bool clearSelectedSession = false,
    bool clearThreadState = false,
    bool clearSettingsSnapshot = false,
    bool clearSurfaceItems = false,
    bool clearAppActionMessage = false,
    bool clearSelectedSkill = false,
    bool clearSkillDetail = false,
    bool clearSkillDetailError = false,
    bool clearDraftWorkspaceScope = false,
    bool clearWorkspaceError = false,
    bool clearFilePreview = false,
    bool clearFilePreviewError = false,
    bool clearModelName = false,
    bool clearReasoning = false,
    bool clearActivity = false,
    bool clearError = false,
    bool clearStreamError = false,
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
      appActionMessage: clearSurfaceItems || clearAppActionMessage
          ? null
          : appActionMessage ?? this.appActionMessage,
      appRequiresRestart: clearSurfaceItems
          ? false
          : appRequiresRestart ?? this.appRequiresRestart,
      automationItems: clearSurfaceItems
          ? const []
          : automationItems ?? this.automationItems,
      skillItems: clearSurfaceItems ? const [] : skillItems ?? this.skillItems,
      selectedSkillItem: clearSelectedSkill
          ? null
          : selectedSkillItem ?? this.selectedSkillItem,
      selectedSkillDetail: clearSelectedSkill || clearSkillDetail
          ? null
          : selectedSkillDetail ?? this.selectedSkillDetail,
      isLoadingSkillDetail: isLoadingSkillDetail ?? this.isLoadingSkillDetail,
      skillDetailError: clearSelectedSkill || clearSkillDetailError
          ? null
          : skillDetailError ?? this.skillDetailError,
      capabilityMentions: capabilityMentions ?? this.capabilityMentions,
      slashCommands: slashCommands ?? this.slashCommands,
      isLoadingSurface: isLoadingSurface ?? this.isLoadingSurface,
      sidebarState: sidebarState ?? this.sidebarState,
      workspacesSnapshot: workspacesSnapshot ?? this.workspacesSnapshot,
      draftWorkspaceScope: clearDraftWorkspaceScope
          ? null
          : draftWorkspaceScope ?? this.draftWorkspaceScope,
      workspaceError: clearWorkspaceError
          ? null
          : workspaceError ?? this.workspaceError,
      filePreviewPath: clearFilePreview
          ? null
          : filePreviewPath ?? this.filePreviewPath,
      filePreview: clearFilePreview ? null : filePreview ?? this.filePreview,
      filePreviewError: clearFilePreview || clearFilePreviewError
          ? null
          : filePreviewError ?? this.filePreviewError,
      modelName: clearModelName ? null : modelName ?? this.modelName,
      socketStatus: socketStatus ?? this.socketStatus,
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      isLoadingThread: isLoadingThread ?? this.isLoadingThread,
      isLoadingFilePreview: isLoadingFilePreview ?? this.isLoadingFilePreview,
      isStreaming: isStreaming ?? this.isStreaming,
      reasoningText: clearReasoning
          ? null
          : reasoningText ?? this.reasoningText,
      activityText: clearActivity ? null : activityText ?? this.activityText,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      streamError: clearStreamError ? null : streamError ?? this.streamError,
    );
  }

  static int _sessionTime(NanobotSessionSummary session) {
    return (session.updatedAt ?? session.createdAt)?.millisecondsSinceEpoch ??
        0;
  }

  static int _createdTime(NanobotSessionSummary session) {
    return session.createdAt?.millisecondsSinceEpoch ?? 0;
  }

  static int _compareNaturalTitles(String a, String b) {
    final aParts = _titleParts(a);
    final bParts = _titleParts(b);
    final count = aParts.length < bParts.length ? aParts.length : bParts.length;
    for (var i = 0; i < count; i += 1) {
      final aPart = aParts[i];
      final bPart = bParts[i];
      final aNumber = int.tryParse(aPart);
      final bNumber = int.tryParse(bPart);
      final result = aNumber != null && bNumber != null
          ? aNumber.compareTo(bNumber)
          : aPart.toLowerCase().compareTo(bPart.toLowerCase());
      if (result != 0) {
        return result;
      }
    }
    return aParts.length.compareTo(bParts.length);
  }

  static List<String> _titleParts(String value) {
    return RegExp(
      r'\d+|\D+',
    ).allMatches(value.trim()).map((match) => match.group(0) ?? '').toList();
  }
}
