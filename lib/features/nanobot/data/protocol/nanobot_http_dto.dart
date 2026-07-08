class NanobotWebuiThreadDto {
  const NanobotWebuiThreadDto({
    required this.schemaVersion,
    this.sessionKey,
    this.savedAt,
    this.messages = const [],
    this.forkBoundaryMessageCount,
    this.hasPendingToolCalls = false,
    this.page,
    this.workspaceScope,
  });

  final int schemaVersion;
  final String? sessionKey;
  final String? savedAt;
  final List<Map<String, Object?>> messages;
  final int? forkBoundaryMessageCount;
  final bool hasPendingToolCalls;
  final NanobotWebuiThreadPageDto? page;
  final NanobotWorkspaceScopeDto? workspaceScope;

  factory NanobotWebuiThreadDto.fromJson(Map<String, Object?> json) {
    return NanobotWebuiThreadDto(
      schemaVersion: _intFrom(json['schemaVersion']) ?? 0,
      sessionKey: json['sessionKey'] as String?,
      savedAt: json['savedAt'] as String?,
      messages: _mapListFrom(json['messages']),
      forkBoundaryMessageCount: _intFrom(json['fork_boundary_message_count']),
      hasPendingToolCalls: json['has_pending_tool_calls'] == true,
      page: _mapFrom(json['page']) == null
          ? null
          : NanobotWebuiThreadPageDto.fromJson(_mapFrom(json['page'])!),
      workspaceScope: _mapFrom(json['workspace_scope']) == null
          ? null
          : NanobotWorkspaceScopeDto.fromJson(
              _mapFrom(json['workspace_scope'])!,
            ),
    );
  }
}

class NanobotWebuiThreadPageDto {
  const NanobotWebuiThreadPageDto({
    this.beforeCursor,
    this.hasMoreBefore = false,
    this.loadedMessageCount,
    this.totalKnownMessageCount,
    this.userMessageOffset,
  });

  final String? beforeCursor;
  final bool hasMoreBefore;
  final int? loadedMessageCount;
  final int? totalKnownMessageCount;
  final int? userMessageOffset;

  factory NanobotWebuiThreadPageDto.fromJson(Map<String, Object?> json) {
    return NanobotWebuiThreadPageDto(
      beforeCursor: json['before_cursor'] as String?,
      hasMoreBefore: json['has_more_before'] == true,
      loadedMessageCount: _intFrom(json['loaded_message_count']),
      totalKnownMessageCount: _intFrom(json['total_known_message_count']),
      userMessageOffset: _intFrom(json['user_message_offset']),
    );
  }
}

class NanobotWorkspaceScopeDto {
  const NanobotWorkspaceScopeDto({
    required this.projectPath,
    required this.accessMode,
    this.projectName,
    this.restrictToWorkspace,
    this.sandboxStatus,
  });

  final String projectPath;
  final String? projectName;
  final String accessMode;
  final bool? restrictToWorkspace;
  final Map<String, Object?>? sandboxStatus;

  factory NanobotWorkspaceScopeDto.fromJson(Map<String, Object?> json) {
    return NanobotWorkspaceScopeDto(
      projectPath: json['project_path'] as String? ?? '',
      projectName: json['project_name'] as String?,
      accessMode: json['access_mode'] as String? ?? 'restricted',
      restrictToWorkspace: json['restrict_to_workspace'] as bool?,
      sandboxStatus: _mapFrom(json['sandbox_status']),
    );
  }

  Map<String, Object?> toJson() {
    return _withoutNulls({
      'project_path': projectPath,
      'project_name': projectName,
      'access_mode': accessMode,
      'restrict_to_workspace': restrictToWorkspace,
      'sandbox_status': sandboxStatus,
    });
  }
}

class NanobotWorkspacesDto {
  const NanobotWorkspacesDto({
    required this.defaultScope,
    this.controls,
    this.recent = const [],
  });

  final NanobotWorkspaceScopeDto defaultScope;
  final Map<String, Object?>? controls;
  final List<NanobotWorkspaceScopeDto> recent;

