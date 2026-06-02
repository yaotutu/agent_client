import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/data/agent_control_chat_repository.dart';
import 'package:agent_client/features/agent_control/domain/agent_control_models.dart';
import 'package:agent_client/features/chat/data/agent_chat_repository.dart';
import 'package:agent_client/features/chat/domain/chat_event.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:agent_client/features/chat/domain/chat_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'creates a named-agent backend session when AgentCard has no default session',
    () async {
      final api = _FakeAgentControlApi(
        card: _card(name: 'coder', defaultSessionId: null),
        createdSessionId: 'session-created',
      );
      final repository = AgentControlChatRepository(api: api);

      final sessionId = await repository.ensureSessionId('coder');

      expect(sessionId, 'session-created');
      expect(api.cardAgentName, 'coder');
      expect(api.createdSessionAgentName, 'coder');
      expect(api.createSessionCount, 1);
      expect(api.startedAgentNames, isEmpty);
    },
  );

  test('starts an unhealthy agent before creating a session', () async {
    final api = _FakeAgentControlApi(
      card: _card(name: 'test', defaultSessionId: null, health: 'unknown'),
      cardAfterStart: _card(name: 'test', defaultSessionId: null),
      createdSessionId: 'session-created',
    );
    final repository = AgentControlChatRepository(
      api: api,
      startupPollDelay: Duration.zero,
    );

    final sessionId = await repository.ensureSessionId('test');

    expect(sessionId, 'session-created');
    expect(api.startedAgentNames, ['test']);
    expect(api.createdSessionAgentName, 'test');
  });

  test('treats ok health as ready without starting the agent', () async {
    final api = _FakeAgentControlApi(
      card: _card(name: 'test', defaultSessionId: null, health: 'ok'),
      createdSessionId: 'session-created',
    );
    final repository = AgentControlChatRepository(api: api);

    final sessionId = await repository.ensureSessionId('test');

    expect(sessionId, 'session-created');
    expect(api.startedAgentNames, isEmpty);
    expect(api.createSessionCount, 1);
  });

  test(
    'reuses named-agent default session without creating a new one',
    () async {
      final api = _FakeAgentControlApi(
        card: _card(name: 'coder', defaultSessionId: 'session-default'),
        createdSessionId: 'session-created',
      );
      final repository = AgentControlChatRepository(api: api);

      final sessionId = await repository.ensureSessionId('coder');

      expect(sessionId, 'session-default');
      expect(api.cardAgentName, 'coder');
      expect(api.createSessionCount, 0);
    },
  );

  test(
    'startNewSession creates a fresh session instead of reusing default',
    () async {
      final api = _FakeAgentControlApi(
        card: _card(name: 'coder', defaultSessionId: 'session-default'),
        createdSessionId: 'session-fresh',
      );
      final repository = AgentControlChatRepository(api: api);

      final session = await repository.startNewSession('coder');

      expect(session.id, 'session-fresh');
      expect(session.title, 'New chat');
      expect(api.createdSessionAgentName, 'coder');
      expect(api.createSessionCount, 1);
    },
  );

  test('listSessions maps backend session metadata for the UI', () async {
    final runStartedAt = DateTime.fromMillisecondsSinceEpoch(
      1780023022320,
      isUtc: true,
    );
    final api = _FakeAgentControlApi(
      card: _card(name: 'coder', defaultSessionId: null),
      sessions: [
        SessionSummary(
          rawSessionId: 'session-1',
          createdAt: DateTime(2026, 5, 29, 10, 50),
          updatedAt: DateTime(2026, 5, 29, 10, 51),
          title: '你好，帮我看看代码',
          preview: '你好，帮我看看代码',
          messageCount: 4,
          status: 'running',
          runStartedAt: runStartedAt,
        ),
      ],
    );
    final repository = AgentControlChatRepository(api: api);

    final sessions = await repository.listSessions('coder');

    expect(sessions.single.id, 'session-1');
    expect(sessions.single.title, '你好，帮我看看代码');
    expect(sessions.single.preview, '你好，帮我看看代码');
    expect(sessions.single.messageCount, 4);
    expect(sessions.single.status, ChatSessionStatus.running);
    expect(sessions.single.runStartedAt, runStartedAt);
  });

  test('listSessions maps backend stopping session status', () async {
    final api = _FakeAgentControlApi(
      card: _card(name: 'coder', defaultSessionId: null),
      sessions: const [
        SessionSummary(
          rawSessionId: 'session-1',
          createdAt: null,
          updatedAt: null,
          title: 'Stopping chat',
          preview: '',
          messageCount: 1,
          status: 'stopping',
        ),
      ],
    );
    final repository = AgentControlChatRepository(api: api);

    final sessions = await repository.listSessions('coder');

    expect(sessions.single.status, ChatSessionStatus.stopping);
  });

  test('keeps session caches separate per agent name', () async {
    final api = _FakeAgentControlApi(
      card: _card(name: 'coder', defaultSessionId: null),
      createdSessionId: 'coder-session',
      sessionIdsByAgent: const {'reviewer': 'reviewer-session'},
    );
    final repository = AgentControlChatRepository(api: api);

    expect(await repository.ensureSessionId('coder'), 'coder-session');
    expect(await repository.ensureSessionId('reviewer'), 'reviewer-session');

    expect(api.createdSessionAgentNames, ['coder', 'reviewer']);
  });

  test(
    'streams Agent Control text events into chat events for named agent',
    () async {
      final api = _FakeAgentControlApi(
        card: _card(name: 'coder', defaultSessionId: 'session-1'),
        streamEvents: const [
          AgentControlStreamEvent(
            type: AgentControlStreamEventType.text,
            text: 'Hel',
          ),
          AgentControlStreamEvent(
            type: AgentControlStreamEventType.progress,
            text: 'Running command',
          ),
          AgentControlStreamEvent(
            type: AgentControlStreamEventType.text,
            text: 'lo',
          ),
          AgentControlStreamEvent(
            type: AgentControlStreamEventType.done,
            latencyMs: 12,
          ),
        ],
      );
      final repository = AgentControlChatRepository(api: api);

      final events = await repository
          .sendMessage(
            const SendMessageRequest(
              agentId: 'coder',
              sessionId: 'session-1',
              assistantMessageId: 'assistant-1',
              input: 'Hi',
            ),
          )
          .toList();

      expect(api.sentAgentName, 'coder');
      expect(api.sentSessionId, 'session-1');
      expect(api.sentContent, 'Hi');
      expect(
        events[0],
        const ChatEvent.messageStarted(messageId: 'assistant-1'),
      );
      expect(
        events[1],
        const ChatEvent.textDelta(messageId: 'assistant-1', delta: 'Hel'),
      );
      expect(events[2].type, ChatEventType.activity);
      expect(
        events[2].activity,
        const ChatActivity.progress('Running command'),
      );
      expect(
        events[3],
        const ChatEvent.textDelta(messageId: 'assistant-1', delta: 'lo'),
      );
      expect(
        events[4],
        const ChatEvent.messageCompleted(messageId: 'assistant-1'),
      );
    },
  );

  test('preserves Agent Control stream error codes', () async {
    final api = _FakeAgentControlApi(
      card: _card(name: 'coder', defaultSessionId: 'session-1'),
      streamEvents: const [
        AgentControlStreamEvent(
          type: AgentControlStreamEventType.error,
          message: 'Session is busy',
          code: 'SESSION_BUSY',
        ),
      ],
    );
    final repository = AgentControlChatRepository(api: api);

    final events = await repository
        .sendMessage(
          const SendMessageRequest(
            agentId: 'coder',
            sessionId: 'session-1',
            assistantMessageId: 'assistant-1',
            input: 'Hi',
          ),
        )
        .toList();

    expect(events.last.type, ChatEventType.error);
    expect(events.last.errorMessage, 'Session is busy');
    expect(events.last.errorCode, 'SESSION_BUSY');
  });

  test('maps Agent Control file edit events into chat activity', () async {
    final api = _FakeAgentControlApi(
      card: _card(name: 'coder', defaultSessionId: 'session-1'),
      streamEvents: const [
        AgentControlStreamEvent(
          type: AgentControlStreamEventType.fileEdit,
          fileEdits: [
            {'path': 'src/a.js', 'action': 'modified'},
            {'file': 'lib/b.dart', 'status': 'created'},
            {'name': 'README.md'},
          ],
        ),
        AgentControlStreamEvent(type: AgentControlStreamEventType.done),
      ],
    );
    final repository = AgentControlChatRepository(api: api);

    final events = await repository
        .sendMessage(
          const SendMessageRequest(
            agentId: 'coder',
            sessionId: 'session-1',
            assistantMessageId: 'assistant-1',
            input: 'Hi',
          ),
        )
        .toList();

    expect(events[1].type, ChatEventType.activity);
    expect(
      events[1].activity,
      const ChatActivity.fileEdit(
        fileEdits: [
          {'path': 'src/a.js', 'action': 'modified'},
          {'file': 'lib/b.dart', 'status': 'created'},
          {'name': 'README.md'},
        ],
      ),
    );
  });

  test('attaches an existing session before sending a message', () async {
    final api = _FakeAgentControlApi(
      card: _card(name: 'coder', defaultSessionId: null),
      streamEvents: const [
        AgentControlStreamEvent(type: AgentControlStreamEventType.done),
      ],
    );
    final repository = AgentControlChatRepository(api: api);

    await repository
        .sendMessage(
          const SendMessageRequest(
            agentId: 'coder',
            sessionId: 'cached-session',
            assistantMessageId: 'assistant-1',
            input: 'Hi',
          ),
        )
        .toList();

    expect(api.attachedAgentName, 'coder');
    expect(api.attachedSessionId, 'cached-session');
    expect(api.sentSessionId, 'cached-session');
  });

  test('maps named-agent backend history into local chat messages', () async {
    final api = _FakeAgentControlApi(
      card: _card(name: 'coder', defaultSessionId: 'session-1'),
      messages: SessionMessages(
        key: 'websocket:session-1',
        createdAt: null,
        updatedAt: null,
        metadata: const {},
        messages: [
          SessionMessage(
            role: 'user',
            content: '你好',
            timestamp: DateTime(2026, 5, 29, 10, 1),
          ),
          SessionMessage(
            role: 'assistant',
            content: '你好！',
            timestamp: DateTime(2026, 5, 29, 10, 2),
            latencyMs: 1000,
          ),
        ],
      ),
    );
    final repository = AgentControlChatRepository(api: api);

    final messages = await repository.loadRecentMessages(
      'coder',
      sessionId: 'session-1',
    );

    expect(api.messagesAgentName, 'coder');
    expect(messages, hasLength(2));
    expect(messages.first.role, ChatRole.user);
    expect(messages.first.conversationId, 'session-1');
    expect(messages.last.role, ChatRole.assistant);
    expect(messages.last.content, '你好！');
  });

  test('maps only the recent backend history window', () async {
    final api = _FakeAgentControlApi(
      card: _card(name: 'coder', defaultSessionId: 'session-1'),
      messages: SessionMessages(
        key: 'websocket:session-1',
        createdAt: null,
        updatedAt: null,
        metadata: const {},
        messages: [
          for (var index = 0; index < 80; index += 1)
            SessionMessage(
              role: index.isEven ? 'user' : 'assistant',
              content: 'message $index',
              timestamp: DateTime(2026, 5, 29, 10, index),
            ),
        ],
      ),
    );
    final repository = AgentControlChatRepository(api: api);

    final messages = await repository.loadRecentMessages(
      'coder',
      sessionId: 'session-1',
    );

    expect(messages, hasLength(50));
    expect(messages.first.content, 'message 30');
    expect(messages.last.content, 'message 79');
  });

  test(
    'loads latest persisted session without starting or attaching a session',
    () async {
      final api = _FakeAgentControlApi(
        card: _card(name: 'coder', defaultSessionId: null, health: 'unknown'),
        sessions: [
          SessionSummary(
            key: 'websocket:older-session',
            createdAt: DateTime(2026, 5, 28),
            updatedAt: DateTime(2026, 5, 28, 1),
            title: '',
            preview: 'old',
          ),
          SessionSummary(
            key: 'websocket:latest-session',
            createdAt: DateTime(2026, 5, 29),
            updatedAt: DateTime(2026, 5, 29, 1),
            title: '',
            preview: 'new',
          ),
        ],
        messages: SessionMessages(
          key: 'websocket:latest-session',
          createdAt: null,
          updatedAt: null,
          metadata: const {},
          messages: [
            SessionMessage(
              role: 'assistant',
              content: 'latest',
              timestamp: DateTime(2026, 5, 29, 1),
            ),
          ],
        ),
      );
      final repository = AgentControlChatRepository(api: api);

      final messages = await repository.loadRecentMessages('coder');

      expect(messages.single.conversationId, 'latest-session');
      expect(api.attachedSessionId, isNull);
      expect(api.createSessionCount, 0);
      expect(api.startedAgentNames, isEmpty);
    },
  );

  test(
    'stops the backend task for the named agent and active session',
    () async {
      final api = _FakeAgentControlApi(
        card: _card(name: 'coder', defaultSessionId: 'session-1'),
      );
      final repository = AgentControlChatRepository(api: api);

      await repository.cancelActiveResponse(
        agentId: 'coder',
        sessionId: 'session-1',
      );

      expect(api.stoppedAgentName, 'coder');
      expect(api.stoppedSessionId, 'session-1');
    },
  );
}

