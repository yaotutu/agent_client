import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const defaultAgents = <Agent>[
  Agent(id: 'agent-general', name: 'General Agent'),
  Agent(id: 'agent-research', name: 'Research Agent'),
  Agent(id: 'agent-ops', name: 'Ops Agent', status: AgentStatus.busy),
];

final agentsProvider = Provider<List<Agent>>((ref) => defaultAgents);

final currentAgentIdProvider = NotifierProvider<CurrentAgentController, String>(
  CurrentAgentController.new,
);

final currentAgentProvider = Provider<Agent>((ref) {
  final currentId = ref.watch(currentAgentIdProvider);
  final agents = ref.watch(agentsProvider);

  return agents.firstWhere(
    (agent) => agent.id == currentId,
    orElse: () => agents.first,
  );
});

class CurrentAgentController extends Notifier<String> {
  @override
  String build() => defaultAgents.first.id;

  void selectAgent(String agentId) {
    final exists = ref.read(agentsProvider).any((agent) => agent.id == agentId);
    if (exists) {
      state = agentId;
    }
  }
}