  factory NanobotWorkspacesDto.fromJson(Map<String, Object?> json) {
    return NanobotWorkspacesDto(
      defaultScope: NanobotWorkspaceScopeDto.fromJson(
        _mapFrom(json['default_scope']) ?? const {},
      ),
      controls: _mapFrom(json['controls']),
      recent: [
        for (final row in _mapListFrom(json['recent']))
          NanobotWorkspaceScopeDto.fromJson(row),
      ],
    );
  }
}

class NanobotSidebarStateDto {
  const NanobotSidebarStateDto({
    this.pinnedKeys = const [],
    this.archivedKeys = const [],
    this.titleOverrides = const {},
    this.projectNameOverrides = const {},
    this.collapsedGroups = const {},
    this.view = const NanobotSidebarViewDto(),
  });

  final List<String> pinnedKeys;
  final List<String> archivedKeys;
  final Map<String, String> titleOverrides;
  final Map<String, String> projectNameOverrides;
  final Map<String, bool> collapsedGroups;
  final NanobotSidebarViewDto view;

  factory NanobotSidebarStateDto.fromJson(Map<String, Object?> json) {
    return NanobotSidebarStateDto(
      pinnedKeys: _stringListFrom(json['pinned_keys']),
      archivedKeys: _stringListFrom(json['archived_keys']),
      titleOverrides: _stringMapFrom(json['title_overrides']),
      projectNameOverrides: _stringMapFrom(json['project_name_overrides']),
      collapsedGroups: _boolMapFrom(json['collapsed_groups']),
      view: NanobotSidebarViewDto.fromJson(_mapFrom(json['view']) ?? const {}),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'pinned_keys': pinnedKeys,
      'archived_keys': archivedKeys,
      'title_overrides': titleOverrides,
      'project_name_overrides': projectNameOverrides,
      'collapsed_groups': collapsedGroups,
      'view': view.toJson(),
    };
  }
}

class NanobotSidebarViewDto {
  const NanobotSidebarViewDto({
    this.density = 'comfortable',
    this.sort = 'updated_desc',
    this.showArchived = false,
  });

  final String density;
  final String sort;
  final bool showArchived;

  factory NanobotSidebarViewDto.fromJson(Map<String, Object?> json) {
    return NanobotSidebarViewDto(
      density: json['density'] as String? ?? 'comfortable',
      sort: json['sort'] as String? ?? 'updated_desc',
      showArchived: json['show_archived'] == true,
    );
  }

  Map<String, Object?> toJson() {
    return {'density': density, 'sort': sort, 'show_archived': showArchived};
  }
}

class NanobotSlashCommandDto {
  const NanobotSlashCommandDto({
    required this.command,
    required this.title,
    required this.description,
    required this.icon,
    required this.lifecycle,
    this.argHint = '',
    this.acceptsArgs = false,
  });

  final String command;
  final String title;
  final String description;
  final String icon;
  final String argHint;
  final String lifecycle;
  final bool acceptsArgs;

  factory NanobotSlashCommandDto.fromJson(Map<String, Object?> json) {
    final command = json['command'] as String? ?? '';
    final argHint = json['arg_hint'] as String? ?? '';
    return NanobotSlashCommandDto(
      command: command,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      argHint: argHint,
      lifecycle: _slashLifecycleFor(command, json['lifecycle'] as String?),
      acceptsArgs: json['accepts_args'] == true || argHint.trim().isNotEmpty,
    );
  }

  static List<NanobotSlashCommandDto> listFromJson(Map<String, Object?> json) {
    return [
      for (final row in _mapListFrom(json['commands']))
        if (_isSupportedSlashCommandRow(row))
          NanobotSlashCommandDto.fromJson(row),
    ];
  }
}

class NanobotFilePreviewDto {
  const NanobotFilePreviewDto({
    required this.path,
    required this.displayPath,
    required this.projectPath,
    required this.language,
    required this.content,
    required this.size,
    required this.truncated,
  });

  final String path;
  final String displayPath;
  final String projectPath;
  final String language;
  final String content;
  final int size;
  final bool truncated;

