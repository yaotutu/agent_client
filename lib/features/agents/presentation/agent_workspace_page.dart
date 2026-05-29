import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:agent_client/features/agents/application/agent_controller.dart';
import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:agent_client/features/agents/presentation/agent_navigation_panel.dart';
import 'package:agent_client/features/agents/presentation/agent_side_rail.dart';
import 'package:agent_client/features/chat/presentation/chat_panel.dart';
import 'package:agent_client/features/files/presentation/files_panel.dart';
import 'package:agent_client/features/tasks/presentation/tasks_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _mediumMinWidth = 600.0;
const _wideMinWidth = 840.0;

class AgentWorkspacePage extends HookConsumerWidget {
  const AgentWorkspacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agent = ref.watch(currentAgentProvider);
    final currentAgentId = ref.watch(currentAgentIdProvider);

    return agent.when(
      data: (agent) => _WorkspaceScaffold(agent: agent),
      loading: () => _WorkspaceScaffold(agent: fallbackAgent(currentAgentId)),
      error: (_, _) => _WorkspaceScaffold(agent: fallbackAgent(currentAgentId)),
    );
  }
}

class _WorkspaceScaffold extends StatelessWidget {
  const _WorkspaceScaffold({required this.agent});

  final Agent agent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < _mediumMinWidth;
        final isWide = width >= _wideMinWidth;

        return Scaffold(
          drawer: isCompact
              ? const Drawer(
                  child: AgentNavigationPanel(
                    closeAfterSelection: true,
                    showTitle: true,
                  ),
                )
              : null,
          body: SafeArea(
            bottom: false,
            child: Row(
              children: [
                if (!isCompact)
                  isWide ? const AgentSideRail() : const AgentCompactRail(),
                Expanded(
                  child: _AgentTabs(
                    agentId: agent.id,
                    agentTitle: _agentTitle(agent),
                    showHeader: !isWide,
                    showMenuButton: isCompact,
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
    required this.agentTitle,
    required this.showHeader,
    required this.showMenuButton,
  });

  final String agentId;
  final String agentTitle;
  final bool showHeader;
  final bool showMenuButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 3, keys: [agentId]);

    return Column(
      children: [
        if (showHeader)
          _AgentHeader(title: agentTitle, showMenuButton: showMenuButton),
        Material(
          color: AppThemeTokens.panel,
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
  const _AgentHeader({required this.title, required this.showMenuButton});

  final String title;
  final bool showMenuButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppThemeTokens.panel,
        border: Border(bottom: BorderSide(color: AppThemeTokens.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (showMenuButton)
            Builder(
              builder: (context) {
                return IconButton(
                  key: const Key('agent-navigation-button'),
                  tooltip: 'Agents',
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                );
              },
            )
          else
            const SizedBox(width: 8),
          Expanded(
            child: KeyedSubtree(
              key: const Key('current-agent-title'),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
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

String _agentTitle(Agent agent) {
  return agent.name;
}
