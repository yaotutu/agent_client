import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/data/agent_control_settings_repository.dart';
import 'package:agent_client/features/settings/domain/agent_command.dart';
import 'package:agent_client/features/settings/domain/agent_settings.dart';
import 'package:agent_client/features/settings/domain/agent_settings_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final agentSettingsRepositoryProvider = Provider<AgentSettingsRepository>((
  ref,
) {
  return AgentControlSettingsRepository(
    ref.watch(agentControlApiClientProvider),
  );
});

final agentCommandsProvider =
    FutureProvider.family<List<AgentCommandItem>, String>((ref, agentName) {
      return ref.watch(agentSettingsRepositoryProvider).commands(agentName);
    });

final agentSettingsProvider =
    FutureProvider.family<AgentSettingsSnapshot, String>((ref, agentName) {
      return ref.watch(agentSettingsRepositoryProvider).settings(agentName);
    });
