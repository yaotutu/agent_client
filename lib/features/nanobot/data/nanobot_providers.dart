import 'package:agent_client/core/config/app_config.dart';
import 'package:agent_client/features/nanobot/data/nanobot_api_client.dart';
import 'package:agent_client/features/nanobot/data/nanobot_repository.dart';
import 'package:agent_client/features/nanobot/data/nanobot_ws_client.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_config.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final nanobotConfigProvider = Provider<NanobotConfig>((ref) {
  return NanobotConfig.fromAppConfig(ref.watch(appConfigProvider));
});

final nanobotApiClientProvider = Provider<NanobotApiClient>((ref) {
  return NanobotApiClient(config: ref.watch(nanobotConfigProvider));
});

final nanobotWsClientProvider = Provider<NanobotWsClient>((ref) {
  final api = ref.watch(nanobotApiClientProvider);
  final client = NanobotWsClient(
    config: ref.watch(nanobotConfigProvider),
    bootstrap: api.bootstrap,
  );
  ref.onDispose(() {
    client.dispose();
  });
  return client;
});

final nanobotRepositoryProvider = Provider<NanobotRepositoryPort>((ref) {
  return NanobotRepository(
    api: ref.watch(nanobotApiClientProvider),
    ws: ref.watch(nanobotWsClientProvider),
  );
});
