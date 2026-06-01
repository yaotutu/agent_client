import 'package:agent_client/data/local/app_database.dart';
import 'package:agent_client/data/local/app_database_provider.dart';
import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final agentAvatarStoreProvider = Provider<AgentAvatarStore>((ref) {
  return DriftAgentAvatarStore(ref.watch(appDatabaseProvider));
});

abstract interface class AgentAvatarStore {
  Future<Map<String, String>> loadAvatarUrls();

  Future<void> saveAvatar({
    required String agentId,
    required String agentName,
    required String avatarUrl,
    required AgentStatus status,
  });

  Future<void> deleteAvatar(String agentId);
}

class DriftAgentAvatarStore implements AgentAvatarStore {
  const DriftAgentAvatarStore(this._database);

  final AppDatabase _database;

  @override
  Future<Map<String, String>> loadAvatarUrls() async {
    final rows = await _database.select(_database.cachedAgents).get();
    return {
      for (final row in rows)
        if (row.avatarUrl?.trim().isNotEmpty == true)
          row.id: row.avatarUrl!.trim(),
    };
  }

  @override
  Future<void> saveAvatar({
    required String agentId,
    required String agentName,
    required String avatarUrl,
    required AgentStatus status,
  }) {
    return _database
        .into(_database.cachedAgents)
        .insertOnConflictUpdate(
          CachedAgentsCompanion(
            id: Value(agentId),
            name: Value(agentName),
            avatarUrl: Value(avatarUrl),
            status: Value(status.name),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  @override
  Future<void> deleteAvatar(String agentId) {
    return (_database.delete(
      _database.cachedAgents,
    )..where((table) => table.id.equals(agentId))).go();
  }
}
