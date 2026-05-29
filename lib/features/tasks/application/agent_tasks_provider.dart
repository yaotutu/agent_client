import 'package:agent_client/features/tasks/domain/agent_task_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final agentTasksProvider = Provider.family<List<AgentTaskItem>, String>((
  ref,
  agentId,
) {
  return switch (agentId) {
    'agent-research' => _researchTasks,
    'agent-ops' => _opsTasks,
    _ => _generalTasks,
  };
});

const _generalTasks = [
  AgentTaskItem(
    title: 'Draft static chat UI',
    status: AgentTaskStatus.inProgress,
    dueLabel: 'Today',
    detail: 'Make the chat screen reviewable without service data.',
  ),
  AgentTaskItem(
    title: 'Review file tab density',
    status: AgentTaskStatus.todo,
    dueLabel: 'Today',
    detail: 'Check row spacing on phone and desktop widths.',
  ),
  AgentTaskItem(
    title: 'Prepare API handoff notes',
    status: AgentTaskStatus.blocked,
    dueLabel: 'Next',
    detail: 'Waiting for final server event examples.',
  ),
];

const _researchTasks = [
  AgentTaskItem(
    title: 'Collect source summaries',
    status: AgentTaskStatus.inProgress,
    dueLabel: 'Today',
    detail: 'Group notes by product, layout, and integration concerns.',
  ),
  AgentTaskItem(
    title: 'Mark evidence quality',
    status: AgentTaskStatus.todo,
    dueLabel: 'Tomorrow',
    detail: 'Add confidence labels before service integration begins.',
  ),
];

const _opsTasks = [
  AgentTaskItem(
    title: 'Validate release checklist',
    status: AgentTaskStatus.done,
    dueLabel: 'Done',
    detail: 'Static data mode keeps the app runnable offline.',
  ),
];
