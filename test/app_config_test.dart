import 'package:agent_client/core/config/app_config.dart';
import 'package:agent_client/core/config/app_config_store_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('app config defaults to the current nanobot gateway', () {
    expect(AppConfig.defaults.apiBaseUrl, 'http://192.168.55.240:8765');
    expect(AppConfig.defaults.apiKey, 'redhat');
  });

  test('app config migrates old nanobot default gateways', () {
    expect(
      AppConfig.fromJson({
        'apiBaseUrl': 'http://192.168.200.149:8765',
        'apiKey': 'redhat',
      }).apiBaseUrl,
      'http://192.168.55.240:8765',
    );
    expect(
      AppConfig.fromJson({
        'apiBaseUrl': ' http://192.168.55.130:8765/ ',
        'apiKey': 'redhat',
      }).apiBaseUrl,
      'http://192.168.55.240:8765',
    );
  });

  test('app config controller saves editable backend settings', () async {
    final store = _MemoryAppConfigStore();
    final container = ProviderContainer(
      overrides: [
        appConfigStoreProvider.overrideWithValue(store),
        initialAppConfigProvider.overrideWithValue(AppConfig.defaults),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(appConfigControllerProvider.notifier)
        .save(apiBaseUrl: ' http://10.0.0.2:9800/ ', apiKey: ' edited-key ');

    expect(
      container.read(appConfigProvider),
      const AppConfig(apiBaseUrl: 'http://10.0.0.2:9800', apiKey: 'edited-key'),
    );
    expect(
      store.saved,
      const AppConfig(apiBaseUrl: 'http://10.0.0.2:9800', apiKey: 'edited-key'),
    );
  });

  test('app config preserves webui local appearance preferences', () async {
    final config = AppConfig.fromJson({
      'apiBaseUrl': 'http://192.168.55.240:8765',
      'apiKey': 'redhat',
      'appearanceTheme': 'light',
      'appearanceLanguage': 'en',
      'appearanceDensity': 'compact',
      'appearanceActivityMode': 'expanded',
      'appearanceCodeWrap': false,
      'appearanceBrandLogos': true,
    });

    expect(config.appearanceTheme, 'light');
    expect(config.appearanceLanguage, 'en');
    expect(config.appearanceDensity, 'compact');
    expect(config.appearanceActivityMode, 'expanded');
    expect(config.appearanceCodeWrap, isFalse);
    expect(config.appearanceBrandLogos, isTrue);
    expect(config.toJson(), containsPair('appearanceDensity', 'compact'));
  });

  test('app config controller saves appearance preferences', () async {
    final store = _MemoryAppConfigStore();
    final container = ProviderContainer(
      overrides: [
        appConfigStoreProvider.overrideWithValue(store),
        initialAppConfigProvider.overrideWithValue(AppConfig.defaults),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(appConfigControllerProvider.notifier)
        .saveAppearance(
          theme: 'light',
          language: 'en',
          density: 'compact',
          activityMode: 'expanded',
          codeWrap: false,
          brandLogos: true,
        );

    expect(container.read(appConfigProvider).appearanceTheme, 'light');
    expect(store.saved?.appearanceDensity, 'compact');
    expect(store.saved?.appearanceBrandLogos, isTrue);
    expect(store.saved?.apiBaseUrl, AppConfig.defaultApiBaseUrl);
  });

  test(
    'file app config store ignores unsupported local directory on load',
    () async {
      final store = FileAppConfigStore(
        directoryProvider: () async => throw UnsupportedError('no directory'),
      );

      await expectLater(store.load(), completion(isNull));
    },
  );
}

class _MemoryAppConfigStore implements AppConfigStore {
  AppConfig? saved;

  @override
  Future<AppConfig?> load() async => saved;

  @override
  Future<void> save(AppConfig config) async {
    saved = config;
  }
}
