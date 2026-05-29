import 'package:agent_client/features/files/data/agent_resources_repository.dart';
import 'package:agent_client/features/files/domain/agent_file_content.dart';
import 'package:agent_client/features/files/domain/agent_file_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef AgentFilesQuery = ({String agentId, String path});
typedef AgentFileQuery = ({String agentId, String path});

final agentFilesProvider =
    FutureProvider.family<List<AgentFileItem>, AgentFilesQuery>((ref, query) {
      return ref
          .watch(agentResourcesRepositoryProvider)
          .listWorkspaceDirectory(query.agentId, path: query.path);
    });

final agentFileProvider =
    FutureProvider.family<AgentFileContent, AgentFileQuery>((ref, query) {
      return ref
          .watch(agentResourcesRepositoryProvider)
          .readFile(agentName: query.agentId, path: query.path);
    });
