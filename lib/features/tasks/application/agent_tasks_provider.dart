import 'package:agent_client/features/chat/application/chat_controller.dart';
import 'package:agent_client/features/tasks/domain/agent_task_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final agentTasksProvider = Provider.family<List<AgentTaskItem>, String>((
  ref,
  agentId,
) {
  final chatState = ref.watch(chatControllerProvider(agentId));
  final tasks = <AgentTaskItem>[];

  if (chatState.goalStatus case final status?) {
    tasks.add(
      AgentTaskItem(
        title: 'Goal status',
        status: status == 'running'
            ? AgentTaskStatus.inProgress
            : AgentTaskStatus.done,
        dueLabel: status,
        detail: 'Backend goal state is $status.',
      ),
    );
  }

  if (chatState.reasoningText case final reasoning?) {
    tasks.add(
      AgentTaskItem(
        title: 'Reasoning',
        status: AgentTaskStatus.inProgress,
        dueLabel: 'Active',
        detail: reasoning,
      ),
    );
  }

  if (chatState.progressText case final progress?) {
    tasks.add(
      AgentTaskItem(
        title: 'Progress',
        status: AgentTaskStatus.inProgress,
        dueLabel: 'Active',
        detail: progress,
      ),
    );
  }

  if (chatState.toolHintText case final toolHint?) {
    tasks.add(
      AgentTaskItem(
        title: 'Tool activity',
        status: AgentTaskStatus.inProgress,
        dueLabel: 'Active',
        detail: toolHint,
      ),
    );
  }

  if (chatState.goalState case final goalState?) {
    tasks.add(
      AgentTaskItem(
        title: 'Goal state',
        status: AgentTaskStatus.inProgress,
        dueLabel: 'Live',
        detail: goalState.toString(),
      ),
    );
  }

  if (tasks.isEmpty) {
    return const [
      AgentTaskItem(
        title: 'No active task',
        status: AgentTaskStatus.done,
        dueLabel: 'Idle',
        detail: 'The backend has not reported active goal or tool state.',
      ),
    ];
  }
  return tasks;
});
