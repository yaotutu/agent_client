import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DataClassName('CachedAgentRow')
class CachedAgents extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CachedConversationRow')
class CachedConversations extends Table {
  TextColumn get id => text()();
  TextColumn get agentId => text()();
  TextColumn get title => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CachedMessageRow')
class CachedMessages extends Table {
  TextColumn get id => text()();
  TextColumn get agentId => text()();
  TextColumn get conversationId => text()();
  TextColumn get role => text()();
  TextColumn get content => text()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [CachedAgents, CachedConversations, CachedMessages])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'agent_client_cache',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
