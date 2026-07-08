import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:agent_client/features/nanobot/domain/nanobot_bootstrap.dart';
import 'package:agent_client/features/nanobot/data/protocol/nanobot_ws_envelope.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_config.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_event.dart';

enum NanobotSocketStatus { idle, connecting, open, reconnecting, closed, error }

class NanobotWsClient {
  NanobotWsClient({
    required this.config,
    required this.bootstrap,
    this.reconnect = true,
    this.reconnectDelay = const Duration(milliseconds: 500),
    this.maxReconnectDelay = const Duration(seconds: 15),
  });

  final NanobotConfig config;
  final Future<NanobotBootstrap> Function({bool forceRefresh}) bootstrap;
  final bool reconnect;
  final Duration reconnectDelay;
  final Duration maxReconnectDelay;
  final _events = StreamController<NanobotEvent>.broadcast();
  final _status = StreamController<NanobotSocketStatus>.broadcast();
  final _knownChats = <String>{};
  final _sendQueue = <Map<String, Object?>>[];
  final _pendingTranscriptions = <String, Completer<String>>{};
  final _chatStreams = <String, StreamController<NanobotEvent>>{};
  final _chatListenerCounts = <String, int>{};
  final _pendingInboundByChat = <String, List<NanobotEvent>>{};
  static const _pendingInboundMax = 2000;

  WebSocket? _socket;
  Timer? _reconnectTimer;
  Completer<String>? _pendingChatRequest;
  NanobotSocketStatus _currentStatus = NanobotSocketStatus.idle;
  int _reconnectAttempts = 0;
  bool _intentionallyClosed = false;

  Stream<NanobotEvent> get events => _events.stream;

  Stream<NanobotSocketStatus> get status => _status.stream;

  NanobotSocketStatus get currentStatus => _currentStatus;

  Stream<NanobotEvent> eventsForChat(String chatId) {
    final trimmed = chatId.trim();
    if (trimmed.isEmpty) {
      return const Stream<NanobotEvent>.empty();
    }
    final existing = _chatStreams[trimmed];
    if (existing != null) {
      return existing.stream;
    }

    late final StreamController<NanobotEvent> controller;
    controller = StreamController<NanobotEvent>.broadcast(
      onListen: () {
        _chatListenerCounts[trimmed] = (_chatListenerCounts[trimmed] ?? 0) + 1;
        scheduleMicrotask(() {
          final pending = _pendingInboundByChat.remove(trimmed);
          if (pending == null || controller.isClosed) {
            return;
          }
          for (final event in pending) {
            controller.add(event);
          }
        });
      },
      onCancel: () {
        final next = (_chatListenerCounts[trimmed] ?? 1) - 1;
        if (next <= 0) {
          _chatListenerCounts.remove(trimmed);
        } else {
          _chatListenerCounts[trimmed] = next;
        }
      },
    );
    _chatStreams[trimmed] = controller;
    return controller.stream;
  }

  Future<void> connect({bool forceRefresh = false}) async {
    final existing = _socket;
    if (existing != null && existing.readyState == WebSocket.open) {
      return;
    }

    _intentionallyClosed = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _setStatus(NanobotSocketStatus.connecting);
    try {
      final token = await bootstrap(forceRefresh: forceRefresh);
      final socket = await WebSocket.connect(_wsUrl(token));
      _socket = socket;
      _reconnectAttempts = 0;
      _setStatus(NanobotSocketStatus.open);
      for (final chatId in _knownChats) {
        _rawSend(NanobotOutboundEnvelope.attach(chatId: chatId).toJson());
      }
      final queued = List<Map<String, Object?>>.from(_sendQueue);
      _sendQueue.clear();
      for (final frame in queued) {
        _rawSend(frame);
      }
      unawaited(_read(socket));
    } on Object {
      _setStatus(NanobotSocketStatus.error);
      rethrow;
    }
  }

