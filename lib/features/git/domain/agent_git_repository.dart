import 'package:agent_client/features/git/domain/agent_git_status.dart';

abstract interface class AgentGitRepository {
  Future<AgentGitStatus> status(String agentName);

  Future<AgentGitDiff> diff({required String agentName, String path = '.'});
}
