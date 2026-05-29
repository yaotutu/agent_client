import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/domain/agent_control_models.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final agentGitRepositoryProvider = Provider<AgentGitRepository>((ref) {
  return AgentGitRepository(ref.watch(agentControlApiClientProvider));
});

final agentGitStatusProvider = FutureProvider.family<GitStatus, String>((
  ref,
  agentName,
) {
  return ref.watch(agentGitRepositoryProvider).status(agentName);
});

class AgentGitRepository {
  const AgentGitRepository(this._api);

  final AgentControlApi _api;

  Future<GitStatus> status(String agentName) {
    return _api.getGitStatus(agentName);
  }

  Future<GitDiff> diff({required String agentName, String path = '.'}) {
    return _api.getGitDiff(agentName: agentName, path: path);
  }
}