AgentCard _card({
  required String name,
  required String? defaultSessionId,
  String health = 'healthy',
}) {
  return AgentCard(
    name: name,
    protocol: 'agent-control/v1',
    capabilities: const ['sessions', 'streaming'],
    state: AgentCardState(
      status: 'idle',
      defaultSessionId: defaultSessionId,
      health: health,
    ),
    model: 'MiniMax-M2.7-highspeed',
    provider: 'minimax',
    workspace: '/workspace',
    wsPort: 8760,
    gatewayPort: 18760,
  );
}

class _FakeAgentControlApi implements AgentControlApi {
  _FakeAgentControlApi({
    required this.card,
    this.cardAfterStart,
    this.createdSessionId = 'session-created',
    this.sessionIdsByAgent = const {},
    this.sessions = const [],
    this.streamEvents = const [],
    SessionMessages? messages,
  }) : messages =
           messages ??
           const SessionMessages(
             key: 'websocket:session-created',
             createdAt: null,
             updatedAt: null,
             metadata: {},
             messages: [],
           );

  final AgentCard card;
  final AgentCard? cardAfterStart;
  final String createdSessionId;
  final Map<String, String> sessionIdsByAgent;
  final List<SessionSummary> sessions;
  final List<AgentControlStreamEvent> streamEvents;
  final SessionMessages messages;
  var createSessionCount = 0;
  final createdSessionAgentNames = <String>[];
  final startedAgentNames = <String>[];
  String? cardAgentName;
  String? createdSessionAgentName;
  String? messagesAgentName;
  String? attachedAgentName;
  String? attachedSessionId;
  String? sentAgentName;
  String? sentSessionId;
  String? sentContent;
  String? stoppedAgentName;
  String? stoppedSessionId;