  factory NanobotFilePreviewDto.fromJson(Map<String, Object?> json) {
    return NanobotFilePreviewDto(
      path: json['path'] as String? ?? '',
      displayPath: json['display_path'] as String? ?? '',
      projectPath: json['project_path'] as String? ?? '',
      language: json['language'] as String? ?? '',
      content: json['content'] as String? ?? '',
      size: _intFrom(json['size']) ?? 0,
      truncated: json['truncated'] == true,
    );
  }
}

class NanobotSettingsDto {
  const NanobotSettingsDto({
    this.surface,
    this.runtimeSurface,
    this.runtimeCapabilities,
    this.applyState,
    this.restartBehaviorBySection,
    this.agent = const {},
    this.modelPresets = const [],
    this.providers = const [],
    this.webSearch,
    this.web,
    this.imageGeneration,
    this.transcription,
    this.runtime,
    this.usage,
    this.advanced,
    this.requiresRestart = false,
    this.restartRequiredSections = const [],
    this.version,
  });

  final String? surface;
  final String? runtimeSurface;
  final Map<String, Object?>? runtimeCapabilities;
  final Map<String, Object?>? applyState;
  final Map<String, Object?>? restartBehaviorBySection;
  final Map<String, Object?> agent;
  final List<Map<String, Object?>> modelPresets;
  final List<Map<String, Object?>> providers;
  final Map<String, Object?>? webSearch;
  final Map<String, Object?>? web;
  final Map<String, Object?>? imageGeneration;
  final Map<String, Object?>? transcription;
  final Map<String, Object?>? runtime;
  final NanobotSettingsUsageDto? usage;
  final Map<String, Object?>? advanced;
  final bool requiresRestart;
  final List<String> restartRequiredSections;
  final Map<String, Object?>? version;

  factory NanobotSettingsDto.fromJson(Map<String, Object?> json) {
    return NanobotSettingsDto(
      surface: json['surface'] as String?,
      runtimeSurface: json['runtime_surface'] as String?,
      runtimeCapabilities: _mapFrom(json['runtime_capabilities']),
      applyState: _mapFrom(json['apply_state']),
      restartBehaviorBySection: _mapFrom(json['restart_behavior_by_section']),
      agent: _mapFrom(json['agent']) ?? const {},
      modelPresets: _mapListFrom(json['model_presets']),
      providers: _mapListFrom(json['providers']),
      webSearch: _mapFrom(json['web_search']),
      web: _mapFrom(json['web']),
      imageGeneration: _mapFrom(json['image_generation']),
      transcription: _mapFrom(json['transcription']),
      runtime: _mapFrom(json['runtime']),
      usage: _mapFrom(json['usage']) == null
          ? null
          : NanobotSettingsUsageDto.fromJson(_mapFrom(json['usage'])!),
      advanced: _mapFrom(json['advanced']),
      requiresRestart: json['requires_restart'] == true,
      restartRequiredSections: _stringListFrom(
        json['restart_required_sections'],
      ),
      version: _mapFrom(json['version']),
    );
  }
}

class NanobotSettingsUsageDto {
  const NanobotSettingsUsageDto({
    this.days = const [],
    this.totalTokens = 0,
    this.totalTokens30d = 0,
    this.totalTokens365d = 0,
    this.peakDayTokens = 0,
    this.currentStreakDays = 0,
    this.longestStreakDays = 0,
    this.activeDays30d = 0,
    this.requests30d = 0,
    this.updatedAt,
  });

  final List<Map<String, Object?>> days;
  final int totalTokens;
  final int totalTokens30d;
  final int totalTokens365d;
  final int peakDayTokens;
  final int currentStreakDays;
  final int longestStreakDays;
  final int activeDays30d;
  final int requests30d;
  final String? updatedAt;

