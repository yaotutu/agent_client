import 'dart:async';

import 'package:agent_client/features/nanobot/application/nanobot_thread_reducer.dart';
import 'package:agent_client/features/nanobot/application/nanobot_workspace_state.dart';
import 'package:agent_client/features/nanobot/data/nanobot_providers.dart';
import 'package:agent_client/features/nanobot/data/nanobot_repository.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_event.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_message.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_shell_models.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_thread_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final nanobotWorkspaceControllerProvider =
    NotifierProvider<NanobotWorkspaceController, NanobotWorkspaceState>(
      NanobotWorkspaceController.new,
    );

class NanobotWorkspaceController extends Notifier<NanobotWorkspaceState> {
  StreamSubscription<NanobotEvent>? _eventSubscription;
  StreamSubscription<Object?>? _statusSubscription;
  var _loadGeneration = 0;

  @override
  NanobotWorkspaceState build() {
    final repository = ref.watch(nanobotRepositoryProvider);
    _eventSubscription?.cancel();
    _statusSubscription?.cancel();
    _eventSubscription = repository.events.listen(_handleEvent);
    _statusSubscription = repository.status.listen((status) {
      state = state.copyWith(socketStatus: status);
    });
    ref.onDispose(() {
      _eventSubscription?.cancel();
      _statusSubscription?.cancel();
    });
    Future.microtask(initialize);
    return const NanobotWorkspaceState(isBootstrapping: true);
  }