  @override
  Future<AgentListResponse> listAgents() async {
    return const AgentListResponse(object: 'list', data: []);
  }

  @override
  Future<AgentCard> getAgentCard(String agentName) async {
    cardAgentName = agentName;
    if (startedAgentNames.isNotEmpty && cardAfterStart != null) {
      return cardAfterStart!;
    }
    return card;
  }

  @override
  Future<HealthStatus> getHealth() async => const HealthStatus(status: 'ok');

  @override
  Future<CreateAgentResponse> createAgent({
    required String name,
    String? description,
  }) async {
    return CreateAgentResponse(
      name: name,
      wsPort: 8760,
      gatewayPort: 18760,
      configPath: '/agents/$name/config.json',
      workspaceDir: '/agents/$name/workspace',
      model: 'MiniMax-M2.7-highspeed',
      provider: 'minimax',
      status: 'stopped',
    );
  }

  @override
  Future<DeleteAgentResponse> deleteAgent(String agentName) async {
    return DeleteAgentResponse(deleted: true, name: agentName);
  }

  @override
  Future<AgentLifecycleResponse> startAgent(String agentName) async {
    startedAgentNames.add(agentName);
    return AgentLifecycleResponse(accepted: true, name: agentName);
  }

  @override
  Future<AgentLifecycleResponse> stopAgentProcess(String agentName) async {
    return AgentLifecycleResponse(accepted: true, name: agentName);
  }

