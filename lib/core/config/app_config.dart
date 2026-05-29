import 'package:hooks_riverpod/hooks_riverpod.dart';

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.defaultModel,
    this.apiKey = '',
  });

  final String apiBaseUrl;
  final String defaultModel;
  final String apiKey;

  bool get hasApiKey => apiKey.trim().isNotEmpty;
}

final appConfigProvider = Provider<AppConfig>((ref) {
  return const AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'AGENT_API_BASE_URL',
      defaultValue: 'http://localhost:8000',
    ),
    defaultModel: String.fromEnvironment(
      'AGENT_MODEL',
      defaultValue: 'gpt-4.1-mini',
    ),
    apiKey: String.fromEnvironment('AGENT_API_KEY'),
  );
});
