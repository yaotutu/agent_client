import 'package:agent_client/features/files/domain/agent_file_content.dart';
import 'package:agent_client/features/files/domain/agent_file_item.dart';

abstract interface class AgentResourcesRepository {
  Future<List<AgentFileItem>> listWorkspaceRoot(String agentName);

  Future<List<AgentFileItem>> listWorkspaceDirectory(
    String agentName, {
    String path = '.',
  });

  Future<AgentFileContent> readFile({
    required String agentName,
    required String path,
  });

  Future<AgentFileWriteResult> writeFile({
    required String agentName,
    required String path,
    required String content,
  });

  Future<List<AgentFileItem>> search({
    required String agentName,
    required String query,
  });
}
