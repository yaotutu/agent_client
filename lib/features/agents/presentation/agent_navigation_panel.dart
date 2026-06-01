import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:agent_client/features/agents/application/agent_controller.dart';
import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:agent_client/features/agents/domain/agent_avatar.dart';
import 'package:agent_client/features/agents/presentation/agent_avatar_view.dart';
import 'package:agent_client/features/settings/presentation/app_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AgentNavigationPanel extends ConsumerWidget {
  const AgentNavigationPanel({
    super.key,
    this.closeAfterSelection = false,
    this.showTitle = false,
  });

  final bool closeAfterSelection;
  final bool showTitle;

  static void openCreateAgentDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _CreateAgentDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agents = ref.watch(agentsProvider);
    final currentAgentId = ref.watch(currentAgentIdProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, showTitle ? 18 : 12, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    showTitle ? 'Agent Navigator' : 'Agents',
                    style: TextStyle(
                      fontSize: showTitle ? 18 : 13,
                      fontWeight: FontWeight.w700,
                      color: showTitle
                          ? const Color(0xFF101828)
                          : const Color(0xFF344054),
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('agent-create-button'),
                  tooltip: 'Create agent',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => openCreateAgentDialog(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: agents.when(
              data: (agents) {
                if (agents.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(12),
                    children: const [
                      ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          child: Icon(Icons.smart_toy_outlined, size: 18),
                        ),
                        title: Text('No agents yet'),
                        subtitle: Text('Create an agent to start.'),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: agents.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final agent = agents[index];
                    final effectiveAgentId = currentAgentId.isEmpty
                        ? agents.first.id
                        : currentAgentId;
                    final selected = agent.id == effectiveAgentId;

                    return ListTile(
                      key: Key('agent-tile-${agent.id}'),
                      selected: selected,
                      selectedTileColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      leading: AgentAvatarView(
                        agent: agent,
                        selected: selected,
                        radius: 16,
                      ),
                      title: Text(
                        agent.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                      trailing: _AgentTileActions(
                        agent: agent,
                        selected: selected,
                      ),
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
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  ListTile(
                    selected: true,
                    selectedTileColor: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    leading: const CircleAvatar(
                      radius: 16,
                      child: Icon(Icons.cloud_off, size: 18),
                    ),
                    title: const Text('Backend offline'),
                    subtitle: Text(
                      error.toString(),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: 'Retry',
                      icon: const Icon(Icons.refresh),
                      onPressed: () => ref.invalidate(agentsProvider),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            key: const Key('global-settings-button'),
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              if (closeAfterSelection) {
                Navigator.of(context).pop();
              }
              openAppSettingsPage(context);
            },
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
        if (selected) const Icon(Icons.check),
        PopupMenuButton<_AgentAction>(
          key: Key('agent-menu-${agent.id}'),
          tooltip: 'Agent actions',
          onSelected: (action) {
            switch (action) {
              case _AgentAction.delete:
                _confirmDeleteAgent(context, ref, agent);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _AgentAction.delete,
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

enum _AgentAction { delete }

class _CreateAgentDialog extends ConsumerStatefulWidget {
  const _CreateAgentDialog();

  @override
  ConsumerState<_CreateAgentDialog> createState() => _CreateAgentDialogState();
}

class _CreateAgentDialogState extends ConsumerState<_CreateAgentDialog> {
  static final _agentNamePattern = RegExp(r'^[a-zA-Z0-9_-]{1,64}$');

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  AgentAvatarOption _selectedAvatar = AgentAvatarOptions.defaults.first;
  String? _errorText;
  var _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create agent'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('agent-create-name-field'),
              controller: _nameController,
              autofocus: true,
              enabled: !_submitting,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'code-reviewer',
                errorText: _errorText,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            _AgentAvatarPicker(
              selectedAvatar: _selectedAvatar,
              enabled: !_submitting,
              onSelected: (avatar) {
                setState(() => _selectedAvatar = avatar);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('agent-create-description-field'),
              controller: _descriptionController,
              enabled: !_submitting,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: '代码审查助手',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('agent-create-submit-button'),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final validationError = _validateAgentName(name);
    if (validationError != null) {
      setState(() => _errorText = validationError);
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await ref
          .read(currentAgentIdProvider.notifier)
          .createAgent(
            name: name,
            description: _descriptionController.text.trim(),
            avatarUrl: _selectedAvatar.assetPath,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorText = error.toString();
        });
      }
    }
  }

  String? _validateAgentName(String value) {
    if (value.isEmpty) {
      return 'Name is required';
    }
    if (!_agentNamePattern.hasMatch(value)) {
      return 'Use 1-64 letters, numbers, "-" or "_"';
    }
    return null;
  }
}

class _AgentAvatarPicker extends StatelessWidget {
  const _AgentAvatarPicker({
    required this.selectedAvatar,
    required this.enabled,
    required this.onSelected,
  });

  final AgentAvatarOption selectedAvatar;
  final bool enabled;
  final ValueChanged<AgentAvatarOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              'Avatar',
              style: TextStyle(
                color: AppThemeTokens.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final avatar in AgentAvatarOptions.defaults)
                _AgentAvatarOptionButton(
                  avatar: avatar,
                  selected: avatar.id == selectedAvatar.id,
                  enabled: enabled,
                  onSelected: onSelected,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgentAvatarOptionButton extends StatelessWidget {
  const _AgentAvatarOptionButton({
    required this.avatar,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final AgentAvatarOption avatar;
  final bool selected;
  final bool enabled;
  final ValueChanged<AgentAvatarOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: avatar.label,
      child: InkWell(
        key: Key('agent-avatar-option-${avatar.id}'),
        borderRadius: BorderRadius.circular(28),
        onTap: enabled ? () => onSelected(avatar) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 54,
          height: 54,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppThemeTokens.brand : AppThemeTokens.border,
              width: selected ? 3 : 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipOval(
                child: Image.asset(
                  avatar.assetPath,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
              if (selected)
                const Positioned(
                  right: -2,
                  bottom: -2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppThemeTokens.brand,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.check, color: Colors.white, size: 13),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmDeleteAgent(
  BuildContext context,
  WidgetRef ref,
  Agent agent,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete ${agent.name}?'),
      content: const Text(
        'This permanently deletes workspace files, SOUL.md, and session history.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('agent-delete-confirm-button'),
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true) {
    return;
  }

  try {
    await ref.read(currentAgentIdProvider.notifier).deleteAgent(agent.id);
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
