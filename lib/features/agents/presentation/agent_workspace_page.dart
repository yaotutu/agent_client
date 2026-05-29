import 'package:agent_client/features/agents/application/agent_controller.dart';
import 'package:agent_client/features/agents/presentation/agent_navigation_panel.dart';
import 'package:agent_client/features/agents/presentation/agent_side_rail.dart';
import 'package:agent_client/features/chat/presentation/chat_panel.dart';
import 'package:agent_client/features/files/presentation/files_panel.dart';
import 'package:agent_client/features/tasks/presentation/tasks_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _desktopMinWidth = 900.0;

class AgentWorkspacePage extends HookConsumerWidget {
  const AgentWorkspacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agent = ref.watch(currentAgentProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= _desktopMinWidth;

        return Scaffold(
          drawer: desktop
              ? null
              : const Drawer(
                  child: AgentNavigationPanel(closeAfterSelection: true),
                ),
          body: SafeArea(
            bottom: false,
            child: Row(
              children: [
                if (desktop) const AgentSideRail(),
                Expanded(
                  child: _AgentTabs(
                    agentId: agent.id,
                    agentName: agent.name,
                    showDrawerButton: !desktop,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AgentTabs extends HookConsumerWidget {
  const _AgentTabs({
    required this.agentId,
    required this.agentName,
    required this.showDrawerButton,
  });

  final String agentId;
  final String agentName;
  final bool showDrawerButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 3, keys: [agentId]);

    return Column(
      children: [
        if (showDrawerButton)
          _AgentHeader(
            agentName: agentName,
            showDrawerButton: showDrawerButton,
          ),
        Material(
          color: Colors.white,
          child: TabBar(
            key: const Key('agent-tab-bar'),
            controller: tabController,
            tabs: const [
              Tab(key: Key('agent-chat-tab'), text: 'Chat'),
              Tab(key: Key('agent-files-tab'), text: 'Files'),
              Tab(key: Key('agent-tasks-tab'), text: 'Tasks'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              ChatPanel(agentId: agentId),
              FilesPanel(agentId: agentId),
              TasksPanel(agentId: agentId),
            ],
          ),
        ),
      ],
    );
  }
}

class _AgentHeader extends StatelessWidget {
  const _AgentHeader({required this.agentName, required this.showDrawerButton});

  final String agentName;
  final bool showDrawerButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E7EC))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (showDrawerButton)
            Builder(
              builder: (context) {
                return IconButton(
                  key: const Key('agent-navigation-button'),
                  tooltip: 'Agents',
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),
          Expanded(
            child: KeyedSubtree(
              key: const Key('current-agent-title'),
              child: Text(
                agentName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
