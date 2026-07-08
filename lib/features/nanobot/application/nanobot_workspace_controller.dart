import 'dart:async';

import 'package:agent_client/features/nanobot/application/nanobot_thread_reducer.dart';
import 'package:agent_client/features/nanobot/application/nanobot_workspace_state.dart';
import 'package:agent_client/features/nanobot/data/nanobot_providers.dart';
import 'package:agent_client/features/nanobot/data/nanobot_repository.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_event.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_media_attachment.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_message.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_shell_models.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_thread_page.dart';
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
  var _filePreviewGeneration = 0;
  var _skillDetailGeneration = 0;
  var _voiceRequestCounter = 0;

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
      final slashCommands = await _loadSlashCommands(repository);
      if (!_isActive(generation)) {
        return;
      }
      final skills = await _loadSkillItems(repository);
      if (!_isActive(generation)) {
        return;
      }
      final capabilityMentions = await _loadCapabilityMentions(repository);
      if (!_isActive(generation)) {
        return;
      }
      state = state.copyWith(
        sessions: sessions,
        sidebarState: sidebarState,
        workspacesSnapshot: workspacesSnapshot,
        slashCommands: slashCommands,
        skillItems: skills,
        capabilityMentions: capabilityMentions,
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

  Future<List<NanobotSlashCommand>> _loadSlashCommands(
    NanobotRepositoryPort repository,
  ) async {
    try {
      return await repository.listSlashCommands();
    } on Object {
      return const [];
    }
  }

  Future<List<NanobotCatalogItem>> _loadSkillItems(
    NanobotRepositoryPort repository,
  ) async {
    try {
      return await repository.fetchSkillItems();
    } on Object {
      return const [];
    }
  }

  Future<List<NanobotCapabilityMention>> _loadCapabilityMentions(
    NanobotRepositoryPort repository,
  ) async {
    try {
      return await repository.fetchCapabilityMentions();
    } on Object {
      return const [];
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

  Future<void> runCliAppAction(String action, NanobotCatalogItem item) async {
    state = state.copyWith(clearError: true);
    try {
      final items = await ref
          .read(nanobotRepositoryProvider)
          .runCliAppAction(action: action, name: _appActionName(item));
      state = state.copyWith(
        appItems: _mergeAppItems(state.appItems, items),
        clearError: true,
      );
    } on Object catch (error) {
      state = state.copyWith(errorMessage: _friendlyError(error));
    }
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

  Future<void> runAutomationAction(
    NanobotAutomationAction action,
    NanobotCatalogItem item,
  ) async {
    state = state.copyWith(clearError: true);
    try {
      final items = await ref
          .read(nanobotRepositoryProvider)
          .runAutomationAction(action: action, id: item.id);
      state = state.copyWith(automationItems: items, clearError: true);
    } on Object catch (error) {
      state = state.copyWith(errorMessage: _friendlyError(error));
    }
  }

  Future<void> updateAutomation(
    NanobotCatalogItem item,
    Map<String, Object?> values,
  ) async {
    state = state.copyWith(clearError: true);
    try {
      final items = await ref
          .read(nanobotRepositoryProvider)
          .updateAutomation(id: item.id, values: values);
      state = state.copyWith(automationItems: items, clearError: true);
    } on Object catch (error) {
      state = state.copyWith(errorMessage: _friendlyError(error));
    }
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

  Future<void> openSkillDetail(NanobotCatalogItem item) async {
    final generation = ++_skillDetailGeneration;
    state = state.copyWith(
      selectedSkillItem: item,
      isLoadingSkillDetail: true,
      clearSkillDetail: true,
      clearSkillDetailError: true,
    );
    try {
      final detail = await ref
          .read(nanobotRepositoryProvider)
          .fetchSkillDetail(item.id);
      if (generation != _skillDetailGeneration) {
        return;
      }
      state = state.copyWith(
        selectedSkillDetail: detail,
        isLoadingSkillDetail: false,
        clearSkillDetailError: true,
      );
    } on Object catch (error) {
      if (generation != _skillDetailGeneration) {
        return;
      }
      state = state.copyWith(
        isLoadingSkillDetail: false,
        skillDetailError: _friendlyError(error),
      );
    }
  }

  void closeSkillDetail() {
    _skillDetailGeneration += 1;
    state = state.copyWith(
      isLoadingSkillDetail: false,
      clearSelectedSkill: true,
    );
  }

  Future<void> openFilePreview(String path) async {
    final sessionKey = state.selectedSessionKey;
    final trimmed = path.trim();
    if (sessionKey == null || trimmed.isEmpty) {
      return;
    }
    final generation = ++_filePreviewGeneration;
    state = state.copyWith(
      filePreviewPath: trimmed,
      isLoadingFilePreview: true,
      clearFilePreview: false,
      clearFilePreviewError: true,
    );
    try {
      final preview = await ref
          .read(nanobotRepositoryProvider)
          .fetchFilePreview(sessionKey: sessionKey, path: trimmed);
      if (generation != _filePreviewGeneration) {
        return;
      }
      state = state.copyWith(
        filePreviewPath: trimmed,
        filePreview: preview,
        isLoadingFilePreview: false,
        clearFilePreviewError: true,
      );
    } on Object catch (error) {
      if (generation != _filePreviewGeneration) {
        return;
      }
      state = state.copyWith(
        filePreviewPath: trimmed,
        filePreviewError: _friendlyError(error),
        isLoadingFilePreview: false,
      );
    }
  }

  void closeFilePreview() {
    _filePreviewGeneration += 1;
    state = state.copyWith(isLoadingFilePreview: false, clearFilePreview: true);
  }

  void dismissStreamError() {
    state = state.copyWith(clearStreamError: true);
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
      clearStreamError: true,
    );
    try {
      final repository = ref.read(nanobotRepositoryProvider);
      await repository.attach(session.chatId);
      final threadPage = await repository.fetchThreadPage(session);
      if (!_isActive(generation)) {
        return;
      }
      final threadWindow = _recentThreadWindow(threadPage);
      state = state.copyWith(
        messages: threadWindow.messages,
        threadState: _threadStateFromMessages(
          sessionKey: session.key,
          chatId: session.chatId,
          messages: threadWindow.messages,
          userMessageOffset: threadWindow.userMessageOffset,
          isStreaming: session.runStartedAt != null,
          runStartedAt: session.runStartedAt,
        ),
        isLoadingThread: false,
        clearError: true,
        clearStreamError: true,
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
      clearStreamError: true,
    );
    try {
      final workspaceScope = state.activeWorkspaceScope;
      final chatId = await ref
          .read(nanobotRepositoryProvider)
          .newChat(workspaceScope: workspaceScope);
      final session = NanobotSessionSummary(
        key: 'websocket:$chatId',
        channel: 'websocket',
        chatId: chatId,
        preview: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        workspaceScope: workspaceScope,
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
        clearStreamError: true,
      );
      unawaited(refreshSessions());
    } on Object catch (error) {
      state = state.copyWith(
        isLoadingThread: false,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> forkFromMessage(int beforeUserIndex) async {
    final sourceChatId = state.selectedChatId;
    final sourceSession = state.selectedSession;
    if (sourceChatId == null ||
        sourceChatId.trim().isEmpty ||
        beforeUserIndex < 0) {
      return;
    }
    final workspaceScope = state.activeWorkspaceScope;
    final sourceTitle = sourceSession == null
        ? 'New Chat'
        : state.displayTitleFor(sourceSession);
    final title = 'Fork: $sourceTitle';
    try {
      final forkedChatId = await ref
          .read(nanobotRepositoryProvider)
          .forkChat(
            sourceChatId: sourceChatId,
            beforeUserIndex: beforeUserIndex,
            title: title,
          );
      final session = NanobotSessionSummary(
        key: 'websocket:$forkedChatId',
        channel: 'websocket',
        chatId: forkedChatId,
        title: title,
        preview: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        workspaceScope: workspaceScope,
      );
      state = state.copyWith(
        sessions: [
          session,
          for (final existing in state.sessions)
            if (existing.key != session.key) existing,
        ],
        activeView: NanobotShellView.chat,
        clearError: true,
        clearStreamError: true,
      );
      await selectSession(session);
    } on Object catch (error) {
      state = state.copyWith(errorMessage: _friendlyError(error));
    }
  }

  Future<void> sendMessage(
    String input, {
    List<NanobotSendMedia> media = const [],
  }) async {
    final content = input.trim();
    if ((content.isEmpty && media.isEmpty) || !state.canSend) {
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

    final slashLifecycle = _slashCommandLifecycle(content);
    if (slashLifecycle == 'stop_active_turn' && state.isStreaming) {
      await stopActiveTurn();
      return;
    }
    final sideChannel = _isSlashSideChannel(slashLifecycle);
    final finalizeActiveTurn = slashLifecycle == 'finalize_active_turn';
    final nextStreaming = sideChannel
        ? (finalizeActiveTurn ? false : state.isStreaming)
        : true;
    final messageMedia = [for (final item in media) item.toAttachment()];
    final userMessage = NanobotMessage(
      id: _newMessageId('user'),
      sessionKey: sessionKey,
      chatId: chatId,
      role: NanobotMessageRole.user,
      content: content,
      createdAt: DateTime.now(),
      media: messageMedia,
    );
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      threadState: _appendUserThreadEntry(
        state.threadState,
        sessionKey: sessionKey,
        chatId: chatId,
        content: content,
        isStreaming: nextStreaming,
        media: messageMedia,
      ),
      isStreaming: nextStreaming,
      clearReasoning: !sideChannel || finalizeActiveTurn,
      clearActivity: !sideChannel || finalizeActiveTurn,
      clearError: true,
    );

    try {
      final mentions = _capabilityMentionsForContent(content);
      await ref
          .read(nanobotRepositoryProvider)
          .sendMessage(
            chatId: chatId,
            content: content,
            media: media,
            cliApps: mentions.cliApps,
            mcpPresets: mentions.mcpPresets,
          );
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

  Future<String> transcribeAudio(String dataUrl, {int? durationMs}) async {
    final trimmed = dataUrl.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    _voiceRequestCounter += 1;
    final requestId =
        'flutter-voice-${DateTime.now().microsecondsSinceEpoch}-$_voiceRequestCounter';
    try {
      final text = await ref
          .read(nanobotRepositoryProvider)
          .transcribeAudio(
            requestId: requestId,
            dataUrl: trimmed,
            durationMs: durationMs,
          );
      state = state.copyWith(clearError: true);
      return text;
    } on Object catch (error) {
      final message = _friendlyError(error);
      state = state.copyWith(errorMessage: message);
      rethrow;
    }
  }

  _ResolvedCapabilityMentions _capabilityMentionsForContent(String content) {
    final cliByName = <String, NanobotCapabilityMention>{};
    final mcpByName = <String, NanobotCapabilityMention>{};
    for (final item in state.capabilityMentions) {
      if (!item.canMention) {
        continue;
      }
      final key = item.name.toLowerCase();
      if (item.kind == NanobotCapabilityMentionKind.cli) {
        cliByName[key] = item;
      } else {
        mcpByName[key] = item;
      }
    }
    final cliApps = <NanobotCapabilityMention>[];
    final mcpPresets = <NanobotCapabilityMention>[];
    final seenCli = <String>{};
    final seenMcp = <String>{};
    final mentionRe = RegExp(
      r'(^|[\s([{])@([a-z0-9_-]+)\b',
      caseSensitive: false,
    );
    for (final match in mentionRe.allMatches(content)) {
      final name = match.group(2)?.toLowerCase();
      if (name == null) {
        continue;
      }
      final app = cliByName[name];
      if (app != null) {
        if (seenCli.add(name)) {
          cliApps.add(app);
        }
        continue;
      }
      final preset = mcpByName[name];
      if (preset != null && seenMcp.add(name)) {
        mcpPresets.add(preset);
      }
    }
    return _ResolvedCapabilityMentions(
      cliApps: cliApps,
      mcpPresets: mcpPresets,
    );
  }

  String? _slashCommandLifecycle(String content) {
    final trimmed = content.trim();
    if (!trimmed.startsWith('/')) {
      return null;
    }
    final commandName = trimmed.split(RegExp(r'\s+')).first;
    for (final command in state.slashCommands) {
      if (command.command != commandName) {
        continue;
      }
      final args = trimmed.substring(command.command.length).trim();
      if (args.isNotEmpty && !command.acceptsArgs) {
        return null;
      }
      if (command.lifecycle == 'agent_turn_with_args') {
        return args.isNotEmpty ? 'agent_turn' : 'side_channel';
      }
      return command.lifecycle;
    }
    return null;
  }

  bool _isSlashSideChannel(String? lifecycle) {
    return lifecycle == 'side_channel' ||
        lifecycle == 'finalize_active_turn' ||
        lifecycle == 'stop_active_turn';
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
        if (event.detail == 'message_too_big') {
          state = state.copyWith(
            isStreaming: false,
            streamError: const NanobotStreamError(
              kind: NanobotStreamErrorKind.messageTooBig,
            ),
            clearError: true,
          );
          break;
        }
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

  NanobotThreadPage _recentThreadWindow(NanobotThreadPage page) {
    final messages = _recentMessages(page.messages);
    if (messages.length == page.messages.length) {
      return page;
    }
    final dropped = page.messages.take(page.messages.length - messages.length);
    final droppedUserCount = dropped.where(
      (message) => message.role == NanobotMessageRole.user,
    );
    return NanobotThreadPage(
      messages: messages,
      userMessageOffset: page.userMessageOffset + droppedUserCount.length,
      forkBoundaryMessageCount: page.forkBoundaryMessageCount,
    );
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
    int userMessageOffset = 0,
  }) {
    return NanobotThreadState(
      sessionKey: sessionKey,
      chatId: chatId,
      userMessageOffset: userMessageOffset,
      entries: [
        for (final message in messages)
          NanobotThreadEntry(
            id: message.id,
            role: _threadRoleFromMessage(message.role),
            content: message.content,
            createdAt: message.createdAt,
            isStreaming: message.status == NanobotMessageStatus.streaming,
            reasoning: message.reasoning,
            media: message.media,
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
    required bool isStreaming,
    List<NanobotMediaAttachment> media = const [],
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
          media: media,
        ),
      ],
      isStreaming: isStreaming,
    );
  }

  List<NanobotMessage> _messagesFromThreadState(NanobotThreadState thread) {
    return [
      for (final entry in thread.entries)
        if (entry.kind == NanobotThreadEntryKind.message &&
            (entry.content.trim().isNotEmpty ||
                entry.reasoning?.trim().isNotEmpty == true ||
                entry.media.isNotEmpty))
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
            media: entry.media,
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

  String _appActionName(NanobotCatalogItem item) {
    final separator = item.id.indexOf(':');
    if (separator >= 0 && separator < item.id.length - 1) {
      return item.id.substring(separator + 1);
    }
    return item.id;
  }

  List<NanobotCatalogItem> _mergeAppItems(
    List<NanobotCatalogItem> current,
    List<NanobotCatalogItem> updates,
  ) {
    final updateKinds = {
      for (final item in updates) _appKind(item),
    }..remove('');
    if (updateKinds.isEmpty) {
      return updates;
    }
    final merged = [
      for (final item in current)
        if (!updateKinds.contains(_appKind(item))) item,
      ...updates,
    ];
    merged.sort((left, right) {
      final readyRank =
          (_isReadyApp(right) ? 1 : 0) - (_isReadyApp(left) ? 1 : 0);
      if (readyRank != 0) {
        return readyRank;
      }
      return left.title.toLowerCase().compareTo(right.title.toLowerCase());
    });
    return merged;
  }

  String _appKind(NanobotCatalogItem item) {
    for (final kind in const ['nanobot', 'cli', 'mcp']) {
      if (item.filterKeys.contains(kind) || item.id.startsWith('$kind:')) {
        return kind;
      }
    }
    return '';
  }

  bool _isReadyApp(NanobotCatalogItem item) {
    final status = item.status.toLowerCase();
    return item.filterKeys.contains('ready') ||
        status == 'installed' ||
        status == 'configured';
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }
}

class _ResolvedCapabilityMentions {
  const _ResolvedCapabilityMentions({
    required this.cliApps,
    required this.mcpPresets,
  });

  final List<NanobotCapabilityMention> cliApps;
  final List<NanobotCapabilityMention> mcpPresets;
}
