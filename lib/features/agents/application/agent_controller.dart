import 'package:agent_client/features/agents/data/agent_registry_repository.dart';
import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:agent_client/features/chat/application/chat_controller.dart';
import 'package:agent_client/features/chat/application/chat_sessions_controller.dart';
import 'package:agent_client/features/chat/data/chat_cache_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final agentsProvider = FutureProvider<List<Agent>>((ref) async {
  return ref.watch(agentRegistryRepositoryProvider).listAgents();
});

final currentAgentIdProvider = NotifierProvider<CurrentAgentController, String>(
  CurrentAgentController.new,
);

final currentAgentProvider = FutureProvider<Agent>((ref) async {
  final currentId = ref.watch(currentAgentIdProvider);
  final agents = await ref.watch(agentsProvider.future).catchError((_) {
    return <Agent>[];
  });
  if (agents.isEmpty) {
    return fallbackAgent(currentId);
  }

  return agents.firstWhere(
    (agent) => agent.id == currentId,
    orElse: () => agents.first,
  );
});

class CurrentAgentController extends Notifier<String> {
  @override
  String build() => '';

  void selectAgent(String agentId) {
    state = agentId;
  }

  Future<void> createAgent({required String name, String? description}) async {
    final trimmedName = name.trim();
    final trimmedDescription = description?.trim();
    final created = await ref
        .read(agentRegistryRepositoryProvider)
        .createAgent(
          name: trimmedName,
          description: trimmedDescription == null || trimmedDescription.isEmpty
              ? null
              : trimmedDescription,
        );

    state = created.id;
    ref.invalidate(agentsProvider);
    await ref.read(agentsProvider.future);
  }

  Future<void> deleteAgent(String agentId) async {
    final currentAgentId = await _effectiveCurrentAgentId();
    await ref.read(agentRegistryRepositoryProvider).deleteAgent(agentId);

    try {
      await ref.read(chatCacheStoreProvider).clearAgent(agentId);
    } finally {
      ref.invalidate(chatControllerProvider(agentId));
      ref.invalidate(chatSessionsProvider(agentId));
      ref.invalidate(agentsProvider);
      final remainingAgents = await ref.read(agentsProvider.future).catchError((
        _,
      ) {
        return <Agent>[];
      });

      if (currentAgentId == agentId) {
        state = remainingAgents.isEmpty ? '' : remainingAgents.first.id;
      }
    }
  }

  Future<String?> _effectiveCurrentAgentId() async {
    if (state.isNotEmpty) {
      return state;
    }
    final agents = await ref.read(agentsProvider.future).catchError((_) {
      return <Agent>[];
    });
    return agents.isEmpty ? null : agents.first.id;
  }
}

Agent fallbackAgent([String? selectedId]) {
  final id = selectedId == null || selectedId.isEmpty ? 'agent' : selectedId;
  return Agent(
    id: id,
    name: id == 'agent' ? 'Agent' : id,
    status: AgentStatus.offline,
    model: 'Backend offline',
  );
}
