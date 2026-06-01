import 'package:agent_client/features/chat/application/chat_controller.dart';
import 'package:agent_client/features/chat/application/chat_sessions_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final chatPreloadControllerProvider = Provider<ChatPreloadController>((ref) {
  return ChatPreloadController(ref);
});

class ChatPreloadController {
  ChatPreloadController(this._ref);

  final Ref _ref;
  final _startedAgentIds = <String>{};
  Future<void> _remoteQueue = Future.value();

  Future<void> preloadAgents(Iterable<String> agentIds) async {
    final nextAgentIds = <String>[];
    for (final agentId in agentIds) {
      final trimmed = agentId.trim();
      if (trimmed.isEmpty || !_startedAgentIds.add(trimmed)) {
        continue;
      }
      nextAgentIds.add(trimmed);
    }

    if (nextAgentIds.isEmpty) {
      return _remoteQueue;
    }

    await Future.wait([
      for (final agentId in nextAgentIds)
        _ref
            .read(chatControllerProvider(agentId).notifier)
            .preloadCachedMessages(),
    ]);

    for (final agentId in nextAgentIds) {
      _remoteQueue = _remoteQueue.then((_) => _preloadRemote(agentId));
    }
    return _remoteQueue;
  }

  Future<void> _preloadRemote(String agentId) async {
    try {
      await _ref
          .read(chatSessionsProvider(agentId).notifier)
          .refreshFromRepository();
      await _ref
          .read(chatControllerProvider(agentId).notifier)
          .loadRecentMessages();
    } catch (_) {
      // Preloading should never make the visible workspace fail.
    }
  }
}
