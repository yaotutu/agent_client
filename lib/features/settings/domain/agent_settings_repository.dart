import 'package:agent_client/features/settings/domain/agent_command.dart';
import 'package:agent_client/features/settings/domain/agent_settings.dart';

abstract interface class AgentSettingsRepository {
  Future<List<AgentCommandItem>> commands(String agentName);

  Future<AgentSettingsSnapshot> settings(String agentName);

  Future<AgentSettingsSnapshot> update({
    required String agentName,
    String? model,
    String? provider,
  });
}
