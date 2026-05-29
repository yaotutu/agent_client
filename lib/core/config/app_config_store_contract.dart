import 'package:agent_client/core/config/app_config_model.dart';

abstract interface class AppConfigStore {
  Future<AppConfig?> load();

  Future<void> save(AppConfig config);
}
