import 'package:agent_client/core/config/app_config_model.dart';
import 'package:agent_client/core/config/app_config_store_contract.dart';
import 'package:agent_client/core/config/app_config_store_io.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

export 'package:agent_client/core/config/app_config_model.dart';
export 'package:agent_client/core/config/app_config_store_contract.dart';

final initialAppConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.defaults;
});

final appConfigStoreProvider = Provider<AppConfigStore>((ref) {
  return FileAppConfigStore();
});

final appConfigControllerProvider =
    NotifierProvider<AppConfigController, AppConfig>(AppConfigController.new);

final appConfigProvider = Provider<AppConfig>((ref) {
  return ref.watch(appConfigControllerProvider);
});

class AppConfigController extends Notifier<AppConfig> {
  @override
  AppConfig build() {
    return ref.watch(initialAppConfigProvider);
  }

  Future<void> save({
    required String apiBaseUrl,
    required String apiKey,
  }) async {
    final config = state.copyWith(
      apiBaseUrl: AppConfig.normalizeBaseUrl(apiBaseUrl),
      apiKey: apiKey.trim(),
    );
    await ref.read(appConfigStoreProvider).save(config);
    state = config;
  }

  Future<void> saveAppearance({
    required String theme,
    required String language,
    required String density,
    required String activityMode,
    required bool codeWrap,
    required bool brandLogos,
  }) async {
    final config = state.copyWith(
      appearanceTheme: theme,
      appearanceLanguage: language,
      appearanceDensity: density,
      appearanceActivityMode: activityMode,
      appearanceCodeWrap: codeWrap,
      appearanceBrandLogos: brandLogos,
    );
    await ref.read(appConfigStoreProvider).save(config);
    state = config;
  }

  Future<void> resetToDefaults() {
    return save(
      apiBaseUrl: AppConfig.defaultApiBaseUrl,
      apiKey: AppConfig.defaultApiKey,
    );
  }
}

AppConfigStore createDefaultAppConfigStore() {
  return FileAppConfigStore();
}
