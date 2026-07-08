import 'package:agent_client/core/config/app_config.dart';

class NanobotConfig {
  const NanobotConfig({required this.baseUrl, required this.secret});

  final String baseUrl;
  final String secret;

  factory NanobotConfig.fromAppConfig(AppConfig config) {
    return NanobotConfig(
      baseUrl: AppConfig.normalizeBaseUrl(config.apiBaseUrl),
      secret: config.apiKey.trim(),
    );
  }
}
