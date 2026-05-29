import 'package:agent_client/data/local/app_database.dart';
import 'package:agent_client/data/local/app_database_provider.dart';
import 'package:agent_client/features/chat/data/chat_cache_store.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final driftChatCacheStoreProvider = Provider<DriftChatCacheStore>((ref) {
  return DriftChatCacheStore(ref.watch(appDatabaseProvider));
});

class DriftChatCacheStore implements ChatCacheStore {
  const DriftChatCacheStore(this._database);

  final AppDatabase _database;

  @override
  Future<void> saveMessage(ChatMessage message) {
    return _database
        .into(_database.cachedMessages)
        .insertOnConflictUpdate(
          CachedMessagesCompanion(
            id: Value(message.id),
            agentId: Value(message.agentId),
            conversationId: Value(message.conversationId),
            role: Value(message.role.name),
            content: Value(message.content),
            status: Value(message.status.name),
            createdAt: Value(message.createdAt),
          ),
        );
  }

  @override
  Future<List<ChatMessage>> loadRecentMessages(
    String agentId, {
    int limit = 50,
  }) async {
    final query = _database.select(_database.cachedMessages)
      ..where((table) => table.agentId.equals(agentId))
      ..orderBy([(table) => OrderingTerm.desc(table.createdAt)])
      ..limit(limit);
    final rows = await query.get();

    return rows.reversed.map(_toMessage).toList();
  }

  ChatMessage _toMessage(CachedMessageRow row) {
    return ChatMessage(
      id: row.id,
      agentId: row.agentId,
      conversationId: row.conversationId,
      role: ChatRole.values.byName(row.role),
      content: row.content,
      status: ChatMessageStatus.values.byName(row.status),
      createdAt: row.createdAt,
    );
  }
}
