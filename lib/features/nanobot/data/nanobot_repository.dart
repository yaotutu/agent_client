import 'package:agent_client/features/nanobot/data/nanobot_api_client.dart';
import 'package:agent_client/features/nanobot/data/protocol/nanobot_http_dto.dart';
import 'package:agent_client/features/nanobot/data/protocol/nanobot_ws_envelope.dart';
import 'package:agent_client/features/nanobot/data/nanobot_ws_client.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_bootstrap.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_event.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_message.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_shell_models.dart';

abstract class NanobotRepositoryPort {
  Stream<NanobotEvent> get events;

  Stream<NanobotSocketStatus> get status;

  NanobotSocketStatus get currentStatus;

  Future<NanobotBootstrap> bootstrap({bool forceRefresh = false});

  Future<void> connect();

  Future<List<NanobotSessionSummary>> listSessions();

  Future<List<NanobotMessage>> fetchThread(NanobotSessionSummary session);

  Future<String> newChat();

  Future<void> attach(String chatId);

  Future<void> sendMessage({required String chatId, required String content});

  Future<NanobotSidebarState> fetchSidebarState() {
    throw UnimplementedError('fetchSidebarState');
  }

  Future<NanobotSidebarState> updateSidebarState(NanobotSidebarState state) {
    throw UnimplementedError('updateSidebarState');
  }

  Future<NanobotSettingsSnapshot> fetchSettingsSnapshot() {
    throw UnimplementedError('fetchSettingsSnapshot');
  }

  Future<List<NanobotCatalogItem>> fetchAppItems() {
    throw UnimplementedError('fetchAppItems');
  }

  Future<List<NanobotCatalogItem>> fetchAutomationItems() {
    throw UnimplementedError('fetchAutomationItems');
  }

  Future<List<NanobotCatalogItem>> fetchSkillItems() {
    throw UnimplementedError('fetchSkillItems');
  }

  Future<void> dispose();
}

class NanobotRepository implements NanobotRepositoryPort {
  const NanobotRepository({required this.api, required this.ws});

  final NanobotApiClient api;
  final NanobotWsClient ws;

  @override
  Stream<NanobotEvent> get events => ws.events;

  @override
  Stream<NanobotSocketStatus> get status => ws.status;

  @override
  NanobotSocketStatus get currentStatus => ws.currentStatus;

  @override
  Future<NanobotBootstrap> bootstrap({bool forceRefresh = false}) {
    return api.bootstrap(forceRefresh: forceRefresh);
  }

  @override
  Future<void> connect() => ws.connect();

  @override
  Future<List<NanobotSessionSummary>> listSessions() => api.listSessions();

  @override
  Future<List<NanobotMessage>> fetchThread(NanobotSessionSummary session) {
    return api.fetchWebuiThread(
      sessionKey: session.key,
      chatId: session.chatId,
    );
  }

  Future<NanobotWebuiThreadDto> fetchThreadPage({
    required String sessionKey,
    int limit = 120,
    String? before,
  }) {
    return api.fetchWebuiThreadPage(
      sessionKey: sessionKey,
      limit: limit,
      before: before,
    );
  }

  Future<NanobotFilePreviewDto> fetchFilePreview({
    required String sessionKey,
    required String path,
  }) {
    return api.fetchFilePreview(sessionKey: sessionKey, path: path);
  }

  Future<NanobotWorkspacesDto> fetchWorkspaces() => api.fetchWorkspaces();

  Future<List<NanobotSlashCommandDto>> listSlashCommands() {
    return api.listSlashCommands();
  }

  @override
  Future<NanobotSidebarState> fetchSidebarState() async {
    return _sidebarStateFromDto(await api.fetchSidebarState());
  }

  @override
  Future<NanobotSidebarState> updateSidebarState(
    NanobotSidebarState state,
  ) async {
    return _sidebarStateFromDto(
      await api.updateSidebarState(_sidebarStateToDto(state)),
    );
  }

  @override
  Future<NanobotSettingsSnapshot> fetchSettingsSnapshot() async {
    final settings = await api.fetchSettings();
    final usage = settings.usage;
    return NanobotSettingsSnapshot(
      model: settings.agent['model'] as String?,
      provider: settings.agent['provider'] as String?,
      totalTokens: usage?.totalTokens ?? 0,
      requiresRestart: settings.requiresRestart,
      version: settings.version?['current'] as String?,
    );
  }

