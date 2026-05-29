class AgentSettingsSnapshot {
  const AgentSettingsSnapshot({
    required this.model,
    required this.provider,
    required this.resolvedProvider,
    required this.hasApiKey,
    required this.providers,
    required this.requiresRestart,
  });

  const AgentSettingsSnapshot.empty()
    : model = null,
      provider = null,
      resolvedProvider = null,
      hasApiKey = false,
      providers = const [],
      requiresRestart = false;

  final String? model;
  final String? provider;
  final String? resolvedProvider;
  final bool hasApiKey;
  final List<AgentProviderSettingsItem> providers;
  final bool requiresRestart;
}

class AgentProviderSettingsItem {
  const AgentProviderSettingsItem({
    required this.name,
    required this.label,
    required this.configured,
    required this.models,
    this.apiKeyHint,
    this.apiBase,
    this.defaultApiBase,
  });

  final String name;
  final String label;
  final bool configured;
  final List<String> models;
  final String? apiKeyHint;
  final String? apiBase;
  final String? defaultApiBase;
}
