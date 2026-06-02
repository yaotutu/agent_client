part of 'agent_workspace_page.dart';

class _ConversationListPane extends ConsumerWidget {
  const _ConversationListPane({
    required this.agents,
    required this.currentAgentId,
    required this.everyoneSelected,
    required this.showSelection,
    required this.showSettingsButton,
    required this.onSelectEveryone,
    required this.onSelectAgent,
  });

  final AsyncValue<List<Agent>> agents;
  final String currentAgentId;
  final bool everyoneSelected;
  final bool showSelection;
  final bool showSettingsButton;
  final VoidCallback onSelectEveryone;
  final ValueChanged<Agent> onSelectAgent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      key: const Key('agent-conversation-list'),
      color: _conversationListColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Conversations',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppThemeTokens.headingText,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('agent-conversation-create-button'),
                  tooltip: 'Create agent',
                  onPressed: () =>
                      AgentNavigationPanel.openCreateAgentDialog(context),
                  icon: const Icon(Icons.add, size: 22),
                ),
                if (showSettingsButton)
                  IconButton(
                    key: const Key('global-settings-button'),
                    tooltip: 'Settings',
                    onPressed: () => openAppSettingsPage(context),
                    icon: const Icon(Icons.settings_outlined),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: SizedBox(
              height: 44,
              child: TextField(
                key: const Key('agent-conversation-search-field'),
                readOnly: true,
                decoration: const InputDecoration(
                  hintText: 'Find a conversation or agent',
                  prefixIcon: Icon(Icons.search, size: 20),
                  suffixText: '⌘K',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _ConversationFilters(),
          const SizedBox(height: 16),
          Expanded(
            child: agents.when(
              data: (agents) => _ConversationRows(
                agents: agents,
                currentAgentId: currentAgentId,
                everyoneSelected: everyoneSelected,
                showSelection: showSelection,
                onSelectEveryone: onSelectEveryone,
                onSelectAgent: onSelectAgent,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ConversationError(
                message: error.toString(),
                onRetry: () => ref.invalidate(agentsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationFilters extends StatelessWidget {
  const _ConversationFilters();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: const [
          _FilterChip(label: 'All', selected: true),
          SizedBox(width: 8),
          _FilterChip(label: 'Unread'),
          SizedBox(width: 8),
          _FilterChip(label: 'Agents'),
          SizedBox(width: 8),
          _FilterChip(label: 'Groups'),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected
              ? AppThemeTokens.brandPressed
              : AppThemeTokens.mutedText,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      selected: selected,
      onSelected: (_) {},
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ConversationRows extends StatelessWidget {
  const _ConversationRows({
    required this.agents,
    required this.currentAgentId,
    required this.everyoneSelected,
    required this.showSelection,
    required this.onSelectEveryone,
    required this.onSelectAgent,
  });

  final List<Agent> agents;
  final String currentAgentId;
  final bool everyoneSelected;
  final bool showSelection;
  final VoidCallback onSelectEveryone;
  final ValueChanged<Agent> onSelectAgent;

  @override
  Widget build(BuildContext context) {
    if (agents.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        children: [
          _EveryoneConversationTile(
            selected: showSelection && everyoneSelected,
            onTap: onSelectEveryone,
          ),
          const SizedBox(height: 12),
          const _EmptyAgentList(),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      itemCount: agents.length + 2,
      separatorBuilder: (_, index) {
        if (index == 0) {
          return const SizedBox(height: 14);
        }
        return const SizedBox(height: 6);
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _SectionLabel('PINNED');
        }
        if (index == 1) {
          return _EveryoneConversationTile(
            selected: showSelection && everyoneSelected,
            onTap: onSelectEveryone,
          );
        }

        final agent = agents[index - 2];
        return _AgentConversationTile(
          agent: agent,
          selected:
              showSelection && !everyoneSelected && agent.id == currentAgentId,
          onTap: () => onSelectAgent(agent),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: AppThemeTokens.subtleText,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _EveryoneConversationTile extends StatelessWidget {
  const _EveryoneConversationTile({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ConversationSurface(
      key: const Key('agent-conversation-everyone'),
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          const _GroupAvatar(),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Everyone',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppThemeTokens.headingText,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Team chat placeholder',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppThemeTokens.mutedText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Soon',
            style: TextStyle(color: AppThemeTokens.subtleText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AgentConversationTile extends ConsumerWidget {
  const _AgentConversationTile({
    required this.agent,
    required this.selected,
    required this.onTap,
  });

  final Agent agent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewMessage = switch (ref.watch(
      latestCachedChatMessageProvider(agent.id),
    )) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final subtitle = previewMessage == null
        ? _agentFallbackSubtitle(agent)
        : _messagePreviewText(previewMessage, agent.name);

    return KeyedSubtree(
      key: Key('agent-conversation-agent-${agent.id}'),
      child: _ConversationSurface(
        key: Key('agent-tile-${agent.id}'),
        selected: selected,
        onTap: onTap,
        child: Row(
          children: [
            AgentAvatarView(agent: agent, selected: selected),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          agent.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppThemeTokens.headingText,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      if (_compactTime(previewMessage?.createdAt)
                          case final label when label.isNotEmpty)
                        Text(
                          label,
                          style: const TextStyle(
                            color: AppThemeTokens.subtleText,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: const TextStyle(
                      color: AppThemeTokens.mutedText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            _AgentTileActions(agent: agent, selected: selected),
          ],
        ),
      ),
    );
  }
}

class _ConversationSurface extends StatelessWidget {
  const _ConversationSurface({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppThemeTokens.selected : Colors.transparent,
      borderRadius: BorderRadius.circular(AppThemeTokens.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppThemeTokens.radius),
            border: selected
                ? Border.all(color: AppThemeTokens.selectedBorder)
                : Border.all(color: Colors.transparent),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        children: const [
          Positioned(
            left: 0,
            top: 2,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppThemeTokens.brandSofter,
              foregroundColor: AppThemeTokens.brandPressed,
              child: Text('A'),
            ),
          ),
          Positioned(
            right: 2,
            top: 0,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppThemeTokens.warningSoft,
              foregroundColor: AppThemeTokens.warning,
              child: Text('N'),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 0,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppThemeTokens.workspace,
              foregroundColor: AppThemeTokens.mutedText,
              child: Text('B'),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 2,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppThemeTokens.panel,
              foregroundColor: AppThemeTokens.headingText,
              child: Text('I'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentTileActions extends ConsumerWidget {
  const _AgentTileActions({required this.agent, required this.selected});

  final Agent agent;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selected)
          const Icon(
            Icons.check_circle,
            size: 18,
            color: AppThemeTokens.brandPressed,
          ),
        PopupMenuButton<_AgentMenuAction>(
          key: Key('agent-menu-${agent.id}'),
          tooltip: 'Agent actions',
          onSelected: (action) {
            switch (action) {
              case _AgentMenuAction.avatar:
                showAgentAvatarEditorDialog(context, ref, agent);
              case _AgentMenuAction.delete:
                _confirmDeleteAgent(context, ref, agent);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _AgentMenuAction.avatar,
              child: Row(
                children: [
                  Icon(Icons.account_circle_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Change avatar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: _AgentMenuAction.delete,
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18),
                  SizedBox(width: 8),
                  Text('Delete agent'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyAgentList extends StatelessWidget {
  const _EmptyAgentList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppThemeTokens.panel,
        border: Border.all(color: AppThemeTokens.border),
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
      ),
      child: const Row(
        children: [
          CircleAvatar(child: Icon(Icons.smart_toy_outlined)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No agents yet. Create an agent to start chatting.',
              style: TextStyle(color: AppThemeTokens.mutedText),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationError extends StatelessWidget {
  const _ConversationError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        _EveryoneConversationTile(selected: false, onTap: () {}),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppThemeTokens.dangerSoft,
            border: Border.all(color: AppThemeTokens.dangerBorder),
            borderRadius: BorderRadius.circular(AppThemeTokens.radius),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: AppThemeTokens.dangerText,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppThemeTokens.dangerText),
                ),
              ),
              IconButton(
                tooltip: 'Retry',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