  @override
  Future<List<NanobotCatalogItem>> fetchAppItems() async {
    final payload = await api.fetchCliApps();
    return [
      for (final row in payload.apps)
        NanobotCatalogItem(
          id: _stringValue(row, 'name'),
          title: _stringValue(row, 'display_name', fallbackKey: 'name'),
          subtitle: _stringValue(row, 'description', fallbackKey: 'category'),
          status: _stringValue(row, 'status'),
        ),
    ];
  }

  @override
  Future<List<NanobotCatalogItem>> fetchAutomationItems() async {
    final payload = await api.fetchAutomations();
    return [
      for (final row in payload.jobs)
        NanobotCatalogItem(
          id: _stringValue(row, 'id'),
          title: _stringValue(row, 'name', fallbackKey: 'id'),
          subtitle: _automationSubtitle(row),
          status: row['enabled'] == false ? 'disabled' : 'enabled',
        ),
    ];
  }

  @override
  Future<List<NanobotCatalogItem>> fetchSkillItems() async {
    final payload = await api.fetchSkills();
    return [
      for (final row in payload.skills)
        NanobotCatalogItem(
          id: _stringValue(row, 'name'),
          title: _stringValue(row, 'name'),
          subtitle: _stringValue(row, 'description', fallbackKey: 'source'),
          status: row['available'] == false ? 'unavailable' : 'available',
        ),
    ];
  }

  @override
  Future<String> newChat() => ws.newChat();

  @override
  Future<void> attach(String chatId) => ws.attach(chatId);

  @override
  Future<void> sendMessage({required String chatId, required String content}) {
    return ws.sendMessage(chatId: chatId, content: content);
  }

  Future<String> forkChat({
    required String sourceChatId,
    required int beforeUserIndex,
    String? title,
  }) {
    return ws.forkChat(
      sourceChatId: sourceChatId,
      beforeUserIndex: beforeUserIndex,
      title: title,
    );
  }

  Future<void> setWorkspaceScope({
    required String chatId,
    required Map<String, Object?> workspaceScope,
  }) {
    return ws.setWorkspaceScope(chatId: chatId, workspaceScope: workspaceScope);
  }

  Future<String> transcribeAudio({
    required String requestId,
    required String dataUrl,
    int? durationMs,
  }) {
    return ws.transcribeAudio(
      requestId: requestId,
      dataUrl: dataUrl,
      durationMs: durationMs,
    );
  }

  Future<void> sendRichMessage({
    required String chatId,
    required String content,
    List<NanobotOutboundMedia> media = const [],
    NanobotOutboundImageGeneration? imageGeneration,
    List<NanobotOutboundMention> cliApps = const [],
    List<NanobotOutboundMention> mcpPresets = const [],
    Map<String, Object?>? workspaceScope,
    String? turnId,
  }) {
    return ws.sendMessage(
      chatId: chatId,
      content: content,
      media: media,
      imageGeneration: imageGeneration,
      cliApps: cliApps,
      mcpPresets: mcpPresets,
      workspaceScope: workspaceScope,
      turnId: turnId,
    );
  }

  @override
  Future<void> dispose() => ws.dispose();

  String _stringValue(
    Map<String, Object?> row,
    String key, {
    String? fallbackKey,
  }) {
    final value = row[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    final fallbackValue = fallbackKey == null ? null : row[fallbackKey];
    if (fallbackValue is String && fallbackValue.trim().isNotEmpty) {
      return fallbackValue;
    }
    return '';
  }

  String _automationSubtitle(Map<String, Object?> row) {
    final schedule = row['schedule'];
    if (schedule is Map) {
      final kind = schedule['kind'];
      if (kind is String && kind.trim().isNotEmpty) {
        return kind;
      }
    }
    return _stringValue(row, 'kind');
  }

  NanobotSidebarState _sidebarStateFromDto(NanobotSidebarStateDto dto) {
    return NanobotSidebarState(
      pinnedKeys: dto.pinnedKeys,
      archivedKeys: dto.archivedKeys,
      titleOverrides: dto.titleOverrides,
      projectNameOverrides: dto.projectNameOverrides,
      collapsedGroups: dto.collapsedGroups,
      showArchived: dto.view.showArchived,
      sort: dto.view.sort,
      density: dto.view.density,
    );
  }

  NanobotSidebarStateDto _sidebarStateToDto(NanobotSidebarState state) {
    return NanobotSidebarStateDto(
      pinnedKeys: state.pinnedKeys,
      archivedKeys: state.archivedKeys,
      titleOverrides: state.titleOverrides,
      projectNameOverrides: state.projectNameOverrides,
      collapsedGroups: state.collapsedGroups,
      view: NanobotSidebarViewDto(
        density: state.density,
        sort: state.sort,
        showArchived: state.showArchived,
      ),
    );
  }
}
