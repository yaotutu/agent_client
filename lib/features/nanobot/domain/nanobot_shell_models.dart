enum NanobotShellView { chat, settings, apps, automations, skills }

class NanobotSettingsSnapshot {
  const NanobotSettingsSnapshot({
    this.model,
    this.provider,
    this.totalTokens = 0,
    this.requiresRestart = false,
    this.version,
  });

  final String? model;
  final String? provider;
  final int totalTokens;
  final bool requiresRestart;
  final String? version;
}

class NanobotCatalogItem {
  const NanobotCatalogItem({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.status = '',
  });

  final String id;
  final String title;
  final String subtitle;
  final String status;
}

class NanobotSlashCommand {
  const NanobotSlashCommand({
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
}

class NanobotSessionDeleteResult {
  const NanobotSessionDeleteResult({
    required this.deleted,
    this.blockedByAutomations = false,
    this.automations = const [],
  });

  final bool deleted;
  final bool blockedByAutomations;
  final List<Map<String, Object?>> automations;
}

class NanobotWorkspaceScope {
  const NanobotWorkspaceScope({
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

  String get projectLabel {
    final name = projectName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    final normalized = projectPath
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'/+$'), '');
    final parts = normalized.split('/').where((part) => part.isNotEmpty);
    return parts.isEmpty ? projectPath : parts.last;
  }

  bool get isFullAccess => accessMode == 'full';

  NanobotWorkspaceScope withAccessMode(String nextAccessMode) {
    return NanobotWorkspaceScope(
      projectPath: projectPath,
      projectName: projectName,
      accessMode: nextAccessMode,
      restrictToWorkspace: nextAccessMode == 'restricted',
      sandboxStatus: sandboxStatus,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'project_path': projectPath,
      if (projectName != null) 'project_name': projectName,
      'access_mode': accessMode,
      if (restrictToWorkspace != null)
        'restrict_to_workspace': restrictToWorkspace,
      if (sandboxStatus != null) 'sandbox_status': sandboxStatus,
    };
  }
}

class NanobotWorkspaceSnapshot {
  const NanobotWorkspaceSnapshot({
    required this.defaultScope,
    this.controls,
    this.recent = const [],
  });

  final NanobotWorkspaceScope defaultScope;
  final Map<String, Object?>? controls;
  final List<NanobotWorkspaceScope> recent;

  bool get canUseFullAccess => controls?['can_use_full_access'] != false;
}

class NanobotSidebarState {
  const NanobotSidebarState({
    this.pinnedKeys = const [],
    this.archivedKeys = const [],
    this.titleOverrides = const {},
    this.projectNameOverrides = const {},
    this.collapsedGroups = const {},
    this.showArchived = false,
    this.sort = 'updated_desc',
    this.density = 'comfortable',
  });

  final List<String> pinnedKeys;
  final List<String> archivedKeys;
  final Map<String, String> titleOverrides;
  final Map<String, String> projectNameOverrides;
  final Map<String, bool> collapsedGroups;
  final bool showArchived;
  final String sort;
  final String density;

  NanobotSidebarState copyWith({
    List<String>? pinnedKeys,
    List<String>? archivedKeys,
    Map<String, String>? titleOverrides,
    Map<String, String>? projectNameOverrides,
    Map<String, bool>? collapsedGroups,
    bool? showArchived,
    String? sort,
    String? density,
  }) {
    return NanobotSidebarState(
      pinnedKeys: pinnedKeys ?? this.pinnedKeys,
      archivedKeys: archivedKeys ?? this.archivedKeys,
      titleOverrides: titleOverrides ?? this.titleOverrides,
      projectNameOverrides: projectNameOverrides ?? this.projectNameOverrides,
      collapsedGroups: collapsedGroups ?? this.collapsedGroups,
      showArchived: showArchived ?? this.showArchived,
      sort: sort ?? this.sort,
      density: density ?? this.density,
    );
  }
}
