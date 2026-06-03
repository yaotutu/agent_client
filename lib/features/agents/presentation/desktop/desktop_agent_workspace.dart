part of '../agent_workspace_page.dart';

class _DesktopAgentWorkspace extends StatelessWidget {
  const _DesktopAgentWorkspace({
    required this.agents,
    required this.currentAgentId,
  });

  final AsyncValue<List<Agent>> agents;
  final String currentAgentId;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const Key('agent-desktop-workspace'),
      child: _TabletAgentWorkspace(
        agents: agents,
        currentAgentId: currentAgentId,
      ),
    );
  }
}
