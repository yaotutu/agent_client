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
    return NanobotSlashCommandDto(
      command: json['command'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      argHint: json['arg_hint'] as String? ?? '',
      lifecycle: json['lifecycle'] as String? ?? '',
      acceptsArgs: json['accepts_args'] == true,
    );
  }

  static List<NanobotSlashCommandDto> listFromJson(Map<String, Object?> json) {
    return [
      for (final row in _mapListFrom(json['commands']))
        if (_supportedSlashCommandLifecycles.contains(row['lifecycle']))
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

const _supportedSlashCommandLifecycles = {
  'side_channel',
  'finalize_active_turn',
  'stop_active_turn',
  'agent_turn',
  'agent_turn_with_args',
};

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
