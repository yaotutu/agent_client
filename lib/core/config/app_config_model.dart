class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.apiKey,
    this.appearanceTheme = defaultAppearanceTheme,
    this.appearanceLanguage = defaultAppearanceLanguage,
    this.appearanceDensity = defaultAppearanceDensity,
    this.appearanceActivityMode = defaultAppearanceActivityMode,
    this.appearanceCodeWrap = defaultAppearanceCodeWrap,
    this.appearanceBrandLogos = defaultAppearanceBrandLogos,
  });

  static const _legacyDefaultApiBaseUrls = {
    'http://192.168.200.149:8765',
    'http://192.168.55.130:8765',
  };

  static const defaultApiBaseUrl = String.fromEnvironment(
    'NANOBOT_BASE_URL',
    defaultValue: 'http://192.168.55.240:8765',
  );

  static const defaultApiKey = String.fromEnvironment(
    'NANOBOT_SECRET',
    defaultValue: 'redhat',
  );

  static const defaultAppearanceTheme = 'dark';
  static const defaultAppearanceLanguage = 'system';
  static const defaultAppearanceDensity = 'comfortable';
  static const defaultAppearanceActivityMode = 'auto';
  static const defaultAppearanceCodeWrap = true;
  static const defaultAppearanceBrandLogos = false;
  static const _appearanceThemes = {'light', 'dark'};
  static const _appearanceLanguages = {'system', 'en'};
  static const _appearanceDensities = {'comfortable', 'compact'};
  static const _appearanceActivityModes = {'auto', 'expanded'};

  static const defaults = AppConfig(
    apiBaseUrl: defaultApiBaseUrl,
    apiKey: defaultApiKey,
  );

  final String apiBaseUrl;
  final String apiKey;
  final String appearanceTheme;
  final String appearanceLanguage;
  final String appearanceDensity;
  final String appearanceActivityMode;
  final bool appearanceCodeWrap;
  final bool appearanceBrandLogos;

  AppConfig copyWith({
    String? apiBaseUrl,
    String? apiKey,
    String? appearanceTheme,
    String? appearanceLanguage,
    String? appearanceDensity,
    String? appearanceActivityMode,
    bool? appearanceCodeWrap,
    bool? appearanceBrandLogos,
  }) {
    return AppConfig(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      apiKey: apiKey ?? this.apiKey,
      appearanceTheme: appearanceTheme ?? this.appearanceTheme,
      appearanceLanguage: appearanceLanguage ?? this.appearanceLanguage,
      appearanceDensity: appearanceDensity ?? this.appearanceDensity,
      appearanceActivityMode:
          appearanceActivityMode ?? this.appearanceActivityMode,
      appearanceCodeWrap: appearanceCodeWrap ?? this.appearanceCodeWrap,
      appearanceBrandLogos: appearanceBrandLogos ?? this.appearanceBrandLogos,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'apiBaseUrl': apiBaseUrl,
      'apiKey': apiKey,
      'appearanceTheme': appearanceTheme,
      'appearanceLanguage': appearanceLanguage,
      'appearanceDensity': appearanceDensity,
      'appearanceActivityMode': appearanceActivityMode,
      'appearanceCodeWrap': appearanceCodeWrap,
      'appearanceBrandLogos': appearanceBrandLogos,
    };
  }

  factory AppConfig.fromJson(Map<String, Object?> json) {
    final apiBaseUrl = json['apiBaseUrl'];
    final apiKey = json['apiKey'];
    final normalizedApiBaseUrl =
        apiBaseUrl is String && apiBaseUrl.trim().isNotEmpty
        ? normalizeBaseUrl(apiBaseUrl)
        : defaultApiBaseUrl;
    return AppConfig(
      apiBaseUrl: _legacyDefaultApiBaseUrls.contains(normalizedApiBaseUrl)
          ? defaultApiBaseUrl
          : normalizedApiBaseUrl,
      apiKey: apiKey is String ? apiKey.trim() : defaultApiKey,
      appearanceTheme: _stringIn(
        json['appearanceTheme'],
        _appearanceThemes,
        defaultAppearanceTheme,
      ),
      appearanceLanguage: _stringIn(
        json['appearanceLanguage'],
        _appearanceLanguages,
        defaultAppearanceLanguage,
      ),
      appearanceDensity: _stringIn(
        json['appearanceDensity'],
        _appearanceDensities,
        defaultAppearanceDensity,
      ),
      appearanceActivityMode: _stringIn(
        json['appearanceActivityMode'],
        _appearanceActivityModes,
        defaultAppearanceActivityMode,
      ),
      appearanceCodeWrap: json['appearanceCodeWrap'] is bool
          ? json['appearanceCodeWrap'] as bool
          : defaultAppearanceCodeWrap,
      appearanceBrandLogos: json['appearanceBrandLogos'] is bool
          ? json['appearanceBrandLogos'] as bool
          : defaultAppearanceBrandLogos,
    );
  }

  static String _stringIn(Object? value, Set<String> allowed, String fallback) {
    if (value is! String) {
      return fallback;
    }
    final normalized = value.trim();
    return allowed.contains(normalized) ? normalized : fallback;
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
            other.apiKey == apiKey &&
            other.appearanceTheme == appearanceTheme &&
            other.appearanceLanguage == appearanceLanguage &&
            other.appearanceDensity == appearanceDensity &&
            other.appearanceActivityMode == appearanceActivityMode &&
            other.appearanceCodeWrap == appearanceCodeWrap &&
            other.appearanceBrandLogos == appearanceBrandLogos;
  }

  @override
  int get hashCode => Object.hash(
    apiBaseUrl,
    apiKey,
    appearanceTheme,
    appearanceLanguage,
    appearanceDensity,
    appearanceActivityMode,
    appearanceCodeWrap,
    appearanceBrandLogos,
  );
}
