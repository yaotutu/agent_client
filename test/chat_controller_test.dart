import 'dart:async';

import 'package:agent_client/features/chat/application/chat_controller.dart';
import 'package:agent_client/features/chat/application/chat_sessions_controller.dart';
import 'package:agent_client/features/chat/data/agent_chat_repository.dart';
import 'package:agent_client/features/chat/data/agent_chat_repository_provider.dart';
import 'package:agent_client/features/chat/data/chat_cache_provider.dart';
import 'package:agent_client/features/chat/data/chat_cache_store.dart';
import 'package:agent_client/features/chat/domain/chat_event.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:agent_client/features/chat/domain/chat_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test(
    'sendMessage streams deltas into one completed assistant message',
    () async {
      final repository = _FakeAgentChatRepository([
        const ChatEvent.messageStarted(messageId: 'assistant-1'),
        const ChatEvent.textDelta(messageId: 'assistant-1', delta: 'Hello'),
        const ChatEvent.textDelta(messageId: 'assistant-1', delta: ' there'),
        const ChatEvent.messageCompleted(messageId: 'assistant-1'),
      ]);
      final cache = InMemoryChatCacheStore();
      final container = ProviderContainer(
        overrides: [
          agentChatRepositoryProvider.overrideWithValue(repository),
          chatCacheStoreProvider.overrideWithValue(cache),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(chatControllerProvider('agent-control').notifier)
          .sendMessage('Hi');

      final state = container.read(chatControllerProvider('agent-control'));
      expect(state.sessionId, 'session-1');
      expect(state.messages, hasLength(2));
      expect(state.messages.first.role, ChatRole.user);
      expect(state.messages.first.content, 'Hi');
      expect(state.messages.first.conversationId, 'session-1');
      expect(state.messages.last.role, ChatRole.assistant);
      expect(state.messages.last.content, 'Hello there');
      expect(state.messages.last.status, ChatMessageStatus.completed);
      expect(state.isStreaming, isFalse);
    },
  );

  test('sendMessage clears live activity after completion', () async {
    final repository = _FakeAgentChatRepository([
      const ChatEvent.messageStarted(messageId: 'assistant-1'),
      const ChatEvent.activity(
        messageId: 'assistant-1',
        activity: ChatActivity.goalStatus(state: 'running'),
      ),
      const ChatEvent.activity(
        messageId: 'assistant-1',
        activity: ChatActivity.reasoning('Thinking'),
      ),
      const ChatEvent.activity(
        messageId: 'assistant-1',
        activity: ChatActivity.progress('Searching'),
      ),
      const ChatEvent.activity(
        messageId: 'assistant-1',
        activity: ChatActivity.toolHint(text: 'running rg'),
      ),
      const ChatEvent.messageCompleted(messageId: 'assistant-1'),
    ]);
    final container = ProviderContainer(
      overrides: [
        agentChatRepositoryProvider.overrideWithValue(repository),
        chatCacheStoreProvider.overrideWithValue(InMemoryChatCacheStore()),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(chatControllerProvider('agent-control').notifier)
        .sendMessage('Hi');

    final state = container.read(chatControllerProvider('agent-control'));
    expect(state.isStreaming, isFalse);
    expect(state.reasoningText, isNull);
    expect(state.progressText, isNull);
    expect(state.toolHintText, isNull);
    expect(state.goalStatus, isNull);
    expect(state.goalState, isNull);
  });

  test(
    'sendMessage accumulates reasoning deltas while stream is active',
    () async {
      final repository = _ManualAgentChatRepository();
      final container = ProviderContainer(
        overrides: [
          agentChatRepositoryProvider.overrideWithValue(repository),
          chatCacheStoreProvider.overrideWithValue(InMemoryChatCacheStore()),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      final sendFuture = container
          .read(chatControllerProvider('agent-control').notifier)
          .sendMessage('Hi');
      final request = await repository.request;

      repository.events.add(
        ChatEvent.messageStarted(messageId: request.assistantMessageId),
      );
      repository.events.add(
        ChatEvent.activity(
          messageId: request.assistantMessageId,
          activity: const ChatActivity.reasoning('Think'),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(chatControllerProvider('agent-control')).reasoningText,
        'Think',
      );

      repository.events.add(
        ChatEvent.activity(
          messageId: request.assistantMessageId,
          activity: const ChatActivity.reasoning('ing'),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(chatControllerProvider('agent-control')).reasoningText,
        'Thinking',
      );

      repository.events.add(
        ChatEvent.activity(
          messageId: request.assistantMessageId,
          activity: const ChatActivity.reasoningDone(),
        ),
      );
      repository.events.add(
        ChatEvent.messageCompleted(messageId: request.assistantMessageId),
      );
      await repository.events.close();
      await sendFuture;
    },
  );

  test('sendMessage clears live activity after stream error', () async {
    final repository = _FakeAgentChatRepository([
      const ChatEvent.messageStarted(messageId: 'assistant-1'),
      const ChatEvent.activity(
        messageId: 'assistant-1',
        activity: ChatActivity.goalStatus(state: 'running'),
      ),
      const ChatEvent.activity(
        messageId: 'assistant-1',
        activity: ChatActivity.reasoning('Thinking'),
      ),
      const ChatEvent.activity(
        messageId: 'assistant-1',
        activity: ChatActivity.progress('Searching'),
      ),
      const ChatEvent.activity(
        messageId: 'assistant-1',
        activity: ChatActivity.toolHint(text: 'running rg'),
      ),
      const ChatEvent.error(messageId: 'assistant-1', errorMessage: 'boom'),
    ]);
    final container = ProviderContainer(
      overrides: [
        agentChatRepositoryProvider.overrideWithValue(repository),
        chatCacheStoreProvider.overrideWithValue(InMemoryChatCacheStore()),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(chatControllerProvider('agent-control').notifier)
        .sendMessage('Hi');

    final state = container.read(chatControllerProvider('agent-control'));
    expect(state.isStreaming, isFalse);
    expect(state.errorMessage, 'boom');
    expect(state.reasoningText, isNull);
    expect(state.progressText, isNull);
    expect(state.toolHintText, isNull);
    expect(state.goalStatus, isNull);
    expect(state.goalState, isNull);
    expect(state.messages.last.status, ChatMessageStatus.failed);
  });

  test(
    'refreshRecentMessages replaces stale static preview messages',
    () async {
      final repository = _FakeAgentChatRepository(
        const [],
        recentMessages: [
          ChatMessage(
            id: 'static-rich-message',
            agentId: 'agent-control',
            conversationId: 'session-1',
            role: ChatRole.assistant,
            content: 'Updated **rich** preview',
            status: ChatMessageStatus.completed,
            createdAt: DateTime(2026, 5, 29),
          ),
        ],
      );
      final cache = InMemoryChatCacheStore();
      final container = ProviderContainer(
        overrides: [
          agentChatRepositoryProvider.overrideWithValue(repository),
          chatCacheStoreProvider.overrideWithValue(cache),
        ],
      );
      addTearDown(container.dispose);

      await cache.saveMessage(
        ChatMessage(
          id: 'old-message',
          agentId: 'agent-control',
          conversationId: 'session-1',
          role: ChatRole.assistant,
          content: 'Old preview',
          status: ChatMessageStatus.completed,
          createdAt: DateTime(2026, 5, 28),
        ),
      );

      await container
          .read(chatControllerProvider('agent-control').notifier)
          .loadRecentMessages();
      expect(
        container
            .read(chatControllerProvider('agent-control'))
            .messages
            .single
            .id,
        'old-message',
      );

      await container
          .read(chatControllerProvider('agent-control').notifier)
          .refreshRecentMessages();

      final messages = container
          .read(chatControllerProvider('agent-control'))
          .messages;
      expect(messages, hasLength(1));
      expect(messages.single.id, 'static-rich-message');
      expect(messages.single.content, 'Updated **rich** preview');
    },
  );

  test(
    'loadRecentMessages uses local cache without ensuring a backend session',
    () async {
      final repository = _FakeAgentChatRepository(const []);
      final cache = InMemoryChatCacheStore();
      final container = ProviderContainer(
        overrides: [
          agentChatRepositoryProvider.overrideWithValue(repository),
          chatCacheStoreProvider.overrideWithValue(cache),
        ],
      );
      addTearDown(container.dispose);

      await cache.saveMessage(
        ChatMessage(
          id: 'cached-message',
          agentId: 'agent-control',
          conversationId: 'cached-session',
          role: ChatRole.assistant,
          content: 'Cached preview',
          status: ChatMessageStatus.completed,
          createdAt: DateTime(2026, 5, 29),
        ),
      );

      await container
          .read(chatControllerProvider('agent-control').notifier)
          .loadRecentMessages();

      final state = container.read(chatControllerProvider('agent-control'));
      expect(state.sessionId, 'cached-session');
      expect(state.messages.single.id, 'cached-message');
      expect(repository.ensureSessionCallCount, 0);
    },
  );

  test(
    'refreshRecentMessages clears stale cache when backend history is empty',
    () async {
      final repository = _FakeAgentChatRepository(const []);
      final cache = InMemoryChatCacheStore();
      final container = ProviderContainer(
        overrides: [
          agentChatRepositoryProvider.overrideWithValue(repository),
          chatCacheStoreProvider.overrideWithValue(cache),
        ],
      );
      addTearDown(container.dispose);

      await cache.saveMessage(
        ChatMessage(
          id: 'old-message',
          agentId: 'agent-control',
          conversationId: 'session-1',
          role: ChatRole.assistant,
          content: 'Old preview',
          status: ChatMessageStatus.completed,
          createdAt: DateTime(2026, 5, 28),
        ),
      );

      await container
          .read(chatControllerProvider('agent-control').notifier)
          .loadRecentMessages();
      expect(
        container
            .read(chatControllerProvider('agent-control'))
            .messages
            .single
            .id,
        'old-message',
      );

      await container
          .read(chatControllerProvider('agent-control').notifier)
          .refreshRecentMessages();

      expect(
        container.read(chatControllerProvider('agent-control')).messages,
        isEmpty,
      );
    },
  );

  test(
    'startNewSession creates a fresh backend session without clearing other sessions',
    () async {
      final repository = _FakeAgentChatRepository(
        const [],
        newSessionId: 'session-2',
      );
      final cache = InMemoryChatCacheStore();
      final container = ProviderContainer(
        overrides: [
          agentChatRepositoryProvider.overrideWithValue(repository),
          chatCacheStoreProvider.overrideWithValue(cache),
        ],
      );
      addTearDown(container.dispose);

      await cache.saveMessage(
        ChatMessage(
          id: 'old-message',
          agentId: 'agent-control',
          conversationId: 'session-1',
          role: ChatRole.assistant,
          content: 'Old preview',
          status: ChatMessageStatus.completed,
          createdAt: DateTime(2026, 5, 28),
        ),
      );
      await container
          .read(chatControllerProvider('agent-control').notifier)
          .loadRecentMessages();

      await container
          .read(chatControllerProvider('agent-control').notifier)
          .startNewSession();

      final state = container.read(chatControllerProvider('agent-control'));
      final sessions = container.read(chatSessionsProvider('agent-control'));
      expect(state.sessionId, 'session-2');
      expect(state.messages, isEmpty);
      expect(sessions.sessions.first.id, 'session-2');
      expect(sessions.sessions.first.title, 'Backend created chat');
      expect(repository.startedNewSessionAgentId, 'agent-control');
      expect(
        await cache.loadMessages(
          agentId: 'agent-control',
          sessionId: 'session-2',
        ),
        isEmpty,
      );
      expect(
        await cache.loadMessages(
          agentId: 'agent-control',
          sessionId: 'session-1',
        ),
        isNotEmpty,
      );
    },
  );

  test('chat sessions refreshes from backend summaries', () async {
    final repository = _FakeAgentChatRepository(
      const [],
      sessions: const [
        ChatSessionSummary(
          id: 'session-2',
          title: '你好，帮我看看代码',
          preview: '你好，帮我看看代码',
          messageCount: 4,
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [agentChatRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container
        .read(chatSessionsProvider('agent-control').notifier)
        .refreshFromRepository();

    final sessions = container.read(chatSessionsProvider('agent-control'));
    expect(sessions.selectedSessionId, 'session-2');
    expect(sessions.sessions.single.title, '你好，帮我看看代码');
    expect(sessions.sessions.single.messageCount, 4);
  });

  test('chat sessions starts empty instead of showing local mock sessions', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final sessions = container.read(chatSessionsProvider('agent-control'));

    expect(sessions.selectedSessionId, isNull);
    expect(sessions.sessions, isEmpty);
  });

  test('cache keeps messages isolated by agent and session', () async {
    final cache = InMemoryChatCacheStore();

    await cache.saveMessage(
      ChatMessage(
        id: 'a-session-1',
        agentId: 'agent-a',
        conversationId: 'session-1',
        role: ChatRole.assistant,
        content: 'first',
        status: ChatMessageStatus.completed,
        createdAt: DateTime(2026, 5, 29, 9),
      ),
    );
    await cache.saveMessage(
      ChatMessage(
        id: 'a-session-2',
        agentId: 'agent-a',
        conversationId: 'session-2',
        role: ChatRole.assistant,
        content: 'second',
        status: ChatMessageStatus.completed,
        createdAt: DateTime(2026, 5, 29, 10),
      ),
    );
    await cache.saveMessage(
      ChatMessage(
        id: 'b-session-2',
        agentId: 'agent-b',
        conversationId: 'session-2',
        role: ChatRole.assistant,
        content: 'other agent',
        status: ChatMessageStatus.completed,
        createdAt: DateTime(2026, 5, 29, 11),
      ),
    );

    final sessionOne = await cache.loadMessages(
      agentId: 'agent-a',
      sessionId: 'session-1',
    );
    final sessionTwo = await cache.loadMessages(
      agentId: 'agent-a',
      sessionId: 'session-2',
    );
    final latest = await cache.loadLatestMessages('agent-a');

    expect(sessionOne.single.content, 'first');
    expect(sessionTwo.single.content, 'second');
    expect(latest.single.id, 'a-session-2');
  });
}

class _FakeAgentChatRepository implements AgentChatRepository {
  _FakeAgentChatRepository(
    this.events, {
    this.recentMessages = const [],
    this.newSessionId = 'session-new',
    this.sessions = const [],
  });

  final List<ChatEvent> events;
  final List<ChatMessage> recentMessages;
  final String newSessionId;
  final List<ChatSessionSummary> sessions;
  String? canceledSessionId;
  String? canceledAgentId;
  String? startedNewSessionAgentId;
  var ensureSessionCallCount = 0;

  @override
  Future<String> ensureSessionId(String agentId) async {
    ensureSessionCallCount += 1;
    expect(agentId, 'agent-control');
    return 'session-1';
  }

  @override
  Future<ChatSessionSummary> startNewSession(String agentId) async {
    startedNewSessionAgentId = agentId;
    return ChatSessionSummary(
      id: newSessionId,
      title: 'Backend created chat',
      preview: '',
      messageCount: 0,
    );
  }

  @override
  Future<List<ChatSessionSummary>> listSessions(String agentId) async {
    return sessions;
  }

  @override
  Future<void> cancelActiveResponse({
    required String agentId,
    required String sessionId,
  }) async {
    canceledAgentId = agentId;
    canceledSessionId = sessionId;
  }

  @override
  Future<List<ChatMessage>> loadRecentMessages(
    String agentId, {
    String? sessionId,
  }) async {
    expect(sessionId, 'session-1');
    return recentMessages;
  }

  @override
  Stream<ChatEvent> sendMessage(SendMessageRequest request) async* {
    expect(request.agentId, 'agent-control');
    expect(request.sessionId, 'session-1');
    expect(request.assistantMessageId, startsWith('assistant-'));
    expect(request.input, 'Hi');

    for (final event in events) {
      yield event;
    }
  }
}

class _ManualAgentChatRepository implements AgentChatRepository {
  final events = StreamController<ChatEvent>();
  final _request = Completer<SendMessageRequest>();

  Future<SendMessageRequest> get request => _request.future;

  void dispose() {
    if (!events.isClosed) {
      events.close();
    }
  }

  @override
  Future<String> ensureSessionId(String agentId) async {
    expect(agentId, 'agent-control');
    return 'session-1';
  }

  @override
  Future<ChatSessionSummary> startNewSession(String agentId) async {
    return const ChatSessionSummary(
      id: 'session-new',
      title: 'Backend created chat',
      preview: '',
      messageCount: 0,
    );
  }

  @override
  Future<List<ChatSessionSummary>> listSessions(String agentId) async {
    return const [];
  }

  @override
  Future<void> cancelActiveResponse({
    required String agentId,
    required String sessionId,
  }) async {}

  @override
  Future<List<ChatMessage>> loadRecentMessages(
    String agentId, {
    String? sessionId,
  }) async {
    return const [];
  }

  @override
  Stream<ChatEvent> sendMessage(SendMessageRequest request) {
    _request.complete(request);
    return events.stream;
  }
}
