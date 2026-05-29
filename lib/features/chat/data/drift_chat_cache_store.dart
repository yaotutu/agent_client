import 'package:agent_client/data/local/app_database.dart';
import 'package:agent_client/features/chat/data/chat_cache_store.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:drift/drift.dart';

class DriftChatCacheStore implements ChatCacheStore {
  const DriftChatCacheStore(this._database);

  final AppDatabase _database;

  @override
  Future<void> clearAgent(String agentId) {
    return _database.transaction(() async {
      await (_database.delete(
        _database.cachedMessages,
      )..where((table) => table.agentId.equals(agentId))).go();
      await (_database.delete(
        _database.cachedConversations,
      )..where((table) => table.agentId.equals(agentId))).go();
    });
  }

  @override
  Future<void> clearSession({
    required String agentId,
    required String sessionId,
  }) {
    return (_database.delete(_database.cachedMessages)..where(
          (table) =>
              table.agentId.equals(agentId) &
              table.conversationId.equals(sessionId),
        ))
        .go();
  }

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
  Future<List<ChatMessage>> loadMessages({
    required String agentId,
    required String sessionId,
    int limit = 50,
  }) async {
    final query = _database.select(_database.cachedMessages)
      ..where(
        (table) =>
            table.agentId.equals(agentId) &
            table.conversationId.equals(sessionId),
      )
      ..orderBy([(table) => OrderingTerm.desc(table.createdAt)])
      ..limit(limit);
    final rows = await query.get();

    return rows.reversed.map(_toMessage).toList();
  }

  @override
  Future<List<ChatMessage>> loadLatestMessages(
    String agentId, {
    int limit = 50,
  }) async {
    final latest =
        await (_database.select(_database.cachedMessages)
              ..where((table) => table.agentId.equals(agentId))
              ..orderBy([(table) => OrderingTerm.desc(table.createdAt)])
              ..limit(1))
            .getSingleOrNull();
    if (latest == null || latest.conversationId.isEmpty) {
      return const [];
    }

    return loadMessages(
      agentId: agentId,
      sessionId: latest.conversationId,
      limit: limit,
    );
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
