import 'package:agent_client/features/agents/application/agent_controller.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AgentNavigationPanel extends ConsumerWidget {
  const AgentNavigationPanel({super.key, this.closeAfterSelection = false});

  final bool closeAfterSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agents = ref.watch(agentsProvider);
    final currentAgentId = ref.watch(currentAgentIdProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Text(
              'Agent Navigator',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: agents.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final agent = agents[index];
                final selected = agent.id == currentAgentId;

                return ListTile(
                  selected: selected,
                  selectedTileColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  leading: CircleAvatar(
                    radius: 16,
                    child: Text(agent.name.characters.first),
                  ),
                  title: Text(agent.name),
                  trailing: selected ? const Icon(Icons.check) : null,
                  onTap: () {
                    ref
                        .read(currentAgentIdProvider.notifier)
                        .selectAgent(agent.id);
                    if (closeAfterSelection) {
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
