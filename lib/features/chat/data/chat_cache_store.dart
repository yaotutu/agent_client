import 'package:agent_client/features/chat/domain/chat_message.dart';

abstract interface class ChatCacheStore {
  Future<void> saveMessage(ChatMessage message);

  Future<void> clearAgent(String agentId);

  Future<void> clearSession({
    required String agentId,
    required String sessionId,
  });

  Future<List<ChatMessage>> loadMessages({
    required String agentId,
    required String sessionId,
    int limit = 50,
  });

  Future<List<ChatMessage>> loadLatestMessages(
    String agentId, {
    int limit = 50,
  });
}

class InMemoryChatCacheStore implements ChatCacheStore {
  final Map<String, List<ChatMessage>> _messagesByAgent = {};

  @override
  Future<void> clearAgent(String agentId) async {
    _messagesByAgent.remove(agentId);
  }

  @override
  Future<void> clearSession({
    required String agentId,
    required String sessionId,
  }) async {
    _messagesByAgent.update(agentId, (messages) {
      return [
        for (final message in messages)
          if (message.conversationId != sessionId) message,
      ];
    }, ifAbsent: () => []);
  }

  @override
  Future<List<ChatMessage>> loadMessages({
    required String agentId,
    required String sessionId,
    int limit = 50,
  }) async {
    final messages = [
      for (final message in _messagesByAgent[agentId] ?? <ChatMessage>[])
        if (message.conversationId == sessionId) message,
    ];
    if (messages.length <= limit) {
      return messages;
    }
    return messages.sublist(messages.length - limit);
  }

  @override
  Future<List<ChatMessage>> loadLatestMessages(
    String agentId, {
    int limit = 50,
  }) async {
    final messages = List<ChatMessage>.of(_messagesByAgent[agentId] ?? []);
    if (messages.isEmpty) {
      return const [];
    }
    messages.sort((left, right) => left.createdAt.compareTo(right.createdAt));
    final latestSessionId = messages.last.conversationId;
    return loadMessages(
      agentId: agentId,
      sessionId: latestSessionId,
      limit: limit,
    );
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
