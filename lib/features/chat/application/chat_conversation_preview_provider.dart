import 'package:agent_client/features/chat/data/chat_cache_provider.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final latestCachedChatMessageProvider =
    FutureProvider.family<ChatMessage?, String>((ref, agentId) async {
      final messages = await ref
          .watch(chatCacheStoreProvider)
          .loadLatestMessages(agentId, limit: 1);
      return messages.isEmpty ? null : messages.last;
    });
