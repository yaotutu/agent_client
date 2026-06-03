part of '../agent_workspace_page.dart';

class _TabletAgentWorkspace extends ConsumerStatefulWidget {
  const _TabletAgentWorkspace({
    required this.agents,
    required this.currentAgentId,
  });

  final AsyncValue<List<Agent>> agents;
  final String currentAgentId;

  @override
  ConsumerState<_TabletAgentWorkspace> createState() =>
      _TabletAgentWorkspaceState();
}

class _TabletAgentWorkspaceState extends ConsumerState<_TabletAgentWorkspace> {
  var _showEveryone = false;

  @override
  Widget build(BuildContext context) {
    final availableAgents = _agentsFrom(widget.agents);
    final selectedAgent =
        _selectedAgent(availableAgents, widget.currentAgentId) ??
        fallbackAgent(widget.currentAgentId);
    final effectiveAgentId = selectedAgent.id;

    return KeyedSubtree(
      key: const Key('agent-tablet-workspace'),
      child: Row(
        key: const Key('agent-im-shell'),
        children: [
          const _SharedWorkspaceRail(),
          SizedBox(
            width: AdaptiveLayoutPolicy.tabletConversationListWidth,
            child: _SharedConversationListPane(
              agents: widget.agents,
              currentAgentId: effectiveAgentId,
              everyoneSelected: _showEveryone,
              showSelection: true,
              showSettingsButton: false,
              onSelectEveryone: () {
                setState(() => _showEveryone = true);
              },
              onSelectAgent: (agent) {
                setState(() => _showEveryone = false);
                ref.read(currentAgentIdProvider.notifier).selectAgent(agent.id);
              },
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: _showEveryone
                ? const _SharedEveryoneDetail()
                : _SharedAgentChatDetail(
                    agent: selectedAgent,
                    chatPanel: TabletChatPanel(agent: selectedAgent),
                  ),
          ),
        ],
      ),
    );
  }
}
