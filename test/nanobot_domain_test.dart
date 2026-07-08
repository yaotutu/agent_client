import 'package:agent_client/features/nanobot/application/nanobot_workspace_state.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_bootstrap.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_event.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_message.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_shell_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bootstrap maps token and expiry', () {
    final before = DateTime.now();

    final bootstrap = NanobotBootstrap.fromJson({
      'token': 'nbwt_token',
      'ws_path': '/',
      'ws_url': 'ws://127.0.0.1:8765/',
      'expires_in': 300,
      'model_name': 'MiniMax-M3',
      'runtime_surface': 'browser',
    });

    expect(bootstrap.token, 'nbwt_token');
    expect(bootstrap.wsPath, '/');
    expect(bootstrap.wsUrl, 'ws://127.0.0.1:8765/');
    expect(bootstrap.modelName, 'MiniMax-M3');
    expect(bootstrap.runtimeSurface, 'browser');
    expect(bootstrap.expiresAt.isAfter(before), isTrue);
  });

  test('session summary splits websocket session key', () {
    final session = NanobotSessionSummary.fromJson({
      'key': 'websocket:chat-123',
      'title': '',
      'preview': 'hello',
      'created_at': '2026-07-08T10:00:00Z',
      'updated_at': '2026-07-08T10:05:00Z',
      'run_started_at': 123,
    });

    expect(session.channel, 'websocket');
    expect(session.chatId, 'chat-123');
    expect(session.displayTitle, 'hello');
    expect(session.runStartedAt, 123);
  });

  test('workspace state sorts visible sessions by displayed title', () {
    final state = NanobotWorkspaceState(
      sessions: [
        NanobotSessionSummary(
          key: 'websocket:zulu',
          channel: 'websocket',
          chatId: 'zulu',
          title: 'Zulu work',
          preview: 'later',
          createdAt: DateTime.utc(2026, 4, 16, 12),
          updatedAt: DateTime.utc(2026, 4, 16, 12),
        ),
        NanobotSessionSummary(
          key: 'websocket:new',
          channel: 'websocket',
          chatId: 'new',
          title: '',
          preview: 'hi nanobot',
          createdAt: DateTime.utc(2026, 4, 15, 12),
          updatedAt: DateTime.utc(2026, 4, 15, 12),
        ),
        NanobotSessionSummary(
          key: 'websocket:alpha',
          channel: 'websocket',
          chatId: 'alpha',
          title: 'Alpha plan',
          preview: 'earlier',
          createdAt: DateTime.utc(2026, 4, 14, 12),
          updatedAt: DateTime.utc(2026, 4, 14, 12),
        ),
      ],
      sidebarState: const NanobotSidebarState(
        sort: 'title_asc',
        titleOverrides: {'websocket:new': 'Beta fallback'},
      ),
    );

    expect(state.visibleSessions.map((session) => session.key), [
      'websocket:alpha',
      'websocket:new',
      'websocket:zulu',
    ]);
  });

  test('workspace state uses natural title sort and created date sort', () {
    final sessions = [
      NanobotSessionSummary(
        key: 'websocket:chat-10',
        channel: 'websocket',
        chatId: 'chat-10',
        title: 'Chat 10',
        preview: '',
        createdAt: DateTime.utc(2026, 4, 14, 12),
        updatedAt: DateTime.utc(2026, 4, 16, 12),
      ),
      NanobotSessionSummary(
        key: 'websocket:chat-2',
        channel: 'websocket',
        chatId: 'chat-2',
        title: 'Chat 2',
        preview: '',
        createdAt: DateTime.utc(2026, 4, 16, 12),
        updatedAt: DateTime.utc(2026, 4, 14, 12),
      ),
    ];

    expect(
      NanobotWorkspaceState(
        sessions: sessions,
        sidebarState: const NanobotSidebarState(sort: 'title_asc'),
      ).visibleSessions.map((session) => session.key),
      ['websocket:chat-2', 'websocket:chat-10'],
    );
    expect(
      NanobotWorkspaceState(
        sessions: sessions,
        sidebarState: const NanobotSidebarState(sort: 'created_desc'),
      ).visibleSessions.map((session) => session.key),
      ['websocket:chat-2', 'websocket:chat-10'],
    );
  });

  test('webui thread messages map UIMessage shape', () {
    final message = NanobotMessage.fromWebuiJson(
      json: {
        'id': 'm1',
        'role': 'assistant',
        'content': 'answer',
        'reasoning': 'thinking',
        'createdAt': 1783490000000,
      },
      sessionKey: 'websocket:chat-1',
      chatId: 'chat-1',
    );

    expect(message.id, 'm1');
    expect(message.role, NanobotMessageRole.assistant);
    expect(message.content, 'answer');
    expect(message.reasoning, 'thinking');
    expect(message.sessionKey, 'websocket:chat-1');
  });

  test('webui thread messages preserve media attachments', () {
    final message = NanobotMessage.fromWebuiJson(
      json: {
        'id': 'm-media',
        'role': 'assistant',
        'content': 'diagram',
        'media': [
          {'kind': 'image', 'url': '/api/media/sig/payload', 'name': 'Diagram'},
        ],
      },
      sessionKey: 'websocket:chat-1',
      chatId: 'chat-1',
    );

    expect(message.media, hasLength(1));
    expect(message.media.single.kind, 'image');
    expect(message.media.single.url, '/api/media/sig/payload');
    expect(message.media.single.name, 'Diagram');
  });

  test('websocket event mapper keeps key live event fields', () {
    final delta = NanobotEvent.fromJson({
      'event': 'delta',
      'chat_id': 'chat-1',
      'text': 'chunk',
      'stream_id': 'stream-1',
      'turn_id': 'turn-1',
      'turn_phase': 'answer',
      'turn_seq': 2,
    });
    final goalStatus = NanobotEvent.fromJson({
      'event': 'goal_status',
      'chat_id': 'chat-1',
      'status': 'running',
      'started_at': 42,
    });
    final message = NanobotEvent.fromJson({
      'event': 'message',
      'chat_id': 'chat-1',
      'text': 'Using tools',
      'kind': 'tool_hint',
      'latency_ms': 120,
      'tool_events': [
        {'name': 'read_file', 'phase': 'start'},
      ],
      'source': {'kind': 'cron'},
    });

    expect(delta.kind, NanobotEventKind.delta);
    expect(delta.chatId, 'chat-1');
    expect(delta.text, 'chunk');
    expect(delta.streamId, 'stream-1');
    expect(delta.turnId, 'turn-1');
    expect(delta.turnPhase, 'answer');
    expect(delta.turnSeq, 2);
    expect(goalStatus.kind, NanobotEventKind.goalStatus);
    expect(goalStatus.status, 'running');
    expect(goalStatus.startedAt, 42);
    expect(message.kind, NanobotEventKind.message);
    expect(message.kindLabel, 'tool_hint');
    expect(message.latencyMs, 120);
    expect(message.toolEvents.single['name'], 'read_file');
    expect(message.source?['kind'], 'cron');
  });
}
