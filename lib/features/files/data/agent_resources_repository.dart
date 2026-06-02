import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/data/agent_control_resources_repository.dart';
import 'package:agent_client/features/files/domain/agent_resources_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final agentResourcesRepositoryProvider = Provider<AgentResourcesRepository>((
  ref,
) {
  return AgentControlResourcesRepository(
    ref.watch(agentControlApiClientProvider),
  );
});
