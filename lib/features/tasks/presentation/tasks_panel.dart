import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:agent_client/features/tasks/application/agent_tasks_provider.dart';
import 'package:agent_client/features/tasks/domain/agent_task_item.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TasksPanel extends ConsumerWidget {
  const TasksPanel({super.key, required this.agentId});

  final String agentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(agentTasksProvider(agentId));

    return ColoredBox(
      color: AppThemeTokens.workspace,
      child: ListView.separated(
        key: const Key('agent-tasks-list'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: tasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return _TaskRow(task: tasks[index]);
        },
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final AgentTaskItem task;

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(task.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppThemeTokens.panel,
        border: Border.all(color: AppThemeTokens.border),
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: colors.$1, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(
                      label: _statusLabel(task.status),
                      color: colors.$2,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  task.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppThemeTokens.mutedText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: AppThemeTokens.mutedText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.dueLabel,
                      style: const TextStyle(
                        color: AppThemeTokens.mutedText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(AgentTaskStatus status) {
    return switch (status) {
      AgentTaskStatus.todo => 'Todo',
      AgentTaskStatus.inProgress => 'In progress',
      AgentTaskStatus.blocked => 'Blocked',
      AgentTaskStatus.done => 'Done',
    };
  }

  (Color, Color) _statusColors(AgentTaskStatus status) {
    return switch (status) {
      AgentTaskStatus.todo => (
        AppThemeTokens.mutedText,
        const Color(0xFFF2F4F7),
      ),
      AgentTaskStatus.inProgress => (
        AppThemeTokens.brand,
        AppThemeTokens.brandSoft,
      ),
      AgentTaskStatus.blocked => (
        AppThemeTokens.dangerText,
        AppThemeTokens.dangerSoft,
      ),
      AgentTaskStatus.done => (
        AppThemeTokens.success,
        AppThemeTokens.successSoft,
      ),
    };
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
