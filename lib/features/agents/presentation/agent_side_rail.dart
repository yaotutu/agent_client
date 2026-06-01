import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:agent_client/features/agents/application/agent_controller.dart';
import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:agent_client/features/agents/presentation/agent_avatar_view.dart';
import 'package:agent_client/features/agents/presentation/agent_navigation_panel.dart';
import 'package:agent_client/features/settings/presentation/app_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AgentSideRail extends StatelessWidget {
  const AgentSideRail({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('agent-side-rail'),
      width: AppThemeTokens.fullRailWidth,
      decoration: const BoxDecoration(
        color: AppThemeTokens.panel,
        border: Border(right: BorderSide(color: AppThemeTokens.border)),
      ),
      child: const Material(
        color: Colors.transparent,
        child: AgentNavigationPanel(),
      ),
    );
  }
}

class AgentCompactRail extends ConsumerWidget {
  const AgentCompactRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agents = ref.watch(agentsProvider);
    final currentAgentId = ref.watch(currentAgentIdProvider);

    return Container(
      key: const Key('agent-compact-rail'),
      width: AppThemeTokens.compactRailWidth,
      decoration: const BoxDecoration(
        color: AppThemeTokens.panel,
        border: Border(right: BorderSide(color: AppThemeTokens.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            IconButton.filledTonal(
              key: const Key('agent-compact-create-button'),
              tooltip: 'Create agent',
              onPressed: () =>
                  AgentNavigationPanel.openCreateAgentDialog(context),
              icon: const Icon(Icons.add, size: 20),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: agents.when(
                data: (agents) => _CompactAgentList(
                  agents: agents,
                  currentAgentId: currentAgentId,
                  onSelect: (agent) => ref
                      .read(currentAgentIdProvider.notifier)
                      .selectAgent(agent.id),
                ),
                loading: () => const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, _) => const Center(
                  child: Icon(
                    Icons.cloud_off_outlined,
                    color: AppThemeTokens.mutedText,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: IconButton(
                key: const Key('global-settings-button'),
                tooltip: 'Settings',
                onPressed: () => openAppSettingsPage(context),
                icon: const Icon(Icons.settings_outlined, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactAgentList extends StatelessWidget {
  const _CompactAgentList({
    required this.agents,
    required this.currentAgentId,
    required this.onSelect,
  });

  final List<Agent> agents;
  final String currentAgentId;
  final ValueChanged<Agent> onSelect;

  @override
  Widget build(BuildContext context) {
    if (agents.isEmpty) {
      return const Center(
        child: Icon(Icons.smart_toy_outlined, color: AppThemeTokens.mutedText),
      );
    }

    final effectiveAgentId = currentAgentId.isEmpty
        ? agents.first.id
        : currentAgentId;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      itemCount: agents.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final agent = agents[index];
        final selected = agent.id == effectiveAgentId;

        return Tooltip(
          message: agent.name,
          child: Material(
            color: selected ? AppThemeTokens.brandSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(AppThemeTokens.radius),
            child: InkWell(
              key: Key('agent-compact-tile-${agent.id}'),
              borderRadius: BorderRadius.circular(AppThemeTokens.radius),
              onTap: () => onSelect(agent),
              child: SizedBox(
                height: 52,
                child: Center(
                  child: AgentAvatarView(
                    agent: agent,
                    selected: selected,
                    radius: 18,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
