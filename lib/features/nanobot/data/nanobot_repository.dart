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

  Future<NanobotFilePreview> fetchFilePreview({
    required String sessionKey,
    required String path,
  }) {
    throw UnimplementedError('fetchFilePreview');
  }

  Future<List<NanobotSlashCommand>> listSlashCommands() {
    throw UnimplementedError('listSlashCommands');
  }

  Future<String> newChat({NanobotWorkspaceScope? workspaceScope});

  Future<void> attach(String chatId);

  Future<void> sendMessage({
    required String chatId,
    required String content,
    List<NanobotCapabilityMention> cliApps = const [],
    List<NanobotCapabilityMention> mcpPresets = const [],
  });

  Future<NanobotSidebarState> fetchSidebarState() {
    throw UnimplementedError('fetchSidebarState');
  }

  Future<NanobotSidebarState> updateSidebarState(NanobotSidebarState state) {
    throw UnimplementedError('updateSidebarState');
  }

  Future<NanobotSessionDeleteResult> deleteSession({
    required String sessionKey,
    bool deleteAutomations = false,
  }) {
    throw UnimplementedError('deleteSession');
  }

  Future<NanobotWorkspaceSnapshot> fetchWorkspacesSnapshot() {
    throw UnimplementedError('fetchWorkspacesSnapshot');
  }

  Future<void> setWorkspaceScope({
    required String chatId,
    required NanobotWorkspaceScope workspaceScope,
  }) {
    throw UnimplementedError('setWorkspaceScope');
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

  Future<List<NanobotCapabilityMention>> fetchCapabilityMentions() {
    throw UnimplementedError('fetchCapabilityMentions');
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

  @override
  Future<NanobotFilePreview> fetchFilePreview({
    required String sessionKey,
    required String path,
  }) async {
    final dto = await api.fetchFilePreview(sessionKey: sessionKey, path: path);
    return NanobotFilePreview(
      path: dto.path,
      displayPath: dto.displayPath,
      projectPath: dto.projectPath,
      language: dto.language,
      content: dto.content,
      size: dto.size,
      truncated: dto.truncated,
    );
  }

  Future<NanobotWorkspacesDto> fetchWorkspaces() => api.fetchWorkspaces();

  @override
  Future<NanobotWorkspaceSnapshot> fetchWorkspacesSnapshot() async {
    final dto = await api.fetchWorkspaces();
    return NanobotWorkspaceSnapshot(
      defaultScope: _workspaceScopeFromDto(dto.defaultScope),
      controls: dto.controls,
      recent: [for (final scope in dto.recent) _workspaceScopeFromDto(scope)],
    );
  }

  @override
  Future<List<NanobotSlashCommand>> listSlashCommands() async {
    final commands = await api.listSlashCommands();
    return [
      for (final command in commands)
        NanobotSlashCommand(
          command: command.command,
          title: command.title,
          description: command.description,
          icon: command.icon,
          argHint: command.argHint,
          lifecycle: command.lifecycle,
          acceptsArgs: command.acceptsArgs,
        ),
    ];
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
  Future<NanobotSessionDeleteResult> deleteSession({
    required String sessionKey,
    bool deleteAutomations = false,
  }) async {
    final dto = await api.deleteSession(
      sessionKey: sessionKey,
      deleteAutomations: deleteAutomations,
    );
    return NanobotSessionDeleteResult(
      deleted: dto.deleted,
      blockedByAutomations: dto.blockedByAutomations,
      automations: dto.automations,
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
  Future<List<NanobotCapabilityMention>> fetchCapabilityMentions() async {
    final apps = await api.fetchCliApps();
    final mcpPresets = await api.fetchMcpPresets();
    return [
      for (final row in apps.apps)
        NanobotCapabilityMention(
          kind: NanobotCapabilityMentionKind.cli,
          name: _stringValue(row, 'name'),
          displayName: _stringValue(row, 'display_name', fallbackKey: 'name'),
          category: _stringValue(row, 'category'),
          description: _stringValue(row, 'description'),
          entryPoint: _nullableStringValue(row, 'entry_point'),
          installed: row['installed'] == true,
          configured: row['configured'] == true,
          status: _stringValue(row, 'status'),
          logoUrl: _nullableStringValue(row, 'logo_url'),
          brandColor: _nullableStringValue(row, 'brand_color'),
        ),
      for (final row in mcpPresets.presets)
        NanobotCapabilityMention(
          kind: NanobotCapabilityMentionKind.mcp,
          name: _stringValue(row, 'name'),
          displayName: _stringValue(row, 'display_name', fallbackKey: 'name'),
          category: _stringValue(row, 'category'),
          description: _stringValue(row, 'description'),
          transport: _nullableStringValue(row, 'transport'),
          installed: row['installed'] == true,
          configured: row['configured'] == true,
          status: _stringValue(row, 'status'),
          logoUrl: _nullableStringValue(row, 'logo_url'),
          brandColor: _nullableStringValue(row, 'brand_color'),
        ),
    ];
  }

  @override
  Future<String> newChat({NanobotWorkspaceScope? workspaceScope}) {
    return ws.newChat(workspaceScope: workspaceScope?.toJson());
  }

  @override
  Future<void> attach(String chatId) => ws.attach(chatId);

  @override
  Future<void> sendMessage({
    required String chatId,
    required String content,
    List<NanobotCapabilityMention> cliApps = const [],
    List<NanobotCapabilityMention> mcpPresets = const [],
  }) {
    return ws.sendMessage(
      chatId: chatId,
      content: content,
      cliApps: [for (final item in cliApps) _outboundMention(item)],
      mcpPresets: [for (final item in mcpPresets) _outboundMention(item)],
    );
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

  @override
  Future<void> setWorkspaceScope({
    required String chatId,
    required NanobotWorkspaceScope workspaceScope,
  }) {
    return ws.setWorkspaceScope(
      chatId: chatId,
      workspaceScope: workspaceScope.toJson(),
    );
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

  String? _nullableStringValue(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }

  NanobotOutboundMention _outboundMention(NanobotCapabilityMention item) {
    return NanobotOutboundMention(
      name: item.name,
      displayName: item.displayName,
      category: item.category,
      entryPoint: item.entryPoint,
      transport: item.transport,
      status: item.status,
      configured: item.kind == NanobotCapabilityMentionKind.mcp
          ? item.configured
          : null,
      logoUrl: item.logoUrl,
      brandColor: item.brandColor,
    );
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

  NanobotWorkspaceScope _workspaceScopeFromDto(NanobotWorkspaceScopeDto dto) {
    return NanobotWorkspaceScope(
      projectPath: dto.projectPath,
      projectName: dto.projectName,
      accessMode: dto.accessMode,
      restrictToWorkspace: dto.restrictToWorkspace,
      sandboxStatus: dto.sandboxStatus,
    );
  }
}
