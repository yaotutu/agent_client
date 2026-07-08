import 'package:agent_client/app/nanobot_client_app.dart';
import 'package:agent_client/core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configStore = createDefaultAppConfigStore();
  final initialConfig = await configStore.load() ?? AppConfig.defaults;

  runApp(
    ProviderScope(
      overrides: [
        appConfigStoreProvider.overrideWithValue(configStore),
        initialAppConfigProvider.overrideWithValue(initialConfig),
      ],
      child: const NanobotClientApp(),
    ),
  );
}
