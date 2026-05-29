import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/domain/agent_control_models.dart';
import 'package:agent_client/features/files/domain/agent_file_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final agentResourcesRepositoryProvider = Provider<AgentResourcesRepository>((
  ref,
) {
  return AgentResourcesRepository(ref.watch(agentControlApiClientProvider));
});

class AgentResourcesRepository {
  const AgentResourcesRepository(this._api);

  final AgentControlApi _api;

  Future<List<AgentFileItem>> listWorkspaceRoot(String agentName) async {
    return listWorkspaceDirectory(agentName);
  }

  Future<List<AgentFileItem>> listWorkspaceDirectory(
    String agentName, {
    String path = '.',
  }) async {
    final tree = await _api.getResourceTree(agentName: agentName, path: path);
    return tree.children.map(_toFileItem).toList();
  }

  Future<ResourceFile> readFile({
    required String agentName,
    required String path,
  }) {
    return _api.getResourceFile(agentName: agentName, path: path);
  }

  Future<ResourceFileWriteResult> writeFile({
    required String agentName,
    required String path,
    required String content,
  }) {
    return _api.putResourceFile(
      agentName: agentName,
      path: path,
      content: content,
    );
  }

  Future<List<AgentFileItem>> search({
    required String agentName,
    required String query,
  }) async {
    final response = await _api.searchResources(
      agentName: agentName,
      query: query,
    );
    return response.data.map(_searchResultToFileItem).toList();
  }

  AgentFileItem _toFileItem(ResourceTreeItem item) {
    return AgentFileItem(
      name: item.name,
      path: item.path,
      kind: _kindFor(path: item.path, type: item.type),
      sizeLabel: item.type,
      updatedLabel: item.path,
      owner: 'workspace',
    );
  }

  AgentFileItem _searchResultToFileItem(ResourceSearchResult item) {
    return AgentFileItem(
      name: item.path.split('/').last,
      path: item.path,
      kind: _kindFor(path: item.path, type: item.type),
      sizeLabel: item.match,
      updatedLabel: item.preview ?? item.path,
      owner: item.line == null ? 'workspace' : 'line ${item.line}',
    );
  }

  AgentFileKind _kindFor({required String path, required String type}) {
    if (type == 'directory') {
      return AgentFileKind.directory;
    }
    final extension = path.split('.').last.toLowerCase();
    return switch (extension) {
      'md' || 'txt' || 'pdf' || 'doc' || 'docx' => AgentFileKind.document,
      'csv' || 'tsv' || 'xls' || 'xlsx' => AgentFileKind.spreadsheet,
      'png' || 'jpg' || 'jpeg' || 'gif' || 'webp' => AgentFileKind.image,
      'zip' || 'tar' || 'gz' => AgentFileKind.archive,
      _ => type == 'file' ? AgentFileKind.file : AgentFileKind.other,
    };
  }
}
