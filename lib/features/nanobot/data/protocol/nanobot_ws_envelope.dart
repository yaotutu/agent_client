enum NanobotInboundEventType {
  ready,
  attached,
  message,
  fileEdit,
  delta,
  streamEnd,
  reasoningDelta,
  reasoningEnd,
  runtimeModelUpdated,
  turnEnd,
  goalStatus,
  goalState,
  sessionUpdated,
  transcriptionResult,
  transcriptionError,
  error,
  unknown,
}

class NanobotInboundEnvelope {
  const NanobotInboundEnvelope({
    required this.type,
    required this.rawEvent,
    this.chatId,
    this.clientId,
    this.text,
    this.replyTo,
    this.streamId,
    this.kind,
    this.detail,
    this.reason,
    this.provider,
    this.modelName,
    this.modelPreset,
    this.status,
    this.scope,
    this.requestId,
    this.startedAt,
    this.latencyMs,
    this.turnSeq,
    this.turnId,
    this.turnPhase,
    this.media = const [],
    this.mediaUrls = const [],
    this.toolEvents = const [],
    this.fileEdits = const [],
    this.source,
    this.agentUi,
    this.goalState,
    this.workspaceScope,
  });

  final NanobotInboundEventType type;
  final String rawEvent;
  final String? chatId;
  final String? clientId;
  final String? text;
  final String? replyTo;
  final String? streamId;
  final String? kind;
  final String? detail;
  final String? reason;
  final String? provider;
  final String? modelName;
  final String? modelPreset;
  final String? status;
  final String? scope;
  final String? requestId;
  final int? startedAt;
  final int? latencyMs;
  final int? turnSeq;
  final String? turnId;
  final String? turnPhase;
  final List<String> media;
  final List<Map<String, Object?>> mediaUrls;
  final List<Map<String, Object?>> toolEvents;
  final List<Map<String, Object?>> fileEdits;
  final Map<String, Object?>? source;
  final Map<String, Object?>? agentUi;
  final Map<String, Object?>? goalState;
  final Map<String, Object?>? workspaceScope;

  factory NanobotInboundEnvelope.fromJson(Map<String, Object?> json) {
    final rawEvent = json['event'] as String? ?? '';
    return NanobotInboundEnvelope(
      type: _eventTypeFrom(rawEvent),
      rawEvent: rawEvent,
      chatId: json['chat_id'] as String?,
      clientId: json['client_id'] as String?,
      text: json['text'] as String?,
      replyTo: json['reply_to'] as String?,
      streamId: json['stream_id'] as String?,
      kind: json['kind'] as String?,
      detail: json['detail'] as String?,
      reason: json['reason'] as String?,
      provider: json['provider'] as String?,
      modelName: json['model_name'] as String?,
      modelPreset: json['model_preset'] as String?,
      status: json['status'] as String?,
      scope: json['scope'] as String?,
      requestId: json['request_id'] as String?,
      startedAt: _intFrom(json['started_at']),
      latencyMs: _intFrom(json['latency_ms']),
      turnSeq: _intFrom(json['turn_seq']),
      turnId: json['turn_id'] as String?,
      turnPhase: json['turn_phase'] as String?,
      media: _stringListFrom(json['media']),
      mediaUrls: _mapListFrom(json['media_urls']),
      toolEvents: _mapListFrom(json['tool_events']),
      fileEdits: _mapListFrom(json['edits']),
      source: _mapFrom(json['source']),
      agentUi: _mapFrom(json['agent_ui']),
      goalState: _mapFrom(json['goal_state']),
      workspaceScope: _mapFrom(json['workspace_scope']),
    );
  }

  static NanobotInboundEventType _eventTypeFrom(String value) {
    return switch (value) {
      'ready' => NanobotInboundEventType.ready,
      'attached' => NanobotInboundEventType.attached,
      'message' => NanobotInboundEventType.message,
      'file_edit' => NanobotInboundEventType.fileEdit,
      'delta' => NanobotInboundEventType.delta,
      'stream_end' => NanobotInboundEventType.streamEnd,
      'reasoning_delta' => NanobotInboundEventType.reasoningDelta,
      'reasoning_end' => NanobotInboundEventType.reasoningEnd,
      'runtime_model_updated' => NanobotInboundEventType.runtimeModelUpdated,
      'turn_end' => NanobotInboundEventType.turnEnd,
      'goal_status' => NanobotInboundEventType.goalStatus,
      'goal_state' => NanobotInboundEventType.goalState,
      'session_updated' => NanobotInboundEventType.sessionUpdated,
      'transcription_result' => NanobotInboundEventType.transcriptionResult,
      'transcription_error' => NanobotInboundEventType.transcriptionError,
      'error' => NanobotInboundEventType.error,
      _ => NanobotInboundEventType.unknown,
    };
  }
}

