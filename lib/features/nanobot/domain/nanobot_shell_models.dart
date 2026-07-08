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
