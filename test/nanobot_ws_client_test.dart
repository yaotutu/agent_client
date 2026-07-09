import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:agent_client/features/nanobot/data/nanobot_ws_client.dart';
import 'package:agent_client/features/nanobot/data/protocol/nanobot_ws_envelope.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_bootstrap.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_config.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _WsHarness harness;

  setUp(() async {
    harness = await _WsHarness.start();
  });

  tearDown(() async {
    await harness.close();
  });

  NanobotWsClient client() {
    return NanobotWsClient(
      config: const NanobotConfig(baseUrl: 'http://127.0.0.1:8765', secret: ''),
      bootstrap: ({bool forceRefresh = false}) async => NanobotBootstrap(
        token: forceRefresh ? 'fresh-token' : 'token',
        wsPath: '/ws',
        wsUrl: harness.wsUrl,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      ),
      reconnectDelay: const Duration(milliseconds: 1),
    );
  }

  test('sends rich message frames through typed outbound envelopes', () async {
    final ws = client();
    addTearDown(ws.dispose);

    await ws.sendMessage(
      chatId: 'chat-1',
      content: 'hello',
      media: const [
        NanobotOutboundMedia(
          dataUrl: 'data:image/png;base64,abc',
          name: 'a.png',
        ),
      ],
      imageGeneration: const NanobotOutboundImageGeneration(aspectRatio: '1:1'),
      cliApps: const [NanobotOutboundMention(name: 'codex')],
      mcpPresets: const [
        NanobotOutboundMention(name: 'github', configured: true),
      ],
      workspaceScope: const {
        'project_path': '/tmp/app',
        'access_mode': 'restricted',
      },
      turnId: 'turn-1',
    );

    expect(await harness.nextFrame(), {'type': 'attach', 'chat_id': 'chat-1'});
    final frame = await harness.nextFrame();
    expect(frame['type'], 'message');
    expect(frame['chat_id'], 'chat-1');
    expect(frame['webui'], isTrue);
    expect((frame['media'] as List).single, {
      'data_url': 'data:image/png;base64,abc',
      'name': 'a.png',
    });
    expect(frame['image_generation'], {'enabled': true, 'aspect_ratio': '1:1'});
    expect((frame['cli_apps'] as List).single, {'name': 'codex'});
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

  test('sends media-only message frames', () async {
    final ws = client();
    addTearDown(ws.dispose);

    await ws.sendMessage(
      chatId: 'chat-1',
      content: '',
      media: const [
        NanobotOutboundMedia(
          dataUrl: 'data:image/png;base64,abc',
          name: 'screen.png',
        ),
      ],
    );

    expect(await harness.nextFrame(), {'type': 'attach', 'chat_id': 'chat-1'});
    final frame = await harness.nextFrame();
    expect(frame['type'], 'message');
    expect(frame['content'], '');
    expect((frame['media'] as List).single, {
      'data_url': 'data:image/png;base64,abc',
      'name': 'screen.png',
    });
  });

  test('supports fork chat and resolves on attached', () async {
    final ws = client();
    addTearDown(ws.dispose);

    final forked = ws.forkChat(
      sourceChatId: 'chat-1',
      beforeUserIndex: 3,
      title: 'Fork',
    );
    final frame = await harness.nextFrame();
    expect(frame, {
      'type': 'fork_chat',
      'source_chat_id': 'chat-1',
      'before_user_index': 3,
      'title': 'Fork',
    });

    harness.send({'event': 'attached', 'chat_id': 'chat-fork'});

    expect(await forked, 'chat-fork');
  });

  test('sends workspace scope frames and surfaces rejection errors', () async {
    final ws = client();
    addTearDown(ws.dispose);

    await ws.setWorkspaceScope(
      chatId: 'chat-1',
      workspaceScope: const {'project_path': '/tmp/app', 'access_mode': 'full'},
    );
    expect(await harness.nextFrame(), {'type': 'attach', 'chat_id': 'chat-1'});
    expect(await harness.nextFrame(), {
      'type': 'set_workspace_scope',
      'chat_id': 'chat-1',
      'workspace_scope': {'project_path': '/tmp/app', 'access_mode': 'full'},
    });

    final error = expectLater(
      ws.events,
      emits(
        isA<NanobotEvent>()
            .having((e) => e.kind, 'kind', NanobotEventKind.error)
            .having((e) => e.detail, 'detail', 'workspace_scope_rejected')
            .having((e) => e.reason, 'reason', 'outside workspace'),
      ),
    );
    harness.send({
      'event': 'error',
      'chat_id': 'chat-1',
      'detail': 'workspace_scope_rejected',
      'reason': 'outside workspace',
    });

    await error;
  });

  test('supports transcribe audio request lifecycle', () async {
    final ws = client();
    addTearDown(ws.dispose);

    final result = ws.transcribeAudio(
      requestId: 'req-1',
      dataUrl: 'data:audio/webm;base64,abc',
      durationMs: 500,
    );
    expect(await harness.nextFrame(), {
      'type': 'transcribe_audio',
      'request_id': 'req-1',
      'data_url': 'data:audio/webm;base64,abc',
      'duration_ms': 500,
    });

    harness.send({
      'event': 'transcription_result',
      'request_id': 'req-1',
      'text': 'hello',
    });

    expect(await result, 'hello');
  });

  test('maps websocket close code 1009 to message_too_big error', () async {
    final ws = client();
    addTearDown(ws.dispose);

    await ws.connect();
    final error = expectLater(
      ws.events,
      emits(
        isA<NanobotEvent>()
            .having((e) => e.kind, 'kind', NanobotEventKind.error)
            .having((e) => e.detail, 'detail', 'message_too_big'),
      ),
    );
    await harness.closeSocket(WebSocketStatus.messageTooBig, 'too big');

    await error;
  });

  test('ignores malformed inbound frames and keeps reading', () async {
    final ws = client();
    addTearDown(ws.dispose);

    await ws.connect();

    final event = expectLater(
      ws.events,
      emits(
        isA<NanobotEvent>()
            .having((e) => e.kind, 'kind', NanobotEventKind.delta)
            .having((e) => e.chatId, 'chatId', 'chat-1')
            .having((e) => e.text, 'text', 'still alive'),
      ),
    );

    harness.sendRaw('not json');
    harness.send({
      'event': 'delta',
      'chat_id': 'chat-1',
      'text': 'still alive',
    });

    await event;
    expect(ws.currentStatus, NanobotSocketStatus.open);
  });

  test(
    'replays pending inbound frames when chat stream subscribes later',
    () async {
      final ws = client();
      addTearDown(ws.dispose);
      await ws.connect();

      harness.send({
        'event': 'delta',
        'chat_id': 'chat-late',
        'text': 'buffered',
      });

      await expectLater(
        ws.eventsForChat('chat-late'),
        emits(
          isA<NanobotEvent>()
              .having((event) => event.kind, 'kind', NanobotEventKind.delta)
              .having((event) => event.text, 'text', 'buffered'),
        ),
      );
    },
  );

  test('reauths and reattaches known chats after a dropped socket', () async {
    final ws = client();
    addTearDown(ws.dispose);

    await ws.attach('chat-1');
    expect(await harness.nextFrame(), {'type': 'attach', 'chat_id': 'chat-1'});
    expect(harness.requestedUris.single.queryParameters['token'], 'token');

    final reconnecting = expectLater(
      ws.status,
      emits(NanobotSocketStatus.reconnecting),
    );
    await harness.closeSocket(WebSocketStatus.normalClosure, 'bye');
    await reconnecting;

    expect(await harness.nextFrame(), {'type': 'attach', 'chat_id': 'chat-1'});
    expect(harness.requestedUris.last.queryParameters['token'], 'fresh-token');
  });
}

class _WsHarness {
  _WsHarness._(this._server, this.wsUrl);

  final HttpServer _server;
  final String wsUrl;
  final _pendingFrames = Queue<Map<String, Object?>>();
  final _frameWaiters = Queue<Completer<Map<String, Object?>>>();
  final requestedUris = <Uri>[];
  WebSocket? _socket;

  static Future<_WsHarness> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final harness = _WsHarness._(
      server,
      'ws://${server.address.address}:${server.port}/ws',
    );
    unawaited(harness._serve());
    return harness;
  }

  Future<Map<String, Object?>> nextFrame() {
    if (_pendingFrames.isNotEmpty) {
      return Future.value(_pendingFrames.removeFirst());
    }
    final completer = Completer<Map<String, Object?>>();
    _frameWaiters.add(completer);
    return completer.future.timeout(const Duration(seconds: 2));
  }

  void send(Map<String, Object?> frame) {
    _socket?.add(jsonEncode(frame));
  }

  void sendRaw(String frame) {
    _socket?.add(frame);
  }

  Future<void> closeSocket(int code, String reason) async {
    await _socket?.close(code, reason);
  }

  Future<void> close() async {
    await _socket?.close();
    for (final waiter in _frameWaiters) {
      if (!waiter.isCompleted) {
        waiter.completeError(StateError('harness closed'));
      }
    }
    _frameWaiters.clear();
    _pendingFrames.clear();
    await _server.close(force: true);
  }

  Future<void> _serve() async {
    await for (final request in _server) {
      if (!WebSocketTransformer.isUpgradeRequest(request)) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        continue;
      }
      requestedUris.add(request.uri);
      final socket = await WebSocketTransformer.upgrade(request);
      _socket = socket;
      socket.listen((raw) {
        if (raw is! String) return;
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final frame = Map<String, Object?>.from(decoded);
          if (_frameWaiters.isNotEmpty) {
            _frameWaiters.removeFirst().complete(frame);
          } else {
            _pendingFrames.add(frame);
          }
        }
      });
    }
  }
}
