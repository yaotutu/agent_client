enum NanobotShellView { chat, settings, apps, automations, skills }

enum NanobotSettingsSection { overview, webSearch }

enum NanobotAutomationAction {
  enable('enable'),
  disable('disable'),
  delete('delete'),
  run('run');

  const NanobotAutomationAction(this.wireName);

  final String wireName;
}

enum NanobotCapabilityMentionKind { cli, mcp }

class NanobotAppsActionResult {
  const NanobotAppsActionResult({
    required this.items,
    this.message,
    this.requiresRestart = false,
  });

  final List<NanobotCatalogItem> items;
  final String? message;
  final bool requiresRestart;
}

class NanobotSettingsSnapshot {
  const NanobotSettingsSnapshot({
    this.model,
    this.provider,
    this.contextWindowTokens,
    this.botName,
    this.webSearchProvider,
    this.webSearchEnabled = false,
    this.webSearchMaxResults,
    this.webSearchTimeoutSeconds,
    this.webFetchUseJinaReader = false,
    this.imageGenerationEnabled = false,
    this.imageGenerationProvider,
    this.imageGenerationModel,
    this.transcriptionEnabled = false,
    this.transcriptionProvider,
    this.transcriptionModel,
    this.runtimeHost,
    this.runtimeGatewayPort,
    this.workspaceCaption,
    this.usageDays = const [],
    this.totalTokens = 0,
    this.totalTokens30d = 0,
    this.totalTokens365d = 0,
    this.peakDayTokens = 0,
    this.currentStreakDays = 0,
    this.longestStreakDays = 0,
    this.requests30d = 0,
    this.activeDays30d = 0,
    this.requiresRestart = false,
    this.version,
  });

  final String? model;
  final String? provider;
  final int? contextWindowTokens;
  final String? botName;
  final String? webSearchProvider;
  final bool webSearchEnabled;
  final int? webSearchMaxResults;
  final int? webSearchTimeoutSeconds;
  final bool webFetchUseJinaReader;
  final bool imageGenerationEnabled;
  final String? imageGenerationProvider;
  final String? imageGenerationModel;
  final bool transcriptionEnabled;
  final String? transcriptionProvider;
  final String? transcriptionModel;
  final String? runtimeHost;
  final int? runtimeGatewayPort;
  final String? workspaceCaption;
  final List<NanobotUsageDay> usageDays;
  final int totalTokens;
  final int totalTokens30d;
  final int totalTokens365d;
  final int peakDayTokens;
  final int currentStreakDays;
  final int longestStreakDays;
  final int requests30d;
  final int activeDays30d;
  final bool requiresRestart;
  final String? version;
}

class NanobotUsageDay {
  const NanobotUsageDay({
    required this.date,
    this.totalTokens = 0,
    this.estimatedTokens = 0,
    this.requests = 0,
    this.sources = const {},
  });

  final String date;
  final int totalTokens;
  final int estimatedTokens;
  final int requests;
  final Map<String, int> sources;
}

class NanobotVersionCheckResult {
  const NanobotVersionCheckResult.upToDate()
    : updateAvailable = false,
      currentVersion = null,
      latestVersion = null,
      pypiUrl = null;

  const NanobotVersionCheckResult.updateAvailable({
    this.currentVersion,
    required this.latestVersion,
    this.pypiUrl,
  }) : updateAvailable = true;

  final bool updateAvailable;
  final String? currentVersion;
  final String? latestVersion;
  final String? pypiUrl;
}

class NanobotCatalogItem {
  const NanobotCatalogItem({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.details = '',
    this.status = '',
    this.filterKeys = const [],
    this.nextRunAtMs,
    this.lastRunAtMs,
    this.createdAtMs,
    this.updatedAtMs,
    this.scheduleLabel = '',
    this.originLabel = '',
    this.originSessionKey,
    this.lastError,
    this.isPending = false,
    this.isProtected = false,
    this.deleteAfterRun = false,
    this.automationScheduleKind,
    this.automationEveryMs,
    this.automationCronExpr,
    this.automationTz,
    this.automationAtMs,
    this.isLocalTriggerAutomation = false,
    this.mcpRequiredFields = const [],
    this.mcpToolNames = const [],
    this.mcpEnabledTools = const [],
  });

