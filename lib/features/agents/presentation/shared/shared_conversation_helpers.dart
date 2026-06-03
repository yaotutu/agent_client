part of '../agent_workspace_page.dart';

enum _AgentMenuAction { avatar, delete }

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

String _messagePreviewText(ChatMessage message, String agentName) {
  final content = message.content.trim().replaceAll(RegExp(r'\s+'), ' ');
  final prefix = switch (message.role) {
    ChatRole.user => 'You',
    ChatRole.assistant => agentName,
    ChatRole.system => 'System',
    ChatRole.tool => 'Tool',
  };
  return content.isEmpty ? '$prefix: No messages yet' : '$prefix: $content';
}

String _agentFallbackSubtitle(Agent agent) {
  if (agent.description?.trim().isNotEmpty == true) {
    return agent.description!.trim();
  }
  if (agent.model?.trim().isNotEmpty == true) {
    return agent.model!.trim();
  }
  if (agent.workspace?.trim().isNotEmpty == true) {
    return agent.workspace!.trim();
  }
  return 'Ready to chat';
}

String _compactTime(DateTime? value) {
  if (value == null) {
    return '';
  }
  final local = value.toLocal();
  final now = DateTime.now();
  final sameDay =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  if (sameDay) {
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
  return '${local.month}/${local.day}';
}
