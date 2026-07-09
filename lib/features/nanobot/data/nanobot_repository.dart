import 'package:agent_client/features/nanobot/data/nanobot_api_client.dart';
import 'package:agent_client/features/nanobot/data/protocol/nanobot_http_dto.dart';
import 'package:agent_client/features/nanobot/data/protocol/nanobot_ws_envelope.dart';
import 'package:agent_client/features/nanobot/data/nanobot_ws_client.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_bootstrap.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_event.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_media_attachment.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_message.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_shell_models.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_thread_page.dart';
import 'package:dio/dio.dart';

abstract class NanobotRepositoryPort {
  Stream<NanobotEvent> get events;

  Stream<NanobotSocketStatus> get status;

  NanobotSocketStatus get currentStatus;

  Future<NanobotBootstrap> bootstrap({bool forceRefresh = false});

  Future<void> connect();

  Future<List<NanobotSessionSummary>> listSessions();

  Future<List<NanobotMessage>> fetchThread(NanobotSessionSummary session);

  Future<NanobotThreadPage> fetchThreadPage(
    NanobotSessionSummary session, {
    int limit = 120,
    String? before,
  });

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
    List<NanobotSendMedia> media = const [],
    List<NanobotCapabilityMention> cliApps = const [],
    List<NanobotCapabilityMention> mcpPresets = const [],
  });

  Future<String> transcribeAudio({
    required String requestId,
    required String dataUrl,
    int? durationMs,
  }) {
    throw UnimplementedError('transcribeAudio');
  }

  Future<String> forkChat({
    required String sourceChatId,
    required int beforeUserIndex,
    String? title,
  }) {
    throw UnimplementedError('forkChat');
  }

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

  Future<List<NanobotCatalogItem>> runCliAppAction({
    required String action,
    required String name,
  }) {
    throw UnimplementedError('runCliAppAction');
  }

  Future<List<NanobotCatalogItem>> runNanobotFeatureAction({
    required String action,
    required String name,
  }) {
    throw UnimplementedError('runNanobotFeatureAction');
  }

  Future<List<NanobotCatalogItem>> runMcpPresetAction({
    required String action,
    required String name,
    Map<String, Object?> values = const {},
  }) {
    throw UnimplementedError('runMcpPresetAction');
  }

  Future<List<NanobotCatalogItem>> updateMcpServerTools({
    required String name,
    required List<String> enabledTools,
  }) {
    throw UnimplementedError('updateMcpServerTools');
  }

  Future<List<NanobotCatalogItem>> fetchAutomationItems() {
    throw UnimplementedError('fetchAutomationItems');
  }

  Future<List<NanobotCatalogItem>> runAutomationAction({
    required NanobotAutomationAction action,
    required String id,
  }) {
    throw UnimplementedError('runAutomationAction');
  }

  Future<List<NanobotCatalogItem>> updateAutomation({
    required String id,
    required Map<String, Object?> values,
  }) {
    throw UnimplementedError('updateAutomation');
  }

  Future<List<NanobotCatalogItem>> fetchSkillItems() {
    throw UnimplementedError('fetchSkillItems');
  }

  Future<NanobotSkillDetail> fetchSkillDetail(String name) {
    throw UnimplementedError('fetchSkillDetail');
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
    return fetchThreadPage(session).then((page) => page.messages);
  }

  @override
  Future<NanobotThreadPage> fetchThreadPage(
    NanobotSessionSummary session, {
    int limit = 120,
    String? before,
  }) async {
    final dto = await api.fetchWebuiThreadPage(
      sessionKey: session.key,
      limit: limit,
      before: before,
    );
    return NanobotThreadPage(
      messages: [
        for (final row in dto.messages)
          NanobotMessage.fromWebuiJson(
            json: row,
            sessionKey: session.key,
            chatId: session.chatId,
          ),
      ],
      userMessageOffset: dto.page?.userMessageOffset ?? 0,
      forkBoundaryMessageCount: dto.forkBoundaryMessageCount,
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
    final results = await Future.wait([
      _optionalCatalog(api.fetchNanobotFeatures, const NanobotFeaturesDto()),
      _optionalCatalog(api.fetchCliApps, const NanobotCliAppsDto()),
      _optionalCatalog(api.fetchMcpPresets, const NanobotMcpPresetsDto()),
    ]);
    final features = results[0] as NanobotFeaturesDto;
    final cliApps = results[1] as NanobotCliAppsDto;
    final mcpPresets = results[2] as NanobotMcpPresetsDto;
    final items = [
      for (final row in features.features) _featureCatalogItem(row),
      for (final row in cliApps.apps) _cliCatalogItem(row),
      for (final row in mcpPresets.presets) _mcpCatalogItem(row),
    ];
    items.sort((left, right) {
      final readyRank =
          (right.filterKeys.contains('ready') ? 1 : 0) -
          (left.filterKeys.contains('ready') ? 1 : 0);
      if (readyRank != 0) {
        return readyRank;
      }
      return left.title.toLowerCase().compareTo(right.title.toLowerCase());
    });
    return items;
  }

  Future<T> _optionalCatalog<T>(Future<T> Function() load, T fallback) async {
    try {
      return await load();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return fallback;
      }
      rethrow;
    }
  }

  NanobotCatalogItem _featureCatalogItem(Map<String, Object?> row) {
    final name = _stringValue(row, 'name');
    final type = _stringFrom(row['type']) ?? 'feature';
    final enabled = row['enabled'] == true;
    final installSupported = row['install_supported'] == true;
    return NanobotCatalogItem(
      id: 'nanobot:$name',
      title: _stringValue(row, 'display_name', fallbackKey: 'name'),
      subtitle: _featureStatusLabel(row),
      status: type == 'channel' ? 'Channel' : 'Feature',
      filterKeys: [
        'nanobot',
        type == 'channel' ? 'channel' : 'feature',
        enabled ? 'ready' : 'unavailable',
        if (installSupported) 'install_supported',
      ],
    );
  }

  NanobotCatalogItem _cliCatalogItem(Map<String, Object?> row) {
    final name = _stringValue(row, 'name');
    final installed = row['installed'] == true;
    final installSupported = row['install_supported'] == true;
    return NanobotCatalogItem(
      id: 'cli:$name',
      title: _stringValue(row, 'display_name', fallbackKey: 'name'),
      subtitle: _firstString(row, const [
        'description',
        'requires',
        'entry_point',
        'name',
      ]),
      status: 'CLI',
      filterKeys: [
        'cli',
        installed ? 'ready' : 'unavailable',
        if (installSupported) 'install_supported',
      ],
    );
  }

  NanobotCatalogItem _mcpCatalogItem(Map<String, Object?> row) {
    final name = _stringValue(row, 'name');
    final installed = row['installed'] == true;
    final configured = row['configured'] == true;
    final installSupported = row['install_supported'] == true;
    return NanobotCatalogItem(
      id: 'mcp:$name',
      title: _stringValue(row, 'display_name', fallbackKey: 'name'),
      subtitle: _firstString(row, const [
        'description',
        'requires',
        'note',
        'name',
      ]),
      status: _mcpStatusLabel(_stringFrom(row['status']) ?? ''),
      filterKeys: [
        'mcp',
        installed && configured ? 'ready' : 'unavailable',
        if (installSupported) 'install_supported',
      ],
      mcpRequiredFields: _mcpRequiredFields(row['required_fields']),
      mcpToolNames: _stringList(row['tool_names']),
      mcpEnabledTools: _stringList(row['enabled_tools']),
    );
  }

  List<NanobotMcpRequiredField> _mcpRequiredFields(Object? value) {
    final fields = value is List ? value : const [];
    return [
      for (final item in fields)
        if (item is Map)
          _mcpRequiredField(Map<String, Object?>.from(item)),
    ];
  }

  NanobotMcpRequiredField _mcpRequiredField(Map<String, Object?> row) {
    final name = _stringValue(row, 'name');
    return NanobotMcpRequiredField(
      name: name,
      label: _stringValue(row, 'label', fallbackKey: 'name'),
      placeholder: _stringFrom(row['placeholder']) ?? '',
      secret: row['secret'] == true,
      required: row['required'] == true,
      configured: row['configured'] == true,
    );
  }

  List<String> _stringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return [
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item,
    ];
  }

  @override
  Future<List<NanobotCatalogItem>> runCliAppAction({
    required String action,
    required String name,
  }) async {
    final payload = await api.runCliAppAction(action: action, name: name);
    return [for (final row in payload.apps) _cliCatalogItem(row)];
  }

  @override
  Future<List<NanobotCatalogItem>> runNanobotFeatureAction({
    required String action,
    required String name,
  }) async {
    final payload = await api.runNanobotFeatureAction(
      action: action,
      name: name,
    );
    return [for (final row in payload.features) _featureCatalogItem(row)];
  }

  @override
  Future<List<NanobotCatalogItem>> runMcpPresetAction({
    required String action,
    required String name,
    Map<String, Object?> values = const {},
  }) async {
    final payload = await api.runMcpPresetAction(
      action: action,
      name: name,
      values: values,
    );
    return [for (final row in payload.presets) _mcpCatalogItem(row)];
  }

  @override
  Future<List<NanobotCatalogItem>> updateMcpServerTools({
    required String name,
    required List<String> enabledTools,
  }) async {
    final payload = await api.updateMcpServerTools(
      name: name,
      enabledTools: enabledTools,
    );
    return [for (final row in payload.presets) _mcpCatalogItem(row)];
  }

  @override
  Future<List<NanobotCatalogItem>> fetchAutomationItems() async {
    final payload = await api.fetchAutomations();
    return _automationItemsFromPayload(payload);
  }

  @override
  Future<List<NanobotCatalogItem>> runAutomationAction({
    required NanobotAutomationAction action,
    required String id,
  }) async {
    final payload = await api.runAutomationAction(
      action: action.wireName,
      id: id,
    );
    return _automationItemsFromPayload(payload);
  }

  @override
  Future<List<NanobotCatalogItem>> updateAutomation({
    required String id,
    required Map<String, Object?> values,
  }) async {
    final payload = await api.updateAutomation(id: id, values: values);
    return _automationItemsFromPayload(payload);
  }

  List<NanobotCatalogItem> _automationItemsFromPayload(
    NanobotAutomationsDto payload,
  ) {
    return [for (final row in payload.jobs) _automationItemFromRow(row)];
  }

  NanobotCatalogItem _automationItemFromRow(Map<String, Object?> row) {
    final state = _mapValue(row['state']);
    final origin = _mapValue(row['origin']);
    final schedule = _mapValue(row['schedule']);
    return NanobotCatalogItem(
      id: _stringValue(row, 'id'),
      title: _stringValue(row, 'name', fallbackKey: 'id'),
      subtitle: _automationSubtitle(row),
      details: _automationDetails(row),
      status: _automationStatusLabel(row),
      filterKeys: _automationFilterKeys(row),
      nextRunAtMs: _intValue(state?['next_run_at_ms']),
      lastRunAtMs: _intValue(state?['last_run_at_ms']),
      createdAtMs: _intValue(row['created_at_ms']),
      updatedAtMs: _intValue(row['updated_at_ms']),
      scheduleLabel: _automationScheduleLabel(row),
      originLabel: _automationDetails(row),
      originSessionKey: _stringFrom(origin?['session_key']),
      lastError: _stringFrom(state?['last_error']),
      isPending: state?['pending'] == true,
      isProtected: row['protected'] == true,
      deleteAfterRun: row['delete_after_run'] == true,
      automationScheduleKind: _stringFrom(schedule?['kind']),
      automationEveryMs: _intValue(schedule?['every_ms']),
      automationCronExpr: _stringFrom(schedule?['expr']),
      automationTz: _stringFrom(schedule?['tz']),
      automationAtMs: _intValue(schedule?['at_ms']),
      isLocalTriggerAutomation: _isLocalTriggerAutomation(row),
    );
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
          status: _skillStatus(row),
        ),
    ];
  }

  @override
  Future<NanobotSkillDetail> fetchSkillDetail(String name) async {
    final dto = await api.fetchSkillDetail(name);
    final requirements = dto.requirements ?? const <String, Object?>{};
    return NanobotSkillDetail(
      name: dto.name,
      description: dto.description,
      source: dto.source,
      available: dto.available,
      unavailableReason: dto.unavailableReason,
      bins: _stringListValue(requirements, 'bins'),
      missingBins: _stringListValue(requirements, 'missing_bins'),
      env: _stringListValue(requirements, 'env'),
      missingEnv: _stringListValue(requirements, 'missing_env'),
      rawMarkdown: dto.rawMarkdown,
    );
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
    List<NanobotSendMedia> media = const [],
    List<NanobotCapabilityMention> cliApps = const [],
    List<NanobotCapabilityMention> mcpPresets = const [],
  }) {
    return ws.sendMessage(
      chatId: chatId,
      content: content,
      media: [
        for (final item in media)
          NanobotOutboundMedia(dataUrl: item.dataUrl, name: item.name),
      ],
      cliApps: [for (final item in cliApps) _outboundMention(item)],
      mcpPresets: [for (final item in mcpPresets) _outboundMention(item)],
    );
  }

  @override
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

  @override
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
    return _stringFrom(value);
  }

  String? _stringFrom(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  String _firstString(Map<String, Object?> row, List<String> keys) {
    for (final key in keys) {
      final value = _stringFrom(row[key]);
      if (value != null) {
        return value;
      }
    }
    return '';
  }

  String _featureStatusLabel(Map<String, Object?> row) {
    final ready = row['ready'] == true;
    final installed = row['installed'] == true;
    final type = _stringFrom(row['type']);
    final name = _stringFrom(row['name']);
    if (ready && type == 'channel' && name == 'websocket') {
      return 'Required for WebUI';
    }
    if (ready) {
      return 'Ready';
    }
    if (!installed) {
      return 'Support missing';
    }
    if (type == 'channel') {
      return 'Channel is disabled';
    }
    return 'Not enabled';
  }

  String _mcpStatusLabel(String status) {
    return switch (status) {
      'configured' => 'Configured',
      'missing_credentials' => 'Needs key',
      'missing_dependency' => 'Needs dependency',
      'coming_soon' => 'Coming soon',
      _ => 'Not enabled',
    };
  }

  Map<String, Object?>? _mapValue(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      return Map<String, Object?>.from(value);
    }
    return null;
  }

  List<String> _stringListValue(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is! List) {
      return const [];
    }
    return [
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item,
    ];
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
    final payload = row['payload'];
    if (payload is Map) {
      final message = payload['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    final schedule = row['schedule'];
    if (schedule is Map) {
      final kind = schedule['kind'];
      if (kind is String && kind.trim().isNotEmpty) {
        return kind;
      }
    }
    return _stringValue(row, 'kind');
  }

  String _automationDetails(Map<String, Object?> row) {
    final origin = row['origin'];
    if (origin is! Map) {
      return '';
    }
    final title = origin['title'];
    if (title is String && title.trim().isNotEmpty) {
      return title;
    }
    final channel = origin['channel'];
    if (channel == 'weixin') {
      return 'WeChat';
    }
    if (channel is String && channel.trim().isNotEmpty) {
      return channel;
    }
    return '';
  }

  String _automationScheduleLabel(Map<String, Object?> row) {
    final schedule = _mapValue(row['schedule']);
    if (schedule == null) {
      return 'Custom schedule';
    }
    final kind = _stringFrom(schedule['kind']);
    final label = switch (kind) {
      'at' => _formatAtSchedule(schedule),
      'every' => _formatEverySchedule(schedule),
      'cron' => _formatCronSchedule(schedule),
      'local' => 'Local trigger',
      _ => 'Custom schedule',
    };
    final tz = _stringFrom(schedule['tz']);
    if (tz == null || tz.isEmpty || kind != 'cron') {
      return label;
    }
    return '$label · $tz';
  }

  String _formatAtSchedule(Map<String, Object?> schedule) {
    final atMs = _intValue(schedule['at_ms']);
    if (atMs == null) {
      return 'One-time';
    }
    return 'At ${DateTime.fromMillisecondsSinceEpoch(atMs).toLocal()}';
  }

  String _formatEverySchedule(Map<String, Object?> schedule) {
    final everyMs = _intValue(schedule['every_ms']);
    if (everyMs == null || everyMs <= 0) {
      return 'Interval';
    }
    final seconds = everyMs ~/ 1000;
    if (seconds % 86400 == 0) {
      final days = seconds ~/ 86400;
      return 'Every $days ${days == 1 ? 'day' : 'days'}';
    }
    if (seconds % 3600 == 0) {
      final hours = seconds ~/ 3600;
      return 'Every $hours ${hours == 1 ? 'hour' : 'hours'}';
    }
    if (seconds % 60 == 0) {
      final minutes = seconds ~/ 60;
      return 'Every $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    }
    return 'Every $seconds ${seconds == 1 ? 'second' : 'seconds'}';
  }

  String _formatCronSchedule(Map<String, Object?> schedule) {
    final expr = _stringFrom(schedule['expr']);
    if (expr == null) {
      return 'Cron';
    }
    final summary = _formatCronScheduleSummary(expr);
    if (summary != null) {
      return summary;
    }
    return 'Cron $expr';
  }

  String? _formatCronScheduleSummary(String expr) {
    final parts = expr.trim().split(RegExp(r'\s+'));
    if (parts.length != 5) {
      return null;
    }
    final minute = parts[0];
    final hour = parts[1];
    final dayOfMonth = parts[2];
    final month = parts[3];
    final dayOfWeek = parts[4];
    final numericMinute = _cronNumericToken(minute, 59);
    final numericHour = _cronNumericToken(hour, 23);
    final everyDay = dayOfMonth == '*' && month == '*' && dayOfWeek == '*';
    final workdays =
        dayOfMonth == '*' &&
        month == '*' &&
        const ['1-5', 'MON-FRI', 'mon-fri'].contains(dayOfWeek);

    if (numericMinute != null && numericHour != null) {
      final time =
          '${numericHour.toString().padLeft(2, '0')}:'
          '${numericMinute.toString().padLeft(2, '0')}';
      if (everyDay) {
        return 'Daily at $time';
      }
      if (workdays) {
        return 'Weekdays at $time';
      }
    }

    if (everyDay && numericMinute != null && hour == '*') {
      return 'Hourly at :${numericMinute.toString().padLeft(2, '0')}';
    }

    final range = RegExp(r'^(\d{1,2})-(\d{1,2})$').firstMatch(hour);
    if (everyDay && numericMinute != null && range != null) {
      final start = int.parse(range.group(1)!);
      final end = int.parse(range.group(2)!);
      if (start > 23 || end > 23) {
        return null;
      }
      return 'Hourly ${start.toString().padLeft(2, '0')}-'
          '${end.toString().padLeft(2, '0')} at :'
          '${numericMinute.toString().padLeft(2, '0')}';
    }

    return null;
  }

  int? _cronNumericToken(String value, int max) {
    if (!RegExp(r'^\d{1,2}$').hasMatch(value)) {
      return null;
    }
    final parsed = int.parse(value);
    return parsed <= max ? parsed : null;
  }

  String _automationStatusLabel(Map<String, Object?> row) {
    final state = _mapValue(row['state']);
    final status = _automationStatusKey(row, state);
    return switch (status) {
      'system' => 'System',
      'running' => 'Running now',
      'paused' => 'Paused',
      'failed' => 'Failed',
      'completed' => 'Completed',
      'idle' => 'No schedule',
      _ => 'Active',
    };
  }

  String _automationStatusKey(
    Map<String, Object?> row,
    Map<String, Object?>? state,
  ) {
    if (row['protected'] == true) {
      return 'system';
    }
    if (state?['pending'] == true) {
      return 'running';
    }
    if (row['enabled'] == false) {
      return 'paused';
    }
    if (state?['last_status'] == 'error') {
      return 'failed';
    }
    if (_isLocalTriggerAutomation(row)) {
      return 'active';
    }
    if (row['delete_after_run'] == true &&
        _intValue(state?['next_run_at_ms']) == null &&
        state?['last_status'] == 'ok') {
      return 'completed';
    }
    if (_intValue(state?['next_run_at_ms']) == null) {
      return 'idle';
    }
    return 'active';
  }

  bool _isLocalTriggerAutomation(Map<String, Object?> row) {
    if (_stringFrom(row['kind']) == 'local_trigger') {
      return true;
    }
    final payload = _mapValue(row['payload']);
    if (_stringFrom(payload?['kind']) == 'local_trigger') {
      return true;
    }
    final schedule = _mapValue(row['schedule']);
    return _stringFrom(schedule?['kind']) == 'local';
  }

  List<String> _automationFilterKeys(Map<String, Object?> row) {
    if (row['protected'] == true) {
      return const ['system'];
    }
    final state = row['state'];
    final lastStatus = state is Map ? state['last_status'] : null;
    if (lastStatus == 'error') {
      return const ['failed'];
    }
    if (row['enabled'] == false) {
      return const ['paused'];
    }
    return const ['active'];
  }

  int? _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double && value.isFinite) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  String _skillStatus(Map<String, Object?> row) {
    if (row['available'] != false) {
      return 'available';
    }
    final reason = _stringValue(row, 'unavailable_reason').trim();
    if (reason.isNotEmpty) {
      return 'Missing: $reason';
    }
    return 'unavailable';
  }

  NanobotSidebarState _sidebarStateFromDto(NanobotSidebarStateDto dto) {
    return NanobotSidebarState(
      pinnedKeys: dto.pinnedKeys,
      archivedKeys: dto.archivedKeys,
      titleOverrides: dto.titleOverrides,
      projectNameOverrides: dto.projectNameOverrides,
      collapsedGroups: dto.collapsedGroups,
      showArchived: dto.view.showArchived,
      showPreviews: dto.view.showPreviews,
      showTimestamps: dto.view.showTimestamps,
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
        showPreviews: state.showPreviews,
        showTimestamps: state.showTimestamps,
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