  Future<void> initialize() async {
    final generation = ++_loadGeneration;
    state = state.copyWith(isBootstrapping: true, clearError: true);
    try {
      final repository = ref.read(nanobotRepositoryProvider);
      final bootstrap = await repository.bootstrap();
      await repository.connect();
      if (!_isActive(generation)) {
        return;
      }
      final sessions = await repository.listSessions();
      if (!_isActive(generation)) {
        return;
      }
      final sidebarState = await _loadSidebarState(repository);
      if (!_isActive(generation)) {
        return;
      }
      final workspacesSnapshot = await _loadWorkspacesSnapshot(repository);
      if (!_isActive(generation)) {
        return;
      }
      state = state.copyWith(
        sessions: sessions,
        sidebarState: sidebarState,
        workspacesSnapshot: workspacesSnapshot,
        modelName: bootstrap.modelName,
        isBootstrapping: false,
        socketStatus: repository.currentStatus,
        clearError: true,
      );
      if (sessions.isNotEmpty) {
        await selectSession(sessions.first);
      }
    } on Object catch (error) {
      if (!_isActive(generation)) {
        return;
      }
      state = state.copyWith(
        isBootstrapping: false,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> refreshSessions() async {
    try {
      final sessions = await ref.read(nanobotRepositoryProvider).listSessions();
      state = state.copyWith(sessions: sessions, clearError: true);
    } on Object catch (error) {
      state = state.copyWith(errorMessage: _friendlyError(error));
    }
  }

  Future<NanobotSidebarState> _loadSidebarState(
    NanobotRepositoryPort repository,
  ) async {
    try {
      return await repository.fetchSidebarState();
    } on Object {
      return const NanobotSidebarState();
    }
  }

  Future<NanobotWorkspaceSnapshot?> _loadWorkspacesSnapshot(
    NanobotRepositoryPort repository,
  ) async {
    try {
      return await repository.fetchWorkspacesSnapshot();
    } on Object {
      return null;
    }
  }

  void openChat() {
    state = state.copyWith(activeView: NanobotShellView.chat);
  }

  Future<void> openSettings() async {
    state = state.copyWith(
      activeView: NanobotShellView.settings,
      isLoadingSurface: true,
      clearError: true,
    );
    try {
      final snapshot = await ref
          .read(nanobotRepositoryProvider)
          .fetchSettingsSnapshot();
      state = state.copyWith(
        settingsSnapshot: snapshot,
        isLoadingSurface: false,
        clearError: true,
      );
    } on Object catch (error) {
      state = state.copyWith(
        isLoadingSurface: false,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> openApps() {
    return _openCatalog(
      NanobotShellView.apps,
      () => ref.read(nanobotRepositoryProvider).fetchAppItems(),
      (items) => state.copyWith(
        appItems: items,
        isLoadingSurface: false,
        clearError: true,
      ),
    );
  }

  Future<void> openAutomations() {
    return _openCatalog(
      NanobotShellView.automations,
      () => ref.read(nanobotRepositoryProvider).fetchAutomationItems(),
      (items) => state.copyWith(
        automationItems: items,
        isLoadingSurface: false,
        clearError: true,
      ),
    );
  }

  Future<void> openSkills() {
    return _openCatalog(
      NanobotShellView.skills,
      () => ref.read(nanobotRepositoryProvider).fetchSkillItems(),
      (items) => state.copyWith(
        skillItems: items,
        isLoadingSurface: false,
        clearError: true,
      ),
    );
  }

  Future<void> toggleShowArchived() {
    return _updateSidebarState(
      state.sidebarState.copyWith(
        showArchived: !state.sidebarState.showArchived,
      ),
    );
  }

  Future<void> toggleSessionPinned(String key) {
    final pinned = [...state.sidebarState.pinnedKeys];
    if (pinned.contains(key)) {
      pinned.remove(key);
    } else {
      pinned.add(key);
    }
    return _updateSidebarState(state.sidebarState.copyWith(pinnedKeys: pinned));
  }

  Future<void> toggleSessionArchived(String key) async {
    final archived = [...state.sidebarState.archivedKeys];
    final wasArchived = archived.contains(key);
    if (wasArchived) {
      archived.remove(key);
    } else {
      archived.add(key);
    }
    final pinned = state.sidebarState.pinnedKeys
        .where((item) => item != key)
        .toList();
    await _updateSidebarState(
      state.sidebarState.copyWith(pinnedKeys: pinned, archivedKeys: archived),
    );
    if (!wasArchived && state.selectedSessionKey == key) {
      final archivedSet = state.sidebarState.archivedKeys.toSet();
      for (final session in state.sessions) {
        if (!archivedSet.contains(session.key)) {
          await selectSession(session);
          return;
        }
      }
      state = state.copyWith(
        clearSelectedSession: true,
        clearThreadState: true,
        messages: const [],
        clearReasoning: true,
        clearActivity: true,
      );
    }
  }

  Future<void> renameSession(String key, String title) {
    final overrides = {...state.sidebarState.titleOverrides};
    final cleaned = title.trim();
    if (cleaned.isEmpty) {
      overrides.remove(key);
    } else {
      overrides[key] = cleaned;
    }
    return _updateSidebarState(
      state.sidebarState.copyWith(titleOverrides: overrides),
    );
  }

  Future<void> applyWorkspaceAccessMode(String accessMode) async {
    final current = state.activeWorkspaceScope;
    if (current == null) {
      return;
    }
    if (accessMode == 'full' && !state.canUseFullWorkspaceAccess) {
      return;
    }
    final next = current.withAccessMode(accessMode);
    await _applyWorkspaceScope(next);
  }

  Future<void> applyWorkspaceProjectPath(
    String projectPath, {
    String? projectName,
  }) async {
    final base =
        state.activeWorkspaceScope ?? state.workspacesSnapshot?.defaultScope;
    if (base == null) {
      return;
    }
    final trimmed = projectPath.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final next = NanobotWorkspaceScope(
      projectPath: trimmed,
      projectName: projectName ?? _projectNameFromPath(trimmed),
      accessMode: base.accessMode,
      restrictToWorkspace: base.accessMode == 'restricted',
      sandboxStatus: base.sandboxStatus,
    );
    await _applyWorkspaceScope(next);
  }

  Future<void> _applyWorkspaceScope(NanobotWorkspaceScope next) async {
    final chatId = state.selectedChatId;
    state = _stateWithWorkspaceScope(next).copyWith(clearWorkspaceError: true);
    if (chatId == null || chatId.trim().isEmpty) {
      state = state.copyWith(draftWorkspaceScope: next);
      return;
    }
    try {
      await ref
          .read(nanobotRepositoryProvider)
          .setWorkspaceScope(chatId: chatId, workspaceScope: next);
    } on Object catch (error) {
      state = state.copyWith(errorMessage: _friendlyError(error));
    }
  }

  Future<void> deleteSession(String key) async {
    final currentSessions = state.sessions;
    final deletedIndex = currentSessions.indexWhere(
      (session) => session.key == key,
    );
    final deletingActive = state.selectedSessionKey == key;
    try {
      final result = await ref
          .read(nanobotRepositoryProvider)
          .deleteSession(sessionKey: key);
      if (result.blockedByAutomations) {
        state = state.copyWith(
          errorMessage:
              'Delete blocked by ${result.automations.length} automation(s).',
        );
        return;
      }
      if (!result.deleted) {
        state = state.copyWith(errorMessage: 'Delete failed.');
        return;
      }
      final nextSessions = [
        for (final session in state.sessions)
          if (session.key != key) session,
      ];
      state = state.copyWith(sessions: nextSessions, clearError: true);
      if (!deletingActive) {
        return;
      }
      final fallback = _deleteFallbackSession(nextSessions, deletedIndex);
      if (fallback != null) {
        await selectSession(fallback);
      } else {
        state = state.copyWith(
          clearSelectedSession: true,
          clearThreadState: true,
          messages: const [],
          clearReasoning: true,
          clearActivity: true,
        );
      }
    } on Object catch (error) {
      state = state.copyWith(errorMessage: _friendlyError(error));
    }
  }

  Future<void> _updateSidebarState(NanobotSidebarState next) async {
    state = state.copyWith(sidebarState: next, clearError: true);
    try {
      final persisted = await ref
          .read(nanobotRepositoryProvider)
          .updateSidebarState(next);
      state = state.copyWith(sidebarState: persisted, clearError: true);
    } on Object catch (error) {
      state = state.copyWith(errorMessage: _friendlyError(error));
    }
  }

  Future<void> _openCatalog(
    NanobotShellView view,
    Future<List<NanobotCatalogItem>> Function() load,
    NanobotWorkspaceState Function(List<NanobotCatalogItem> items) apply,
  ) async {
    state = state.copyWith(
      activeView: view,
      isLoadingSurface: true,
      clearError: true,
    );
    try {
      final items = await load();
      state = apply(items);
    } on Object catch (error) {
      state = state.copyWith(
        isLoadingSurface: false,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> selectSession(NanobotSessionSummary session) async {
    final generation = ++_loadGeneration;
    state = state.copyWith(
      selectedSessionKey: session.key,
      selectedChatId: session.chatId,
      threadState: NanobotThreadState(
        sessionKey: session.key,
        chatId: session.chatId,
        isStreaming: session.runStartedAt != null,
        runStartedAt: session.runStartedAt,
      ),
      messages: const [],
      isLoadingThread: true,
      isStreaming: session.runStartedAt != null,
      clearReasoning: true,
      clearActivity: true,
      clearError: true,
    );
    try {
      final repository = ref.read(nanobotRepositoryProvider);
      await repository.attach(session.chatId);
      final messages = await repository.fetchThread(session);
      if (!_isActive(generation)) {
        return;
      }
      state = state.copyWith(
        messages: _recentMessages(messages),
        threadState: _threadStateFromMessages(
          sessionKey: session.key,
          chatId: session.chatId,
          messages: _recentMessages(messages),
          isStreaming: session.runStartedAt != null,
          runStartedAt: session.runStartedAt,
        ),
        isLoadingThread: false,
        clearError: true,
      );
    } on Object catch (error) {
      if (!_isActive(generation)) {
        return;
      }
      state = state.copyWith(
        isLoadingThread: false,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> startNewSession() async {
    if (state.isBootstrapping || state.isLoadingThread) {
      return;
    }
    state = state.copyWith(
      isLoadingThread: true,
      clearSelectedSession: true,
      clearThreadState: true,
      messages: const [],
      clearReasoning: true,
      clearActivity: true,
      clearError: true,
    );
    try {
      final chatId = await ref.read(nanobotRepositoryProvider).newChat();
      final session = NanobotSessionSummary(
        key: 'websocket:$chatId',
        channel: 'websocket',
        chatId: chatId,
        preview: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(
        sessions: [session, ...state.sessions],
        selectedSessionKey: session.key,
        selectedChatId: session.chatId,
        threadState: NanobotThreadState(
          sessionKey: session.key,
          chatId: session.chatId,
        ),
        isLoadingThread: false,
        clearError: true,
      );
      unawaited(refreshSessions());
    } on Object catch (error) {
      state = state.copyWith(
        isLoadingThread: false,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> sendMessage(String input) async {
    final content = input.trim();
    if (content.isEmpty || !state.canSend) {
      return;
    }

    var chatId = state.selectedChatId;
    var sessionKey = state.selectedSessionKey;
    if (chatId == null || chatId.trim().isEmpty || sessionKey == null) {
      await startNewSession();
      chatId = state.selectedChatId;
      sessionKey = state.selectedSessionKey;
    }
    if (chatId == null || sessionKey == null) {
      return;
    }

    final userMessage = NanobotMessage(
      id: _newMessageId('user'),
      sessionKey: sessionKey,
      chatId: chatId,
      role: NanobotMessageRole.user,
      content: content,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      threadState: _appendUserThreadEntry(
        state.threadState,
        sessionKey: sessionKey,
        chatId: chatId,
        content: content,
      ),
      isStreaming: true,
      clearReasoning: true,
      clearActivity: true,
      clearError: true,
    );

    try {
      await ref
          .read(nanobotRepositoryProvider)
          .sendMessage(chatId: chatId, content: content);
    } on Object catch (error) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          NanobotMessage(
            id: _newMessageId('error'),
            sessionKey: sessionKey,
            chatId: chatId,
            role: NanobotMessageRole.assistant,
            content: _friendlyError(error),
            createdAt: DateTime.now(),
            status: NanobotMessageStatus.failed,
          ),
        ],
        isStreaming: false,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> stopActiveTurn() async {
    final chatId = state.selectedChatId;
    if (chatId == null) {
      return;
    }
    await ref
        .read(nanobotRepositoryProvider)
        .sendMessage(chatId: chatId, content: '/stop');
    state = state.copyWith(isStreaming: false, clearReasoning: true);
  }

  void _handleEvent(NanobotEvent event) {
    switch (event.kind) {
      case NanobotEventKind.ready:
        state = state.copyWith(
          selectedChatId: state.selectedChatId ?? event.chatId,
          clearError: true,
        );
      case NanobotEventKind.attached:
        if (event.chatId == state.selectedChatId) {
          state = state.copyWith(clearError: true);
        }
      case NanobotEventKind.runtimeModelUpdated:
        state = state.copyWith(modelName: event.modelName);
      case NanobotEventKind.sessionUpdated:
        if (event.workspaceScope != null && event.chatId != null) {
          _applyWorkspaceScopeMap(event.chatId!, event.workspaceScope!);
        }
        unawaited(refreshSessions());
      case NanobotEventKind.reasoningDelta:
      case NanobotEventKind.reasoningEnd:
      case NanobotEventKind.delta:
      case NanobotEventKind.message:
      case NanobotEventKind.streamEnd:
      case NanobotEventKind.goalStatus:
      case NanobotEventKind.fileEdit:
      case NanobotEventKind.turnEnd:
        if (_isSelectedChat(event.chatId)) {
          _applyThreadEvent(event);
          if (event.kind == NanobotEventKind.turnEnd) {
            unawaited(refreshSessions());
          }
        }
      case NanobotEventKind.error:
        if (event.detail == 'workspace_scope_rejected') {
          state = state.copyWith(
            workspaceError:
                'Workspace scope was rejected. Choose another project.',
            errorMessage:
                event.reason ??
                'Workspace scope was rejected. Choose another project.',
          );
          break;
        }
        state = state.copyWith(
          isStreaming: false,
          errorMessage: event.reason ?? event.detail ?? 'nanobot error',
        );
      case NanobotEventKind.transcriptionResult:
      case NanobotEventKind.transcriptionError:
      case NanobotEventKind.goalState:
        if (_isSelectedChat(event.chatId)) {
          _applyThreadEvent(event);
        }
      case NanobotEventKind.unknown:
        break;
    }
  }

  void _applyThreadEvent(NanobotEvent event) {
    final current = _currentThreadState();
    if (current == null) {
      return;
    }
    final next = NanobotThreadReducer.reduce(current, event);
    final reasoningText = _activeReasoningText(next);
    final activityText = _activeActivityText(next);
    state = state.copyWith(
      threadState: next,
      messages: _messagesFromThreadState(next),
      isStreaming: next.isStreaming,
      reasoningText: reasoningText,
      activityText: activityText,
      clearReasoning: reasoningText == null,
      clearActivity: activityText == null,
      clearError: true,
    );
  }

  bool _isSelectedChat(String? chatId) {
    return chatId == null || chatId == state.selectedChatId;
  }

  bool _isActive(int generation) {
    return generation == _loadGeneration;
  }

  List<NanobotMessage> _recentMessages(List<NanobotMessage> messages) {
    const maxInitialMessages = 80;
    if (messages.length <= maxInitialMessages) {
      return messages;
    }
    return messages.sublist(messages.length - maxInitialMessages);
  }

  NanobotWorkspaceState _stateWithWorkspaceScope(NanobotWorkspaceScope scope) {
    final selectedKey = state.selectedSessionKey;
    if (selectedKey == null) {
      return state.copyWith(draftWorkspaceScope: scope);
    }
    return state.copyWith(
      sessions: [
        for (final session in state.sessions)
          if (session.key == selectedKey)
            session.copyWith(workspaceScope: scope)
          else
            session,
      ],
      draftWorkspaceScope: scope,
    );
  }

  void _applyWorkspaceScopeMap(
    String chatId,
    Map<String, Object?> workspaceScope,
  ) {
    final projectPath = workspaceScope['project_path'] as String?;
    if (projectPath == null || projectPath.trim().isEmpty) {
      return;
    }
    final scope = NanobotWorkspaceScope(
      projectPath: projectPath,
      projectName: workspaceScope['project_name'] as String?,
      accessMode: workspaceScope['access_mode'] as String? ?? 'restricted',
      restrictToWorkspace: workspaceScope['restrict_to_workspace'] as bool?,
      sandboxStatus: workspaceScope['sandbox_status'] is Map
          ? Map<String, Object?>.from(workspaceScope['sandbox_status'] as Map)
          : null,
    );
    state = state.copyWith(
      sessions: [
        for (final session in state.sessions)
          if (session.chatId == chatId)
            session.copyWith(workspaceScope: scope)
          else
            session,
      ],
      draftWorkspaceScope: scope,
      clearWorkspaceError: true,
    );
  }

  String _newMessageId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  String _projectNameFromPath(String path) {
    final normalized = path
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'/+$'), '');
    final parts = normalized.split('/').where((part) => part.isNotEmpty);
    return parts.isEmpty ? path : parts.last;
  }

  NanobotThreadState? _currentThreadState() {
    final existing = state.threadState;
    if (existing != null) {
      return existing;
    }
    final sessionKey = state.selectedSessionKey;
    final chatId = state.selectedChatId;
    if (sessionKey == null || chatId == null) {
      return null;
    }
    return _threadStateFromMessages(
      sessionKey: sessionKey,
      chatId: chatId,
      messages: state.messages,
      isStreaming: state.isStreaming,
    );
  }

  NanobotThreadState _threadStateFromMessages({
    required String sessionKey,
    required String chatId,
    required List<NanobotMessage> messages,
    bool isStreaming = false,
    int? runStartedAt,
  }) {
    return NanobotThreadState(
      sessionKey: sessionKey,
      chatId: chatId,
      entries: [
        for (final message in messages)
          NanobotThreadEntry(
            id: message.id,
            role: _threadRoleFromMessage(message.role),
            content: message.content,
            createdAt: message.createdAt,
            isStreaming: message.status == NanobotMessageStatus.streaming,
            reasoning: message.reasoning,
          ),
      ],
      isStreaming: isStreaming,
      runStartedAt: runStartedAt,
    );
  }

  NanobotThreadState _appendUserThreadEntry(
    NanobotThreadState? current, {
    required String sessionKey,
    required String chatId,
    required String content,
  }) {
    final base =
        current ?? NanobotThreadState(sessionKey: sessionKey, chatId: chatId);
    return base.copyWith(
      entries: [
        ...base.entries,
        NanobotThreadEntry(
          id: _newMessageId('user'),
          role: NanobotThreadRole.user,
          content: content,
          createdAt: DateTime.now(),
        ),
      ],
      isStreaming: true,
    );
  }

  List<NanobotMessage> _messagesFromThreadState(NanobotThreadState thread) {
    return [
      for (final entry in thread.entries)
        if (entry.kind == NanobotThreadEntryKind.message &&
            (entry.content.trim().isNotEmpty ||
                entry.reasoning?.trim().isNotEmpty == true))
          NanobotMessage(
            id: entry.id,
            sessionKey: thread.sessionKey,
            chatId: thread.chatId,
            role: _messageRoleFromThread(entry.role),
            content: entry.content,
            createdAt: entry.createdAt,
            status: entry.isStreaming
                ? NanobotMessageStatus.streaming
                : NanobotMessageStatus.completed,
            reasoning: entry.reasoning,
          ),
    ];
  }

  NanobotSessionSummary? _deleteFallbackSession(
    List<NanobotSessionSummary> sessions,
    int deletedIndex,
  ) {
    if (sessions.isEmpty) {
      return null;
    }
    if (deletedIndex < 0) {
      return sessions.first;
    }
    if (deletedIndex < sessions.length) {
      return sessions[deletedIndex];
    }
    return sessions.last;
  }

  String? _activeReasoningText(NanobotThreadState thread) {
    if (!thread.isStreaming) {
      return null;
    }
    for (var i = thread.entries.length - 1; i >= 0; i -= 1) {
      final entry = thread.entries[i];
      if (entry.reasoningStreaming &&
          entry.reasoning?.trim().isNotEmpty == true) {
        return entry.reasoning;
      }
    }
    return null;
  }

  String? _activeActivityText(NanobotThreadState thread) {
    if (!thread.isStreaming || thread.entries.isEmpty) {
      return null;
    }
    final last = thread.entries.last;
    return switch (last.kind) {
      NanobotThreadEntryKind.trace => last.content,
      NanobotThreadEntryKind.fileEdit => last.content,
      NanobotThreadEntryKind.message => null,
    };
  }

  NanobotThreadRole _threadRoleFromMessage(NanobotMessageRole role) {
    return switch (role) {
      NanobotMessageRole.system => NanobotThreadRole.system,
      NanobotMessageRole.user => NanobotThreadRole.user,
      NanobotMessageRole.assistant => NanobotThreadRole.assistant,
      NanobotMessageRole.tool => NanobotThreadRole.tool,
    };
  }

  NanobotMessageRole _messageRoleFromThread(NanobotThreadRole role) {
    return switch (role) {
      NanobotThreadRole.system => NanobotMessageRole.system,
      NanobotThreadRole.user => NanobotMessageRole.user,
      NanobotThreadRole.assistant => NanobotMessageRole.assistant,
      NanobotThreadRole.tool => NanobotMessageRole.tool,
    };
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }
}
