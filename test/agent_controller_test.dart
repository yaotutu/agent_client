import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/domain/agent_control_models.dart';
import 'package:agent_client/features/agents/application/agent_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test(
    'createAgent creates through backend, refreshes list, and selects it',
    () async {
      final api = _FakeAgentControlApi([_agentSummary('nanobot')]);
      final container = ProviderContainer(
        overrides: [agentControlApiClientProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      expect(
        (await container.read(agentsProvider.future)).single.id,
        'nanobot',
      );

      await container
          .read(currentAgentIdProvider.notifier)
          .createAgent(name: 'reviewer', description: '代码审查助手');

      final agents = await container.read(agentsProvider.future);
      expect(api.createdName, 'reviewer');
      expect(api.createdDescription, '代码审查助手');
      expect(agents.map((agent) => agent.id), contains('reviewer'));
      expect(container.read(currentAgentIdProvider), 'reviewer');
    },
  );

  test(
    'deleteAgent deletes through backend and selects the first remaining agent',
    () async {
      final api = _FakeAgentControlApi([
        _agentSummary('nanobot'),
        _agentSummary('reviewer'),
      ]);
      final container = ProviderContainer(
        overrides: [agentControlApiClientProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      await container.read(agentsProvider.future);
      container.read(currentAgentIdProvider.notifier).selectAgent('reviewer');

      await container
          .read(currentAgentIdProvider.notifier)
          .deleteAgent('reviewer');

      final agents = await container.read(agentsProvider.future);
      expect(api.deletedName, 'reviewer');
      expect(agents.map((agent) => agent.id), ['nanobot']);
      expect(container.read(currentAgentIdProvider), 'nanobot');
    },
  );
}

AgentSummary _agentSummary(String name) {
  return AgentSummary(
    name: name,
    wsPort: 8760,
    gatewayPort: 18760,
    workspaceDir: '/workspace/$name',
    status: 'running',
    health: 'healthy',
    model: 'MiniMax-M2.7-highspeed',
    provider: 'minimax',
  );
}

class _FakeAgentControlApi extends Fake implements AgentControlApi {
  _FakeAgentControlApi(this._agents);

  final List<AgentSummary> _agents;
  String? createdName;
  String? createdDescription;
  String? deletedName;

  @override
  Future<AgentListResponse> listAgents() async {
    return AgentListResponse(object: 'list', data: List.of(_agents));
  }

  @override
  Future<CreateAgentResponse> createAgent({
    required String name,
    String? description,
  }) async {
    createdName = name;
    createdDescription = description;
    _agents.add(_agentSummary(name));
    return CreateAgentResponse(
      name: name,
      wsPort: 8761,
      gatewayPort: 18761,
      configPath: '/agents/$name/config.json',
      workspaceDir: '/workspace/$name',
      status: 'stopped',
      model: 'MiniMax-M2.7-highspeed',
      provider: 'minimax',
    );
  }

  @override
  Future<DeleteAgentResponse> deleteAgent(String agentName) async {
    deletedName = agentName;
    _agents.removeWhere((agent) => agent.name == agentName);
    return DeleteAgentResponse(deleted: true, name: agentName);
  }
}