  factory NanobotSettingsUsageDto.fromJson(Map<String, Object?> json) {
    return NanobotSettingsUsageDto(
      days: _mapListFrom(json['days']),
      totalTokens: _intFrom(json['total_tokens']) ?? 0,
      totalTokens30d: _intFrom(json['total_tokens_30d']) ?? 0,
      totalTokens365d: _intFrom(json['total_tokens_365d']) ?? 0,
      peakDayTokens: _intFrom(json['peak_day_tokens']) ?? 0,
      currentStreakDays: _intFrom(json['current_streak_days']) ?? 0,
      longestStreakDays: _intFrom(json['longest_streak_days']) ?? 0,
      activeDays30d: _intFrom(json['active_days_30d']) ?? 0,
      requests30d: _intFrom(json['requests_30d']) ?? 0,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class NanobotSkillsDto {
  const NanobotSkillsDto({this.skills = const []});

  final List<Map<String, Object?>> skills;

  factory NanobotSkillsDto.fromJson(Map<String, Object?> json) {
    return NanobotSkillsDto(skills: _mapListFrom(json['skills']));
  }
}

class NanobotSkillDetailDto {
  const NanobotSkillDetailDto({
    required this.name,
    required this.description,
    required this.source,
    required this.available,
    this.unavailableReason,
    this.requirements,
    this.rawMarkdown = '',
  });

  final String name;
  final String description;
  final String source;
  final bool available;
  final String? unavailableReason;
  final Map<String, Object?>? requirements;
  final String rawMarkdown;

  factory NanobotSkillDetailDto.fromJson(Map<String, Object?> json) {
    return NanobotSkillDetailDto(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      source: json['source'] as String? ?? '',
      available: json['available'] == true,
      unavailableReason: json['unavailable_reason'] as String?,
      requirements: _mapFrom(json['requirements']),
      rawMarkdown: json['raw_markdown'] as String? ?? '',
    );
  }
}

class NanobotCliAppsDto {
  const NanobotCliAppsDto({
    this.apps = const [],
    this.installedCount = 0,
    this.catalogUpdatedAt,
    this.catalogRefreshPending = false,
    this.lastAction,
  });

  final List<Map<String, Object?>> apps;
  final int installedCount;
  final String? catalogUpdatedAt;
  final bool catalogRefreshPending;
  final Map<String, Object?>? lastAction;

  factory NanobotCliAppsDto.fromJson(Map<String, Object?> json) {
    return NanobotCliAppsDto(
      apps: _mapListFrom(json['apps']),
      installedCount: _intFrom(json['installed_count']) ?? 0,
      catalogUpdatedAt: json['catalog_updated_at'] as String?,
      catalogRefreshPending: json['catalog_refresh_pending'] == true,
      lastAction: _mapFrom(json['last_action']),
    );
  }
}

class NanobotFeaturesDto {
  const NanobotFeaturesDto({
    this.features = const [],
    this.enabledCount = 0,
    this.requiresRestart = false,
    this.lastAction,
  });

  final List<Map<String, Object?>> features;
  final int enabledCount;
  final bool requiresRestart;
  final Map<String, Object?>? lastAction;

  factory NanobotFeaturesDto.fromJson(Map<String, Object?> json) {
    return NanobotFeaturesDto(
      features: _mapListFrom(json['features']),
      enabledCount: _intFrom(json['enabled_count']) ?? 0,
      requiresRestart: json['requires_restart'] == true,
      lastAction: _mapFrom(json['last_action']),
    );
  }
}

class NanobotMcpPresetsDto {
  const NanobotMcpPresetsDto({
    this.presets = const [],
    this.installedCount = 0,
    this.requiresRestart = false,
    this.hotReload,
    this.lastAction,
  });

  final List<Map<String, Object?>> presets;
  final int installedCount;
  final bool requiresRestart;
  final Map<String, Object?>? hotReload;
  final Map<String, Object?>? lastAction;

  factory NanobotMcpPresetsDto.fromJson(Map<String, Object?> json) {
    return NanobotMcpPresetsDto(
      presets: _mapListFrom(json['presets']),
      installedCount: _intFrom(json['installed_count']) ?? 0,
      requiresRestart: json['requires_restart'] == true,
      hotReload: _mapFrom(json['hot_reload']),
      lastAction: _mapFrom(json['last_action']),
    );
  }
}

class NanobotProviderModelsDto {
  const NanobotProviderModelsDto({
    required this.provider,
    required this.label,
    required this.status,
    required this.catalogKind,
    this.models = const [],
    this.modelCount = 0,
    this.message,
    this.fetchedAt,
  });

  final String provider;
  final String label;
  final String status;
  final String catalogKind;
  final List<Map<String, Object?>> models;
  final int modelCount;
  final String? message;
  final int? fetchedAt;

  factory NanobotProviderModelsDto.fromJson(Map<String, Object?> json) {
    return NanobotProviderModelsDto(
      provider: json['provider'] as String? ?? '',
      label: json['label'] as String? ?? '',
      status: json['status'] as String? ?? '',
      catalogKind: json['catalog_kind'] as String? ?? '',
      models: _mapListFrom(json['models']),
      modelCount: _intFrom(json['model_count']) ?? 0,
      message: json['message'] as String?,
      fetchedAt: _intFrom(json['fetched_at']),
    );
  }
}

class NanobotAutomationsDto {
  const NanobotAutomationsDto({this.jobs = const []});

  final List<Map<String, Object?>> jobs;

  factory NanobotAutomationsDto.fromJson(Map<String, Object?> json) {
    return NanobotAutomationsDto(jobs: _mapListFrom(json['jobs']));
  }
}

class NanobotSessionDeleteResultDto {
  const NanobotSessionDeleteResultDto({
    required this.deleted,
    this.blockedByAutomations = false,
    this.automations = const [],
  });

  final bool deleted;
  final bool blockedByAutomations;
  final List<Map<String, Object?>> automations;

  factory NanobotSessionDeleteResultDto.fromJson(Map<String, Object?> json) {
    return NanobotSessionDeleteResultDto(
      deleted: json['deleted'] == true,
      blockedByAutomations: json['blocked_by_automations'] == true,
      automations: _mapListFrom(json['automations']),
    );
  }
}

class NanobotVersionCheckDto {
  const NanobotVersionCheckDto({this.updateAvailable});

  final Map<String, Object?>? updateAvailable;

  factory NanobotVersionCheckDto.fromJson(Map<String, Object?> json) {
    return NanobotVersionCheckDto(
      updateAvailable: _mapFrom(json['updateAvailable']),
    );
  }
}

const _supportedSlashCommandLifecycles = {
  'side_channel',
  'finalize_active_turn',
  'stop_active_turn',
  'agent_turn',
  'agent_turn_with_args',
};

bool _isSupportedSlashCommandRow(Map<String, Object?> row) {
  final command = row['command'] as String? ?? '';
  if (!command.startsWith('/')) {
    return false;
  }
  final lifecycle = row['lifecycle'];
  return lifecycle == null ||
      lifecycle == '' ||
      _supportedSlashCommandLifecycles.contains(lifecycle);
}

String _slashLifecycleFor(String command, String? lifecycle) {
  if (lifecycle != null &&
      _supportedSlashCommandLifecycles.contains(lifecycle)) {
    return lifecycle;
  }
  return switch (command) {
    '/new' => 'finalize_active_turn',
    '/stop' => 'stop_active_turn',
    '/goal' => 'agent_turn_with_args',
    _ => 'side_channel',
  };
}

int? _intFrom(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

List<String> _stringListFrom(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is String) item,
  ];
}

List<Map<String, Object?>> _mapListFrom(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map) Map<String, Object?>.from(item),
  ];
}

Map<String, Object?>? _mapFrom(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  return null;
}

Map<String, String> _stringMapFrom(Object? value) {
  final map = _mapFrom(value);
  if (map == null) return const {};
  return {
    for (final entry in map.entries)
      if (entry.value is String) entry.key: entry.value! as String,
  };
}

Map<String, bool> _boolMapFrom(Object? value) {
  final map = _mapFrom(value);
  if (map == null) return const {};
  return {
    for (final entry in map.entries)
      if (entry.value is bool) entry.key: entry.value! as bool,
  };
}

Map<String, Object?> _withoutNulls(Map<String, Object?> value) {
  return {
    for (final entry in value.entries)
      if (entry.value != null) entry.key: entry.value,
  };
}
