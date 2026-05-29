class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.apiKey});

  static const defaultApiBaseUrl = String.fromEnvironment(
    'AGENT_API_BASE_URL',
    defaultValue: 'http://192.168.123.116:9800',
  );

  static const defaultApiKey = String.fromEnvironment(
    'AGENT_API_KEY',
    defaultValue:
        '9217f326d00e1788d89d9e4fca9c98371d5eb4279b7f5427ab5aa7d22e180211',
  );

  static const defaults = AppConfig(
    apiBaseUrl: defaultApiBaseUrl,
    apiKey: defaultApiKey,
  );

  final String apiBaseUrl;
  final String apiKey;

  AppConfig copyWith({String? apiBaseUrl, String? apiKey}) {
    return AppConfig(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      apiKey: apiKey ?? this.apiKey,
    );
  }

  Map<String, Object?> toJson() {
    return {'apiBaseUrl': apiBaseUrl, 'apiKey': apiKey};
  }

  factory AppConfig.fromJson(Map<String, Object?> json) {
    final apiBaseUrl = json['apiBaseUrl'];
    final apiKey = json['apiKey'];
    return AppConfig(
      apiBaseUrl: apiBaseUrl is String && apiBaseUrl.trim().isNotEmpty
          ? normalizeBaseUrl(apiBaseUrl)
          : defaultApiBaseUrl,
      apiKey: apiKey is String ? apiKey.trim() : defaultApiKey,
    );
  }

  static String normalizeBaseUrl(String value) {
    var normalized = value.trim();
    while (normalized.endsWith('/') && normalized.length > 'https://'.length) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppConfig &&
            other.apiBaseUrl == apiBaseUrl &&
            other.apiKey == apiKey;
  }

  @override
  int get hashCode => Object.hash(apiBaseUrl, apiKey);
}