  Future<String> newChat({Map<String, Object?>? workspaceScope}) async {
    await connect();
    if (_pendingChatRequest != null) {
      throw StateError('new_chat already in flight');
    }
    final completer = Completer<String>();
    _pendingChatRequest = completer;
    _queueSend(
      NanobotOutboundEnvelope.newChat(workspaceScope: workspaceScope).toJson(),
    );
    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        if (identical(_pendingChatRequest, completer)) {
          _pendingChatRequest = null;
        }
        throw TimeoutException('new_chat timed out');
      },
    );
  }

  Future<void> attach(String chatId) async {
    final trimmed = chatId.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final wasOpen = _socket?.readyState == WebSocket.open;
    _knownChats.add(trimmed);
    await connect();
    if (wasOpen) {
      _queueSend(NanobotOutboundEnvelope.attach(chatId: trimmed).toJson());
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String content,
    List<NanobotOutboundMedia> media = const [],
    NanobotOutboundImageGeneration? imageGeneration,
    List<NanobotOutboundMention> cliApps = const [],
    List<NanobotOutboundMention> mcpPresets = const [],
    Map<String, Object?>? workspaceScope,
    String? turnId,
  }) async {
    final trimmedChatId = chatId.trim();
    final trimmedContent = content.trim();
    if (trimmedChatId.isEmpty || (trimmedContent.isEmpty && media.isEmpty)) {
      return;
    }
    _knownChats.add(trimmedChatId);
    await connect();
    _queueSend(
      NanobotOutboundEnvelope.message(
        chatId: trimmedChatId,
        content: trimmedContent,
        media: media,
        imageGeneration: imageGeneration,
        cliApps: cliApps,
        mcpPresets: mcpPresets,
        workspaceScope: workspaceScope,
        turnId: turnId,
      ).toJson(),
    );
  }

  Future<String> forkChat({
    required String sourceChatId,
    required int beforeUserIndex,
    String? title,
  }) async {
    final trimmed = sourceChatId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(sourceChatId, 'sourceChatId');
    }
    await connect();
    if (_pendingChatRequest != null) {
      throw StateError('chat creation already in flight');
    }
    final completer = Completer<String>();
    _pendingChatRequest = completer;
    _queueSend(
      NanobotOutboundEnvelope.forkChat(
        sourceChatId: trimmed,
        beforeUserIndex: beforeUserIndex,
        title: title,
      ).toJson(),
    );
    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        if (identical(_pendingChatRequest, completer)) {
          _pendingChatRequest = null;
        }
        throw TimeoutException('fork_chat timed out');
      },
    );
  }

  Future<void> setWorkspaceScope({
    required String chatId,
    required Map<String, Object?> workspaceScope,
  }) async {
    final trimmed = chatId.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _knownChats.add(trimmed);
    await connect();
    _queueSend(
      NanobotOutboundEnvelope.setWorkspaceScope(
        chatId: trimmed,
        workspaceScope: workspaceScope,
      ).toJson(),
    );
  }

  Future<String> transcribeAudio({
    required String requestId,
    required String dataUrl,
    int? durationMs,
  }) async {
    final trimmedRequestId = requestId.trim();
    final trimmedDataUrl = dataUrl.trim();
    if (trimmedRequestId.isEmpty || trimmedDataUrl.isEmpty) {
      throw ArgumentError('requestId and dataUrl are required');
    }
    await connect();
    if (_pendingTranscriptions.containsKey(trimmedRequestId)) {
      throw StateError('transcription already in flight');
    }
    final completer = Completer<String>();
    _pendingTranscriptions[trimmedRequestId] = completer;
    _queueSend(
      NanobotOutboundEnvelope.transcribeAudio(
        requestId: trimmedRequestId,
        dataUrl: trimmedDataUrl,
        durationMs: durationMs,
      ).toJson(),
    );
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _pendingTranscriptions.remove(trimmedRequestId);
        throw TimeoutException('transcribe_audio timed out');
      },
    );
  }

  Future<void> close() async {
    _intentionallyClosed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final socket = _socket;
    _socket = null;
    await socket?.close();
    _setStatus(NanobotSocketStatus.closed);
  }

  Future<void> dispose() async {
    await close();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    for (final controller in _chatStreams.values) {
      await controller.close();
    }
    _chatStreams.clear();
    _chatListenerCounts.clear();
    _pendingInboundByChat.clear();
    await _events.close();
    await _status.close();
  }

  Future<void> _read(WebSocket socket) async {
    var failed = false;
    try {
      await for (final raw in socket) {
        if (raw is! String) {
          continue;
        }
        final decoded = jsonDecode(raw);
        if (decoded is! Map) {
          continue;
        }
        final event = NanobotEvent.fromJson(Map<String, Object?>.from(decoded));
        if (event.kind == NanobotEventKind.ready && event.chatId != null) {
          _knownChats.add(event.chatId!);
        }
        if (event.kind == NanobotEventKind.attached && event.chatId != null) {
          _knownChats.add(event.chatId!);
          final pending = _pendingChatRequest;
          if (pending != null && !pending.isCompleted) {
            pending.complete(event.chatId);
            _pendingChatRequest = null;
          }
        }
        if (event.kind == NanobotEventKind.transcriptionResult &&
            event.requestId != null) {
          final pending = _pendingTranscriptions.remove(event.requestId);
          if (pending != null && !pending.isCompleted) {
            pending.complete(event.text ?? '');
          }
        }
        if (event.kind == NanobotEventKind.transcriptionError &&
            event.requestId != null) {
          final pending = _pendingTranscriptions.remove(event.requestId);
          if (pending != null && !pending.isCompleted) {
            pending.completeError(
              StateError(event.detail ?? 'transcription failed'),
            );
          }
        }
        if (event.kind == NanobotEventKind.error &&
            event.detail == 'workspace_scope_rejected') {
          final pending = _pendingChatRequest;
          if (pending != null && !pending.isCompleted) {
            pending.completeError(
              StateError('workspace_scope_rejected:${event.reason ?? ''}'),
            );
            _pendingChatRequest = null;
          }
        }
        _emitEvent(event);
      }
    } on Object {
      failed = true;
      _setStatus(NanobotSocketStatus.error);
    } finally {
      if (identical(_socket, socket)) {
        _socket = null;
      }
      if (socket.closeCode == WebSocketStatus.messageTooBig) {
        _events.add(
          const NanobotEvent(
            kind: NanobotEventKind.error,
            rawEvent: 'error',
            detail: 'message_too_big',
          ),
        );
      }
      final pending = _pendingChatRequest;
      if (pending != null && !pending.isCompleted) {
        pending.completeError(StateError('nanobot socket closed'));
        _pendingChatRequest = null;
      }
      for (final pending in _pendingTranscriptions.values) {
        if (!pending.isCompleted) {
          pending.completeError(StateError('nanobot socket closed'));
        }
      }
      _pendingTranscriptions.clear();
      if (_intentionallyClosed || !reconnect) {
        _setStatus(
          failed ? NanobotSocketStatus.error : NanobotSocketStatus.closed,
        );
      } else {
        _scheduleReconnect();
      }
    }
  }

  void _scheduleReconnect() {
    _setStatus(NanobotSocketStatus.reconnecting);
    final attempt = _reconnectAttempts++;
    final baseMs = reconnectDelay.inMilliseconds;
    final maxMs = maxReconnectDelay.inMilliseconds;
    final delayMs = baseMs <= 0
        ? 0
        : (baseMs * (1 << attempt)).clamp(baseMs, maxMs);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
      _reconnectTimer = null;
      unawaited(connect(forceRefresh: true));
    });
  }

  void _emitEvent(NanobotEvent event) {
    _events.add(event);
    final chatId = event.chatId;
    if (chatId == null || chatId.isEmpty) {
      return;
    }
    final controller = _chatStreams[chatId];
    if (controller != null && (_chatListenerCounts[chatId] ?? 0) > 0) {
      controller.add(event);
      return;
    }

    final pending = _pendingInboundByChat.putIfAbsent(chatId, () => []);
    pending.add(event);
    if (pending.length > _pendingInboundMax) {
      pending.removeRange(0, pending.length - _pendingInboundMax);
    }
  }

  void _queueSend(Map<String, Object?> frame) {
    final socket = _socket;
    if (socket == null || socket.readyState != WebSocket.open) {
      _sendQueue.add(frame);
      return;
    }
    _rawSend(frame);
  }

  void _rawSend(Map<String, Object?> frame) {
    _socket?.add(jsonEncode(frame));
  }

  String _wsUrl(NanobotBootstrap bootstrap) {
    final raw = bootstrap.wsUrl?.trim().isNotEmpty == true
        ? bootstrap.wsUrl!.trim()
        : _fallbackWsUrl(bootstrap.wsPath);
    final uri = Uri.parse(raw);
    final params = Map<String, String>.from(uri.queryParameters);
    params['token'] = bootstrap.token;
    params['client_id'] = 'flutter-${DateTime.now().millisecondsSinceEpoch}';
    return uri.replace(queryParameters: params).toString();
  }

  String _fallbackWsUrl(String wsPath) {
    final base = Uri.parse(config.baseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    final path = wsPath.startsWith('/') ? wsPath : '/$wsPath';
    return base.replace(scheme: scheme, path: path, query: '').toString();
  }

  void _setStatus(NanobotSocketStatus status) {
    if (_currentStatus == status) {
      return;
    }
    _currentStatus = status;
    _status.add(status);
  }
}
