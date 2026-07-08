import 'package:agent_client/features/nanobot/data/protocol/nanobot_ws_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NanobotInboundEnvelope', () {
    test('preserves rich message frames', () {
      final envelope = NanobotInboundEnvelope.fromJson({
        'event': 'message',
        'chat_id': 'chat-1',
        'text': 'answer',
        'reply_to': 'user-1',
        'media': ['media/path.png'],
        'media_urls': [
          {'url': '/api/media/a', 'name': 'a.png'},
        ],
        'tool_events': [
          {
            'phase': 'start',
            'call_id': 'call-1',
            'name': 'read_file',
            'arguments': {'path': 'README.md'},
          },
        ],
        'kind': 'tool_hint',
        'latency_ms': 1234,
        'source': {'kind': 'cron', 'label': 'Daily'},
        'agent_ui': {
          'kind': 'timeline',
          'data': {'count': 1},
        },
        'turn_id': 'turn-1',
        'turn_phase': 'activity',
        'turn_seq': 7,
      });

      expect(envelope.type, NanobotInboundEventType.message);
      expect(envelope.chatId, 'chat-1');
      expect(envelope.text, 'answer');
      expect(envelope.replyTo, 'user-1');
      expect(envelope.media, ['media/path.png']);
      expect(envelope.mediaUrls.single['name'], 'a.png');
      expect(envelope.toolEvents.single['name'], 'read_file');
      expect(envelope.kind, 'tool_hint');
      expect(envelope.latencyMs, 1234);
      expect(envelope.source?['kind'], 'cron');
      expect(envelope.agentUi?['kind'], 'timeline');
      expect(envelope.turnId, 'turn-1');
      expect(envelope.turnPhase, 'activity');
      expect(envelope.turnSeq, 7);
    });

    test('preserves file edit frames', () {
      final envelope = NanobotInboundEnvelope.fromJson({
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
        'turn_id': 'turn-1',
      });

      expect(envelope.type, NanobotInboundEventType.fileEdit);
      expect(envelope.fileEdits.single['path'], 'lib/main.dart');
      expect(envelope.fileEdits.single['added'], 3);
      expect(envelope.turnId, 'turn-1');
    });

    test('preserves goal state snapshots', () {
      final goalState = {
        'active': true,
        'ui_summary': 'Working',
        'objective': 'Finish task',
      };
      final goalEnvelope = NanobotInboundEnvelope.fromJson({
        'event': 'goal_state',
        'chat_id': 'chat-1',
        'goal_state': goalState,
      });
      final turnEnvelope = NanobotInboundEnvelope.fromJson({
        'event': 'turn_end',
        'chat_id': 'chat-1',
        'latency_ms': 90,
        'goal_state': goalState,
      });

      expect(goalEnvelope.type, NanobotInboundEventType.goalState);
      expect(goalEnvelope.goalState?['objective'], 'Finish task');
      expect(turnEnvelope.type, NanobotInboundEventType.turnEnd);
      expect(turnEnvelope.latencyMs, 90);
      expect(turnEnvelope.goalState?['ui_summary'], 'Working');
    });

    test('preserves transcription frames', () {
      final result = NanobotInboundEnvelope.fromJson({
        'event': 'transcription_result',
        'request_id': 'req-1',
        'text': 'hello',
      });
      final error = NanobotInboundEnvelope.fromJson({
        'event': 'transcription_error',
        'request_id': 'req-2',
        'detail': 'failed',
        'provider': 'openai',
      });

      expect(result.type, NanobotInboundEventType.transcriptionResult);
      expect(result.requestId, 'req-1');
      expect(result.text, 'hello');
      expect(error.type, NanobotInboundEventType.transcriptionError);
      expect(error.requestId, 'req-2');
      expect(error.detail, 'failed');
      expect(error.provider, 'openai');
    });
  });

  group('NanobotOutboundEnvelope', () {
    test('serializes rich message frames', () {
      final frame = NanobotOutboundEnvelope.message(
        chatId: 'chat-1',
        content: 'hello',
        media: const [
          NanobotOutboundMedia(
            dataUrl: 'data:image/png;base64,abc',
            name: 'a.png',
          ),
        ],
        imageGeneration: const NanobotOutboundImageGeneration(
          aspectRatio: '1:1',
        ),
        cliApps: const [
          NanobotOutboundMention(name: 'codex', displayName: 'Codex'),
        ],
        mcpPresets: const [
          NanobotOutboundMention(name: 'github', configured: true),
        ],
        workspaceScope: const {
          'project_path': '/tmp/app',
          'access_mode': 'restricted',
        },
        turnId: 'turn-1',
      ).toJson();

      expect(frame['type'], 'message');
      expect(frame['chat_id'], 'chat-1');
      expect(frame['content'], 'hello');
      expect(frame['webui'], isTrue);
      expect((frame['media'] as List).single, {
        'data_url': 'data:image/png;base64,abc',
        'name': 'a.png',
      });
      expect(frame['image_generation'], {
        'enabled': true,
        'aspect_ratio': '1:1',
      });
      expect((frame['cli_apps'] as List).single, {
        'name': 'codex',
        'display_name': 'Codex',
      });
      expect((frame['mcp_presets'] as List).single, {
        'name': 'github',
        'configured': true,
      });
      expect(frame['workspace_scope'], {
        'project_path': '/tmp/app',
        'access_mode': 'restricted',
      });
      expect(frame['turn_id'], 'turn-1');
    });

    test('serializes fork, workspace, and transcription frames', () {
      expect(
        NanobotOutboundEnvelope.forkChat(
          sourceChatId: 'chat-1',
          beforeUserIndex: 3,
          title: 'Fork',
        ).toJson(),
        {
          'type': 'fork_chat',
          'source_chat_id': 'chat-1',
          'before_user_index': 3,
          'title': 'Fork',
        },
      );
      expect(
        NanobotOutboundEnvelope.setWorkspaceScope(
          chatId: 'chat-1',
          workspaceScope: const {
            'project_path': '/tmp/app',
            'access_mode': 'full',
          },
        ).toJson(),
        {
          'type': 'set_workspace_scope',
          'chat_id': 'chat-1',
          'workspace_scope': {
            'project_path': '/tmp/app',
            'access_mode': 'full',
          },
        },
      );
      expect(
        NanobotOutboundEnvelope.transcribeAudio(
          requestId: 'req-1',
          dataUrl: 'data:audio/webm;base64,abc',
          durationMs: 500,
        ).toJson(),
        {
          'type': 'transcribe_audio',
          'request_id': 'req-1',
          'data_url': 'data:audio/webm;base64,abc',
          'duration_ms': 500,
        },
      );
    });
  });
}
