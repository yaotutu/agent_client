import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:agent_client/features/agents/application/agent_controller.dart';
import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:agent_client/features/agents/domain/agent_avatar.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> showAgentAvatarEditorDialog(
  BuildContext context,
  WidgetRef ref,
  Agent agent,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _AgentAvatarEditorDialog(agent: agent),
  );
}

class _AgentAvatarEditorDialog extends ConsumerStatefulWidget {
  const _AgentAvatarEditorDialog({required this.agent});

  final Agent agent;

  @override
  ConsumerState<_AgentAvatarEditorDialog> createState() =>
      _AgentAvatarEditorDialogState();
}

class _AgentAvatarEditorDialogState
    extends ConsumerState<_AgentAvatarEditorDialog> {
  late AgentAvatarOption _selectedAvatar;
  String? _errorText;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedAvatar = _avatarFor(widget.agent.avatarUrl);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Change ${widget.agent.name} avatar'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgentAvatarPicker(
              selectedAvatar: _selectedAvatar,
              enabled: !_submitting,
              onSelected: (avatar) {
                setState(() => _selectedAvatar = avatar);
              },
            ),
            if (_errorText case final error?)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
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
          key: const Key('agent-avatar-save-button'),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await ref
          .read(currentAgentIdProvider.notifier)
          .updateAgentAvatar(
            widget.agent,
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
}

class AgentAvatarPicker extends StatelessWidget {
  const AgentAvatarPicker({
    super.key,
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

AgentAvatarOption _avatarFor(String? avatarUrl) {
  for (final avatar in AgentAvatarOptions.defaults) {
    if (avatar.assetPath == avatarUrl) {
      return avatar;
    }
  }
  return AgentAvatarOptions.defaults.first;
}
