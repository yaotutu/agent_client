import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/data/agent_control_git_repository.dart';
import 'package:agent_client/features/git/domain/agent_git_repository.dart';
import 'package:agent_client/features/git/domain/agent_git_status.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final agentGitRepositoryProvider = Provider<AgentGitRepository>((ref) {
  return AgentControlGitRepository(ref.watch(agentControlApiClientProvider));
});

final agentGitStatusProvider = FutureProvider.family<AgentGitStatus, String>((
  ref,
  agentName,
) {
  return ref.watch(agentGitRepositoryProvider).status(agentName);
});
