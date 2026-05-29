import 'package:agent_client/data/local/app_database_provider.dart';
import 'package:agent_client/features/chat/data/chat_cache_store.dart';
import 'package:agent_client/features/chat/data/drift_chat_cache_store.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final chatCacheStoreProvider = Provider<ChatCacheStore>((ref) {
  return DriftChatCacheStore(ref.watch(appDatabaseProvider));
});