  @override
  Future<SoulUpdateResponse> updateSoul({
    required String agentName,
    required String content,
    String mode = 'append',
  }) async {
    return SoulUpdateResponse(path: '/agents/$agentName/workspace/SOUL.md');
  }

  @override
  Future<CreateSessionResponse> createSession(String agentName) async {
    createdSessionAgentName = agentName;
    createdSessionAgentNames.add(agentName);
    createSessionCount += 1;
    return CreateSessionResponse(
      sessionId: sessionIdsByAgent[agentName] ?? createdSessionId,
      title: 'New chat',
      preview: '',
      createdAt: null,
      updatedAt: null,
      messageCount: 0,
      status: 'idle',
    );
  }

  @override
  Future<SessionListResponse> listSessions(String agentName) async {
    return SessionListResponse(object: 'list', data: sessions);
  }

  @override
  Future<AttachSessionResponse> attachSession({
    required String agentName,
    required String sessionId,
  }) async {
    attachedAgentName = agentName;
    attachedSessionId = sessionId;
    return AttachSessionResponse(sessionId: sessionId, attached: true);
  }

  @override
  Future<SessionMessages> getSessionMessages({
    required String agentName,
    required String sessionId,
  }) async {
    messagesAgentName = agentName;
    return messages;
  }

  @override
  Stream<AgentControlStreamEvent> sendMessageStream({
    required String agentName,
    required String sessionId,
    required String content,
    required CancelToken cancelToken,
  }) async* {
    sentAgentName = agentName;
    sentSessionId = sessionId;
    sentContent = content;
    for (final event in streamEvents) {
      yield event;
    }
  }

