import 'package:hooks_riverpod/hooks_riverpod.dart';

class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  final String apiBaseUrl;
}

final appConfigProvider = Provider<AppConfig>((ref) {
  return const AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'AGENT_API_BASE_URL',
      defaultValue: 'http://192.168.123.116:9800',
    ),
  );
});
