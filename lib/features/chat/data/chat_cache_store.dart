import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract interface class ChatCacheStore {
  Future<void> saveMessage(ChatMessage message);

  Future<void> clearMessages(String agentId);

  Future<List<ChatMessage>> loadRecentMessages(
    String agentId, {
    int limit = 50,
  });
}

final chatCacheStoreProvider = Provider<ChatCacheStore>((ref) {
  return InMemoryChatCacheStore();
});

class InMemoryChatCacheStore implements ChatCacheStore {
  final Map<String, List<ChatMessage>> _messagesByAgent = {};

  @override
  Future<void> clearMessages(String agentId) async {
    _messagesByAgent.remove(agentId);
  }

  @override
  Future<List<ChatMessage>> loadRecentMessages(
    String agentId, {
    int limit = 50,
  }) async {
    final messages = List<ChatMessage>.of(_messagesByAgent[agentId] ?? []);
    if (messages.length <= limit) {
      return messages;
    }
    return messages.sublist(messages.length - limit);
  }

  @override
  Future<void> saveMessage(ChatMessage message) async {
    final messages = _messagesByAgent.putIfAbsent(message.agentId, () => []);
    final index = messages.indexWhere((item) => item.id == message.id);
    if (index == -1) {
      messages.add(message);
    } else {
      messages[index] = message;
    }
  }
}
