import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/domain/agent_control_models.dart';
import 'package:agent_client/features/git/domain/agent_git_repository.dart';
import 'package:agent_client/features/git/domain/agent_git_status.dart';

class AgentControlGitRepository implements AgentGitRepository {
  const AgentControlGitRepository(this._api);

  final AgentControlApi _api;

  @override
  Future<AgentGitStatus> status(String agentName) async {
    final status = await _api.getGitStatus(agentName);
    return AgentGitStatus(
      isRepo: status.isRepo,
      branch: status.branch,
      upstream: status.upstream,
      ahead: status.ahead,
      behind: status.behind,
      clean: status.clean,
      items: status.data.map(_toStatusItem).toList(),
    );
  }

  @override
  Future<AgentGitDiff> diff({
    required String agentName,
    String path = '.',
  }) async {
    final diff = await _api.getGitDiff(agentName: agentName, path: path);
    return AgentGitDiff(isRepo: diff.isRepo, path: diff.path, diff: diff.diff);
  }

  AgentGitStatusItem _toStatusItem(GitStatusItem item) {
    return AgentGitStatusItem(
      path: item.path,
      status: item.status,
      from: item.from,
      index: item.index,
      worktree: item.worktree,
    );
  }
}