  @override
  Future<NonStreamMessageResponse> sendMessage({
    required String agentName,
    required String sessionId,
    required String content,
  }) async {
    return NonStreamMessageResponse(
      sessionId: sessionId,
      content: content,
      latencyMs: 1,
    );
  }

  @override
  Future<void> deleteSession({
    required String agentName,
    required String sessionId,
  }) async {}

  @override
  Future<void> stopAgentTask({
    required String agentName,
    String? sessionId,
  }) async {
    stoppedAgentName = agentName;
    stoppedSessionId = sessionId;
  }

  @override
  Future<AgentCommandListResponse> listCommands(String agentName) async {
    return const AgentCommandListResponse(object: 'list', data: []);
  }

  @override
  Future<AgentSettings> getSettings(String agentName) async {
    return AgentSettings.empty();
  }

  @override
  Future<AgentSettings> updateSettings({
    required String agentName,
    String? model,
    String? provider,
  }) async {
    return AgentSettings.empty();
  }

  @override
  Future<ResourceTree> getResourceTree({
    required String agentName,
    String path = '.',
  }) async {
    return ResourceTree(
      object: 'resources.tree',
      path: path,
      children: const [],
    );
  }

  @override
  Future<ResourceSearchResponse> searchResources({
    required String agentName,
    required String query,
    String path = '.',
    int limit = 100,
  }) async {
    return ResourceSearchResponse(object: 'list', query: query, data: const []);
  }

  @override
  Future<ResourceFile> getResourceFile({
    required String agentName,
    required String path,
  }) async {
    return ResourceFile(
      object: 'resources.file',
      path: path,
      size: 0,
      mtimeMs: 0,
      content: '',
    );
  }

  @override
  Future<ResourceFileWriteResult> putResourceFile({
    required String agentName,
    required String path,
    required String content,
  }) async {
    return ResourceFileWriteResult(
      object: 'resources.file',
      path: path,
      size: content.length,
      mtimeMs: 0,
    );
  }

  @override
  Future<GitStatus> getGitStatus(String agentName) async => GitStatus.empty();

  @override
  Future<GitDiff> getGitDiff({
    required String agentName,
    String path = '.',
  }) async {
    return GitDiff(object: 'git.diff', isRepo: true, path: path, diff: '');
  }
}
