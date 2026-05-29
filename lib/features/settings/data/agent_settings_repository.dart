import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/domain/agent_control_models.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final agentSettingsRepositoryProvider = Provider<AgentSettingsRepository>((
  ref,
) {
  return AgentSettingsRepository(ref.watch(agentControlApiClientProvider));
});

final agentCommandsProvider = FutureProvider.family<List<AgentCommand>, String>(
  (ref, agentName) async {
    final response = await ref
        .watch(agentSettingsRepositoryProvider)
        .commands(agentName);
    return response.data;
  },
);

final agentSettingsProvider = FutureProvider.family<AgentSettings, String>((
  ref,
  agentName,
) {
  return ref.watch(agentSettingsRepositoryProvider).settings(agentName);
});

class AgentSettingsRepository {
  const AgentSettingsRepository(this._api);

  final AgentControlApi _api;

  Future<AgentCommandListResponse> commands(String agentName) {
    return _api.listCommands(agentName);
  }

  Future<AgentSettings> settings(String agentName) {
    return _api.getSettings(agentName);
  }

  Future<AgentSettings> update({
    required String agentName,
    String? model,
    String? provider,
  }) {
    return _api.updateSettings(
      agentName: agentName,
      model: model,
      provider: provider,
    );
  }
}