  final String id;
  final String title;
  final String subtitle;
  final String details;
  final String status;
  final List<String> filterKeys;
  final int? nextRunAtMs;
  final int? lastRunAtMs;
  final int? createdAtMs;
  final int? updatedAtMs;
  final String scheduleLabel;
  final String originLabel;
  final String? originSessionKey;
  final String? lastError;
  final bool isPending;
  final bool isProtected;
  final bool deleteAfterRun;
  final String? automationScheduleKind;
  final int? automationEveryMs;
  final String? automationCronExpr;
  final String? automationTz;
  final int? automationAtMs;
  final bool isLocalTriggerAutomation;
  final List<NanobotMcpRequiredField> mcpRequiredFields;
  final List<String> mcpToolNames;
  final List<String> mcpEnabledTools;
}

class NanobotMcpRequiredField {
  const NanobotMcpRequiredField({
    required this.name,
    required this.label,
    this.placeholder = '',
    this.secret = false,
    this.required = false,
    this.configured = false,
  });

  final String name;
  final String label;
  final String placeholder;
  final bool secret;
  final bool required;
  final bool configured;
}

class NanobotSkillDetail {
  const NanobotSkillDetail({
    required this.name,
    required this.description,
    required this.source,
    required this.available,
    this.unavailableReason,
    this.bins = const [],
    this.missingBins = const [],
    this.env = const [],
    this.missingEnv = const [],
    this.rawMarkdown = '',
  });

  final String name;
  final String description;
  final String source;
  final bool available;
  final String? unavailableReason;
  final List<String> bins;
  final List<String> missingBins;
  final List<String> env;
  final List<String> missingEnv;
  final String rawMarkdown;
}

class NanobotFilePreview {
  const NanobotFilePreview({
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
}

class NanobotCapabilityMention {
  const NanobotCapabilityMention({
    required this.kind,
    required this.name,
    required this.displayName,
    this.category = '',
    this.description = '',
    this.entryPoint,
    this.transport,
    this.installed = false,
    this.configured = false,
    this.status = '',
    this.logoUrl,
    this.brandColor,
  });

  final NanobotCapabilityMentionKind kind;
  final String name;
  final String displayName;
  final String category;
  final String description;
  final String? entryPoint;
  final String? transport;
  final bool installed;
  final bool configured;
  final String status;
  final String? logoUrl;
  final String? brandColor;

  bool get canMention {
    return switch (kind) {
      NanobotCapabilityMentionKind.cli => installed,
      NanobotCapabilityMentionKind.mcp => installed && configured,
    };
  }
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
    this.showPreviews = false,
    this.showTimestamps = false,
    this.sort = 'updated_desc',
    this.density = 'comfortable',
  });

  final List<String> pinnedKeys;
  final List<String> archivedKeys;
  final Map<String, String> titleOverrides;
  final Map<String, String> projectNameOverrides;
  final Map<String, bool> collapsedGroups;
  final bool showArchived;
  final bool showPreviews;
  final bool showTimestamps;
  final String sort;
  final String density;

  NanobotSidebarState copyWith({
    List<String>? pinnedKeys,
    List<String>? archivedKeys,
    Map<String, String>? titleOverrides,
    Map<String, String>? projectNameOverrides,
    Map<String, bool>? collapsedGroups,
    bool? showArchived,
    bool? showPreviews,
    bool? showTimestamps,
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
      showPreviews: showPreviews ?? this.showPreviews,
      showTimestamps: showTimestamps ?? this.showTimestamps,
      sort: sort ?? this.sort,
      density: density ?? this.density,
    );
  }
}
