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
