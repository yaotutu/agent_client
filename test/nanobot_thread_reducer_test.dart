import 'package:agent_client/features/nanobot/application/nanobot_thread_reducer.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_event.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_thread_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  NanobotThreadState reduceAll(List<Map<String, Object?>> frames) {
    var state = const NanobotThreadState(
      sessionKey: 'websocket:chat-1',
      chatId: 'chat-1',
    );
    for (final frame in frames) {
      state = NanobotThreadReducer.reduce(state, NanobotEvent.fromJson(frame));
    }
    return state;
  }

  test('delta frames create and extend a streaming assistant entry', () {
    final state = reduceAll([
      {'event': 'delta', 'chat_id': 'chat-1', 'text': 'hel', 'turn_id': 't1'},
      {'event': 'delta', 'chat_id': 'chat-1', 'text': 'lo', 'turn_id': 't1'},
    ]);

    expect(state.isStreaming, isTrue);
    expect(state.entries, hasLength(1));
    expect(state.entries.single.kind, NanobotThreadEntryKind.message);
    expect(state.entries.single.role, NanobotThreadRole.assistant);
    expect(state.entries.single.content, 'hello');
    expect(state.entries.single.isStreaming, isTrue);
    expect(state.entries.single.turnId, 't1');
  });

  test('reasoning frames preserve reasoning streaming state', () {
    final state = reduceAll([
      {
        'event': 'reasoning_delta',
        'chat_id': 'chat-1',
        'text': 'thinking',
        'turn_id': 't1',
      },
      {'event': 'reasoning_end', 'chat_id': 'chat-1'},
    ]);

    expect(state.entries, hasLength(1));
    expect(state.entries.single.reasoning, 'thinking');
    expect(state.entries.single.reasoningStreaming, isFalse);
  });

  test(
    'tool hint messages become trace entries and merge consecutive traces',
    () {
      final state = reduceAll([
        {
          'event': 'message',
          'chat_id': 'chat-1',
          'kind': 'tool_hint',
          'text': 'read file',
          'tool_events': [
            {'name': 'read_file', 'phase': 'start'},
          ],
        },
        {
          'event': 'message',
          'chat_id': 'chat-1',
          'kind': 'progress',
          'text': 'write file',
          'tool_events': [
            {'name': 'write_file', 'phase': 'end'},
          ],
        },
      ]);

      expect(state.entries, hasLength(1));
      final trace = state.entries.single;
      expect(trace.kind, NanobotThreadEntryKind.trace);
      expect(trace.traces, ['read file', 'write file']);
      expect(trace.toolEvents.map((event) => event['name']), [
        'read_file',
        'write_file',
      ]);
    },
  );

  test('file edit frames preserve edit payloads', () {
    final state = reduceAll([
      {
        'event': 'file_edit',
        'chat_id': 'chat-1',
        'edits': [
          {
            'call_id': 'call-1',
            'tool': 'write_file',
            'path': 'lib/main.dart',
            'added': 3,
            'deleted': 1,
            'status': 'done',
          },
        ],
      },
    ]);

    expect(state.entries, hasLength(1));
    expect(state.entries.single.kind, NanobotThreadEntryKind.fileEdit);
    expect(state.entries.single.fileEdits.single['path'], 'lib/main.dart');
  });

  test('message frames preserve media attachments', () {
    final state = reduceAll([
      {
        'event': 'message',
        'chat_id': 'chat-1',
        'text': 'diagram',
        'media_urls': [
          {'kind': 'image', 'url': '/api/media/sig/payload', 'name': 'Diagram'},
        ],
      },
    ]);

    expect(state.entries, hasLength(1));
    expect(state.entries.single.media, hasLength(1));
    expect(state.entries.single.media.single.kind, 'image');
    expect(state.entries.single.media.single.url, '/api/media/sig/payload');
    expect(state.entries.single.media.single.name, 'Diagram');
  });

  test('goal status and turn end update run and goal snapshots', () {
    final state = reduceAll([
      {
        'event': 'goal_status',
        'chat_id': 'chat-1',
        'status': 'running',
        'started_at': 42,
      },
      {'event': 'delta', 'chat_id': 'chat-1', 'text': 'done'},
      {
        'event': 'turn_end',
        'chat_id': 'chat-1',
        'latency_ms': 120,
        'goal_state': {
          'active': false,
          'ui_summary': 'Complete',
          'objective': 'Ship',
        },
      },
    ]);

    expect(state.isStreaming, isFalse);
    expect(state.runStartedAt, isNull);
    expect(state.goalState?['objective'], 'Ship');
    expect(state.entries.single.isStreaming, isFalse);
    expect(state.entries.single.latencyMs, 120);
  });
}