class NanobotOutboundMedia {
  const NanobotOutboundMedia({required this.dataUrl, this.name});

  final String dataUrl;
  final String? name;

  Map<String, Object?> toJson() {
    return _withoutNulls({'data_url': dataUrl, 'name': name});
  }
}

class NanobotOutboundImageGeneration {
  const NanobotOutboundImageGeneration({this.aspectRatio});

  final String? aspectRatio;

  Map<String, Object?> toJson() {
    return _withoutNulls({'enabled': true, 'aspect_ratio': aspectRatio});
  }
}

class NanobotOutboundMention {
  const NanobotOutboundMention({
    required this.name,
    this.displayName,
    this.category,
    this.entryPoint,
    this.transport,
    this.status,
    this.configured,
    this.logoUrl,
    this.brandColor,
  });

  final String name;
  final String? displayName;
  final String? category;
  final String? entryPoint;
  final String? transport;
  final String? status;
  final bool? configured;
  final String? logoUrl;
  final String? brandColor;

  Map<String, Object?> toJson() {
    return _withoutNulls({
      'name': name,
      'display_name': displayName,
      'category': category,
      'entry_point': entryPoint,
      'transport': transport,
      'status': status,
      'configured': configured,
      'logo_url': logoUrl,
      'brand_color': brandColor,
    });
  }
}

class NanobotOutboundEnvelope {
  const NanobotOutboundEnvelope._(this._json);

  final Map<String, Object?> _json;

  factory NanobotOutboundEnvelope.newChat({
    Map<String, Object?>? workspaceScope,
  }) {
    return NanobotOutboundEnvelope._(
      _withoutNulls({'type': 'new_chat', 'workspace_scope': workspaceScope}),
    );
  }

  factory NanobotOutboundEnvelope.attach({required String chatId}) {
    return NanobotOutboundEnvelope._({'type': 'attach', 'chat_id': chatId});
  }

  factory NanobotOutboundEnvelope.forkChat({
    required String sourceChatId,
    required int beforeUserIndex,
    String? title,
  }) {
    return NanobotOutboundEnvelope._(
      _withoutNulls({
        'type': 'fork_chat',
        'source_chat_id': sourceChatId,
        'before_user_index': beforeUserIndex,
        'title': title,
      }),
    );
  }

  factory NanobotOutboundEnvelope.setWorkspaceScope({
    required String chatId,
    required Map<String, Object?> workspaceScope,
  }) {
    return NanobotOutboundEnvelope._({
      'type': 'set_workspace_scope',
      'chat_id': chatId,
      'workspace_scope': workspaceScope,
    });
  }

  factory NanobotOutboundEnvelope.transcribeAudio({
    required String requestId,
    required String dataUrl,
    int? durationMs,
  }) {
    return NanobotOutboundEnvelope._(
      _withoutNulls({
        'type': 'transcribe_audio',
        'request_id': requestId,
        'data_url': dataUrl,
        'duration_ms': durationMs,
      }),
    );
  }

  factory NanobotOutboundEnvelope.message({
    required String chatId,
    required String content,
    List<NanobotOutboundMedia> media = const [],
    NanobotOutboundImageGeneration? imageGeneration,
    List<NanobotOutboundMention> cliApps = const [],
    List<NanobotOutboundMention> mcpPresets = const [],
    Map<String, Object?>? workspaceScope,
    String? turnId,
    bool webui = true,
  }) {
    return NanobotOutboundEnvelope._(
      _withoutNulls({
        'type': 'message',
        'chat_id': chatId,
        'content': content,
        'media': media.isEmpty
            ? null
            : [for (final item in media) item.toJson()],
        'image_generation': imageGeneration?.toJson(),
        'cli_apps': cliApps.isEmpty
            ? null
            : [for (final item in cliApps) item.toJson()],
        'mcp_presets': mcpPresets.isEmpty
            ? null
            : [for (final item in mcpPresets) item.toJson()],
        'workspace_scope': workspaceScope,
        'turn_id': turnId,
        'webui': webui ? true : null,
      }),
    );
  }

  Map<String, Object?> toJson() => Map<String, Object?>.from(_json);
}

int? _intFrom(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}

List<String> _stringListFrom(Object? value) {
  if (value is! List) {
    return const [];
  }
  return [
    for (final item in value)
      if (item is String) item,
  ];
}

List<Map<String, Object?>> _mapListFrom(Object? value) {
  if (value is! List) {
    return const [];
  }
  return [
    for (final item in value)
      if (item is Map) Map<String, Object?>.from(item),
  ];
}

Map<String, Object?>? _mapFrom(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return Map<String, Object?>.from(value);
  }
  return null;
}

Map<String, Object?> _withoutNulls(Map<String, Object?> value) {
  return {
    for (final entry in value.entries)
      if (entry.value != null) entry.key: entry.value,
  };
}
