import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/domain/agent_control_models.dart';
import 'package:agent_client/features/files/domain/agent_file_content.dart';
import 'package:agent_client/features/files/domain/agent_file_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final agentResourcesRepositoryProvider = Provider<AgentResourcesRepository>((
  ref,
) {
  return AgentControlResourcesRepository(
    ref.watch(agentControlApiClientProvider),
  );
});

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

class AgentControlResourcesRepository implements AgentResourcesRepository {
  const AgentControlResourcesRepository(this._api);

  final AgentControlApi _api;

  @override
  Future<List<AgentFileItem>> listWorkspaceRoot(String agentName) {
    return listWorkspaceDirectory(agentName);
  }

  @override
  Future<List<AgentFileItem>> listWorkspaceDirectory(
    String agentName, {
    String path = '.',
  }) async {
    final tree = await _api.getResourceTree(agentName: agentName, path: path);
    return tree.children.map(_toFileItem).toList();
  }

  @override
  Future<AgentFileContent> readFile({
    required String agentName,
    required String path,
  }) async {
    final file = await _api.getResourceFile(agentName: agentName, path: path);
    return AgentFileContent(
      path: file.path,
      size: file.size,
      mtimeMs: file.mtimeMs,
      content: file.content,
    );
  }

  @override
  Future<AgentFileWriteResult> writeFile({
    required String agentName,
    required String path,
    required String content,
  }) async {
    final result = await _api.putResourceFile(
      agentName: agentName,
      path: path,
      content: content,
    );
    return AgentFileWriteResult(
      path: result.path,
      size: result.size,
      mtimeMs: result.mtimeMs,
    );
  }

  @override
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
