import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/domain/agent_control_models.dart';
import 'package:agent_client/features/settings/domain/agent_command.dart';
import 'package:agent_client/features/settings/domain/agent_settings.dart';
import 'package:agent_client/features/settings/domain/agent_settings_repository.dart';

class AgentControlSettingsRepository implements AgentSettingsRepository {
  const AgentControlSettingsRepository(this._api);

  final AgentControlApi _api;

  @override
  Future<List<AgentCommandItem>> commands(String agentName) async {
    final response = await _api.listCommands(agentName);
    return response.data.map(_toCommandItem).toList();
  }

  @override
  Future<AgentSettingsSnapshot> settings(String agentName) async {
    final settings = await _api.getSettings(agentName);
    return _toSettingsSnapshot(settings);
  }

  @override
  Future<AgentSettingsSnapshot> update({
    required String agentName,
    String? model,
    String? provider,
  }) async {
    final settings = await _api.updateSettings(
      agentName: agentName,
      model: model,
      provider: provider,
    );
    return _toSettingsSnapshot(settings);
  }

  AgentCommandItem _toCommandItem(AgentCommand command) {
    return AgentCommandItem(
      command: command.command,
      title: command.title,
      description: command.description,
      icon: command.icon,
      argHint: command.argHint,
    );
  }

  AgentSettingsSnapshot _toSettingsSnapshot(AgentSettings settings) {
    return AgentSettingsSnapshot(
      model: settings.agent.model,
      provider: settings.agent.provider,
      resolvedProvider: settings.agent.resolvedProvider,
      hasApiKey: settings.agent.hasApiKey,
      providers: settings.providers.map(_toProviderSettingsItem).toList(),
      requiresRestart: settings.requiresRestart,
    );
  }

  AgentProviderSettingsItem _toProviderSettingsItem(
    AgentProviderSettings provider,
  ) {
    return AgentProviderSettingsItem(
      name: provider.name,
      label: provider.label,
      configured: provider.configured,
      models: provider.models,
      apiKeyHint: provider.apiKeyHint,
      apiBase: provider.apiBase,
      defaultApiBase: provider.defaultApiBase,
    );
  }
}
