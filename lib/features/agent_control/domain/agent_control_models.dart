enum AgentControlStreamEventType {
  text,
  reasoning,
  reasoningDone,
  progress,
  toolHint,
  goalStatus,
  goalState,
  fileEdit,
  streamEnd,
  done,
  error,
  doneMarker,
  unknown,
}

class AgentControlApiException implements Exception {
  const AgentControlApiException({
    required this.message,
    this.type,
    this.code,
    this.statusCode,
  });

  final String message;
  final String? type;
  final String? code;
  final int? statusCode;

  factory AgentControlApiException.fromJson(
    Map<String, Object?> json, {
    int? statusCode,
  }) {
    final error = json['error'];
    if (error is Map<String, Object?>) {
      return AgentControlApiException(
        message: error['message']?.toString() ?? 'Request failed',
        type: error['type']?.toString(),
        code: error['code']?.toString(),
        statusCode: statusCode,
      );
    }
    return AgentControlApiException(
      message: json['message']?.toString() ?? 'Request failed',
      statusCode: statusCode,
    );
  }

  @override
  String toString() => message;
}

class AgentCard {
  const AgentCard({
    required this.name,
    required this.protocol,
    required this.capabilities,
    required this.state,
    required this.workspace,
    this.description,
    this.wsPort,
    this.gatewayPort,
    this.model,
    this.provider,
  });

  final String name;
  final String protocol;
  final String? description;
  final List<String> capabilities;
  final AgentCardState state;
  final int? wsPort;
  final int? gatewayPort;
  final String? model;
  final String? provider;
  final String workspace;

  factory AgentCard.fromJson(Map<String, Object?> json) {
    return AgentCard(
      name: json['name']?.toString() ?? 'agent',
      description: json['description']?.toString(),
      protocol: json['protocol']?.toString() ?? '',
      capabilities: _stringList(json['capabilities']),
      state: AgentCardState.fromJson(_map(json['state'])),
      wsPort: _int(json['wsPort']),
      gatewayPort: _int(json['gatewayPort']),
      model: json['model']?.toString(),
      provider: json['provider']?.toString(),
      workspace:
          json['workspaceDir']?.toString() ??
          json['workspace']?.toString() ??
          '',
    );
  }
}

class AgentCardState {
  const AgentCardState({
    required this.status,
    required this.health,
    this.defaultSessionId,
  });

  final String status;
  final String? defaultSessionId;
  final String health;

  factory AgentCardState.fromJson(Map<String, Object?> json) {
    return AgentCardState(
      status: json['status']?.toString() ?? 'idle',
      defaultSessionId: json['defaultSessionId']?.toString(),
      health: json['health']?.toString() ?? 'unknown',
    );
  }
}

class HealthStatus {
  const HealthStatus({required this.status});

  final String status;

  factory HealthStatus.fromJson(Map<String, Object?> json) {
    return HealthStatus(status: json['status']?.toString() ?? 'unknown');
  }
}

class AgentListResponse {
  const AgentListResponse({required this.object, required this.data});

  final String object;
  final List<AgentSummary> data;

  factory AgentListResponse.fromJson(Map<String, Object?> json) {
    return AgentListResponse(
      object: json['object']?.toString() ?? 'list',
      data: _list(json['data']).map(AgentSummary.fromJson).toList(),
    );
  }
}

class AgentSummary {
  const AgentSummary({
    required this.name,
    required this.wsPort,
    required this.gatewayPort,
    required this.workspaceDir,
    required this.status,
    required this.health,
    this.description,
    this.model,
    this.provider,
  });

  final String name;
  final String? description;
  final int? wsPort;
  final int? gatewayPort;
  final String workspaceDir;
  final String? model;
  final String? provider;
  final String status;
  final String health;

  factory AgentSummary.fromJson(Map<String, Object?> json) {
    return AgentSummary(
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      wsPort: _int(json['wsPort']),
      gatewayPort: _int(json['gatewayPort']),
      workspaceDir: json['workspaceDir']?.toString() ?? '',
      model: json['model']?.toString(),
      provider: json['provider']?.toString(),
      status: json['status']?.toString() ?? 'stopped',
      health: json['health']?.toString() ?? 'unknown',
    );
  }
}

class CreateAgentResponse {
  const CreateAgentResponse({
    required this.name,
    required this.wsPort,
    required this.gatewayPort,
    required this.configPath,
    required this.workspaceDir,
    required this.status,
    this.description,
    this.model,
    this.provider,
  });

  final String name;
  final String? description;
  final int? wsPort;
  final int? gatewayPort;
  final String configPath;
  final String workspaceDir;
  final String? model;
  final String? provider;
  final String status;

  factory CreateAgentResponse.fromJson(Map<String, Object?> json) {
    return CreateAgentResponse(
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      wsPort: _int(json['wsPort']),
      gatewayPort: _int(json['gatewayPort']),
      configPath: json['configPath']?.toString() ?? '',
      workspaceDir: json['workspaceDir']?.toString() ?? '',
      model: json['model']?.toString(),
      provider: json['provider']?.toString(),
      status: json['status']?.toString() ?? 'stopped',
    );
  }
}

class DeleteAgentResponse {
  const DeleteAgentResponse({required this.deleted, required this.name});

  final bool deleted;
  final String name;

  factory DeleteAgentResponse.fromJson(Map<String, Object?> json) {
    return DeleteAgentResponse(
      deleted: json['deleted'] == true,
      name: json['name']?.toString() ?? '',
    );
  }
}

class AgentLifecycleResponse {
  const AgentLifecycleResponse({required this.accepted, required this.name});

  final bool accepted;
  final String name;

  factory AgentLifecycleResponse.fromJson(Map<String, Object?> json) {
    return AgentLifecycleResponse(
      accepted: json['accepted'] == true,
      name: json['name']?.toString() ?? '',
    );
  }
}

class SoulUpdateResponse {
  const SoulUpdateResponse({required this.path});

  final String path;

  factory SoulUpdateResponse.fromJson(Map<String, Object?> json) {
    return SoulUpdateResponse(path: json['path']?.toString() ?? '');
  }
}

class CreateSessionResponse {
  const CreateSessionResponse({
    required this.sessionId,
    required this.title,
    required this.preview,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
    required this.status,
    this.runStartedAt,
  });

  final String sessionId;
  final String title;
  final String preview;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int messageCount;
  final String status;
  final DateTime? runStartedAt;

  factory CreateSessionResponse.fromJson(Map<String, Object?> json) {
    return CreateSessionResponse(
      sessionId: json['sessionId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'New chat',
      preview: json['preview']?.toString() ?? '',
      createdAt: _date(json['createdAt'] ?? json['created_at']),
      updatedAt: _date(json['updatedAt'] ?? json['updated_at']),
      messageCount: _int(json['messageCount'] ?? json['message_count']) ?? 0,
      status: json['status']?.toString() ?? 'idle',
      runStartedAt: _dateOrEpochSeconds(
        json['runStartedAt'] ?? json['run_started_at'],
      ),
    );
  }
}

class AttachSessionResponse {
  const AttachSessionResponse({
    required this.sessionId,
    required this.attached,
  });

  final String sessionId;
  final bool attached;

  factory AttachSessionResponse.fromJson(Map<String, Object?> json) {
    return AttachSessionResponse(
      sessionId: json['sessionId']?.toString() ?? '',
      attached: json['attached'] == true,
    );
  }
}

class SessionListResponse {
  const SessionListResponse({required this.object, required this.data});

  final String object;
  final List<SessionSummary> data;

  factory SessionListResponse.fromJson(Map<String, Object?> json) {
    return SessionListResponse(
      object: json['object']?.toString() ?? 'list',
      data: _list(json['data']).map(SessionSummary.fromJson).toList(),
    );
  }
}

class SessionSummary {
  const SessionSummary({
    this.key = '',
    this.rawSessionId,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    required this.preview,
    this.messageCount = 0,
    this.status = 'idle',
    this.runStartedAt,
  });

  final String key;
  final String? rawSessionId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String title;
  final String preview;
  final int messageCount;
  final String status;
  final DateTime? runStartedAt;

  String get sessionId {
    if (rawSessionId != null && rawSessionId!.isNotEmpty) {
      return rawSessionId!;
    }
    return key.startsWith('websocket:')
        ? key.substring('websocket:'.length)
        : key;
  }

  factory SessionSummary.fromJson(Map<String, Object?> json) {
    return SessionSummary(
      key: json['key']?.toString() ?? '',
      rawSessionId: json['sessionId']?.toString(),
      createdAt: _date(json['created_at'] ?? json['createdAt']),
      updatedAt: _date(json['updated_at'] ?? json['updatedAt']),
      title: json['title']?.toString() ?? '',
      preview: json['preview']?.toString() ?? '',
      messageCount: _int(json['messageCount'] ?? json['message_count']) ?? 0,
      status: json['status']?.toString() ?? 'idle',
      runStartedAt: _dateOrEpochSeconds(
        json['runStartedAt'] ?? json['run_started_at'],
      ),
    );
  }
}

class SessionMessages {
  const SessionMessages({
    required this.key,
    required this.createdAt,
    required this.updatedAt,
    required this.metadata,
    required this.messages,
  });

  final String key;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, Object?> metadata;
  final List<SessionMessage> messages;

  String get sessionId =>
      key.startsWith('websocket:') ? key.substring('websocket:'.length) : key;

  factory SessionMessages.fromJson(Map<String, Object?> json) {
    return SessionMessages(
      key: json['key']?.toString() ?? '',
      createdAt: _date(json['created_at'] ?? json['createdAt']),
      updatedAt: _date(json['updated_at'] ?? json['updatedAt']),
      metadata: _map(json['metadata']),
      messages: _list(json['messages']).map(SessionMessage.fromJson).toList(),
    );
  }
}

class SessionMessage {
  const SessionMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.latencyMs,
  });

  final String role;
  final String content;
  final DateTime? timestamp;
  final int? latencyMs;

  factory SessionMessage.fromJson(Map<String, Object?> json) {
    return SessionMessage(
      role: json['role']?.toString() ?? 'assistant',
      content: json['content']?.toString() ?? '',
      timestamp: _date(json['timestamp']),
      latencyMs: _int(json['latency_ms'] ?? json['latencyMs']),
    );
  }
}

class NonStreamMessageResponse {
  const NonStreamMessageResponse({
    required this.sessionId,
    required this.content,
    required this.latencyMs,
  });

  final String sessionId;
  final String content;
  final int? latencyMs;

  factory NonStreamMessageResponse.fromJson(Map<String, Object?> json) {
    return NonStreamMessageResponse(
      sessionId: json['sessionId']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      latencyMs: _int(json['latencyMs']),
    );
  }
}

class AgentControlStreamEvent {
  const AgentControlStreamEvent({
    required this.type,
    this.text,
    this.message,
    this.code,
    this.state,
    this.startedAt,
    this.latencyMs,
    this.goalState,
    this.toolEvents,
    this.fileEdits = const [],
    this.raw = const {},
  });

  final AgentControlStreamEventType type;
  final String? text;
  final String? message;
  final String? code;
  final String? state;
  final double? startedAt;
  final int? latencyMs;
  final Map<String, Object?>? goalState;
  final List<Object?>? toolEvents;
  final List<Map<String, Object?>> fileEdits;
  final Map<String, Object?> raw;

  factory AgentControlStreamEvent.doneMarker() {
    return const AgentControlStreamEvent(
      type: AgentControlStreamEventType.doneMarker,
    );
  }

  factory AgentControlStreamEvent.fromJson(Map<String, Object?> json) {
    final type = switch (json['type']?.toString()) {
      'text' => AgentControlStreamEventType.text,
      'reasoning' => AgentControlStreamEventType.reasoning,
      'reasoning_done' => AgentControlStreamEventType.reasoningDone,
      'progress' => AgentControlStreamEventType.progress,
      'tool_hint' => AgentControlStreamEventType.toolHint,
      'goal_status' => AgentControlStreamEventType.goalStatus,
      'goal_state' => AgentControlStreamEventType.goalState,
      'file_edit' => AgentControlStreamEventType.fileEdit,
      'stream_end' => AgentControlStreamEventType.streamEnd,
      'done' => AgentControlStreamEventType.done,
      'error' => AgentControlStreamEventType.error,
      _ => AgentControlStreamEventType.unknown,
    };

    return AgentControlStreamEvent(
      type: type,
      text: json['text']?.toString(),
      message: json['message']?.toString(),
      code: json['code']?.toString(),
      state: json['state']?.toString(),
      startedAt: _double(json['startedAt']),
      latencyMs: _int(json['latencyMs']),
      goalState: _nullableMap(json['goalState']),
      toolEvents: _nullableList(json['toolEvents']),
      fileEdits: _list(json['edits']),
      raw: json,
    );
  }
}

class AgentCommandListResponse {
  const AgentCommandListResponse({required this.object, required this.data});

  final String object;
  final List<AgentCommand> data;

  factory AgentCommandListResponse.fromJson(Map<String, Object?> json) {
    return AgentCommandListResponse(
      object: json['object']?.toString() ?? 'list',
      data: _list(json['data']).map(AgentCommand.fromJson).toList(),
    );
  }
}

class AgentCommand {
  const AgentCommand({
    required this.command,
    required this.title,
    required this.description,
    required this.icon,
    required this.argHint,
  });

  final String command;
  final String title;
  final String description;
  final String icon;
  final String argHint;

  factory AgentCommand.fromJson(Map<String, Object?> json) {
    return AgentCommand(
      command: json['command']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      argHint: json['argHint']?.toString() ?? '',
    );
  }
}

class AgentSettings {
  const AgentSettings({
    required this.raw,
    required this.agent,
    required this.providers,
    required this.requiresRestart,
  });

  final Map<String, Object?> raw;
  final AgentRuntimeSettings agent;
  final List<AgentProviderSettings> providers;
  final bool requiresRestart;

  factory AgentSettings.empty() {
    return const AgentSettings(
      raw: {},
      agent: AgentRuntimeSettings(
        model: null,
        provider: null,
        resolvedProvider: null,
        hasApiKey: false,
      ),
      providers: [],
      requiresRestart: false,
    );
  }

  factory AgentSettings.fromJson(Map<String, Object?> json) {
    return AgentSettings(
      raw: json,
      agent: AgentRuntimeSettings.fromJson(_map(json['agent'])),
      providers: _list(
        json['providers'],
      ).map(AgentProviderSettings.fromJson).toList(),
      requiresRestart:
          json['requires_restart'] == true || json['requiresRestart'] == true,
    );
  }
}

class AgentRuntimeSettings {
  const AgentRuntimeSettings({
    required this.model,
    required this.provider,
    required this.resolvedProvider,
    required this.hasApiKey,
  });

  final String? model;
  final String? provider;
  final String? resolvedProvider;
  final bool hasApiKey;

  factory AgentRuntimeSettings.fromJson(Map<String, Object?> json) {
    return AgentRuntimeSettings(
      model: json['model']?.toString(),
      provider: json['provider']?.toString(),
      resolvedProvider:
          json['resolved_provider']?.toString() ??
          json['resolvedProvider']?.toString(),
      hasApiKey: json['has_api_key'] == true || json['hasApiKey'] == true,
    );
  }
}

class AgentProviderSettings {
  const AgentProviderSettings({
    required this.name,
    required this.label,
    required this.configured,
    this.models = const [],
    this.apiKeyHint,
    this.apiBase,
    this.defaultApiBase,
  });

  final String name;
  final String label;
  final bool configured;
  final List<String> models;
  final String? apiKeyHint;
  final String? apiBase;
  final String? defaultApiBase;

  factory AgentProviderSettings.fromJson(Map<String, Object?> json) {
    return AgentProviderSettings(
      name: json['name']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      configured: json['configured'] == true,
      models: _stringList(json['models']),
      apiKeyHint:
          json['api_key_hint']?.toString() ?? json['apiKeyHint']?.toString(),
      apiBase: json['api_base']?.toString() ?? json['apiBase']?.toString(),
      defaultApiBase:
          json['default_api_base']?.toString() ??
          json['defaultApiBase']?.toString(),
    );
  }
}

class ResourceTree {
  const ResourceTree({
    required this.object,
    required this.path,
    required this.children,
  });

  final String object;
  final String path;
  final List<ResourceTreeItem> children;

  factory ResourceTree.fromJson(Map<String, Object?> json) {
    return ResourceTree(
      object: json['object']?.toString() ?? 'resources.tree',
      path: json['path']?.toString() ?? '.',
      children: _list(json['children']).map(ResourceTreeItem.fromJson).toList(),
    );
  }
}

class ResourceTreeItem {
  const ResourceTreeItem({
    required this.name,
    required this.path,
    required this.type,
  });

  final String name;
  final String path;
  final String type;

  factory ResourceTreeItem.fromJson(Map<String, Object?> json) {
    return ResourceTreeItem(
      name: json['name']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      type: json['type']?.toString() ?? 'other',
    );
  }
}

class ResourceSearchResponse {
  const ResourceSearchResponse({
    required this.object,
    required this.query,
    required this.data,
  });

  final String object;
  final String query;
  final List<ResourceSearchResult> data;

  factory ResourceSearchResponse.fromJson(Map<String, Object?> json) {
    return ResourceSearchResponse(
      object: json['object']?.toString() ?? 'list',
      query: json['query']?.toString() ?? '',
      data: _list(json['data']).map(ResourceSearchResult.fromJson).toList(),
    );
  }
}

class ResourceSearchResult {
  const ResourceSearchResult({
    required this.path,
    required this.type,
    required this.match,
    this.line,
    this.preview,
  });

  final String path;
  final String type;
  final String match;
  final int? line;
  final String? preview;

  factory ResourceSearchResult.fromJson(Map<String, Object?> json) {
    return ResourceSearchResult(
      path: json['path']?.toString() ?? '',
      type: json['type']?.toString() ?? 'file',
      match: json['match']?.toString() ?? '',
      line: _int(json['line']),
      preview: json['preview']?.toString(),
    );
  }
}

class ResourceFile {
  const ResourceFile({
    required this.object,
    required this.path,
    required this.size,
    required this.mtimeMs,
    required this.content,
  });

  final String object;
  final String path;
  final int size;
  final double mtimeMs;
  final String content;

  factory ResourceFile.fromJson(Map<String, Object?> json) {
    return ResourceFile(
      object: json['object']?.toString() ?? 'resources.file',
      path: json['path']?.toString() ?? '',
      size: _int(json['size']) ?? 0,
      mtimeMs: _double(json['mtimeMs']) ?? 0,
      content: json['content']?.toString() ?? '',
    );
  }
}

class ResourceFileWriteResult {
  const ResourceFileWriteResult({
    required this.object,
    required this.path,
    required this.size,
    required this.mtimeMs,
  });

  final String object;
  final String path;
  final int size;
  final double mtimeMs;

  factory ResourceFileWriteResult.fromJson(Map<String, Object?> json) {
    return ResourceFileWriteResult(
      object: json['object']?.toString() ?? 'resources.file',
      path: json['path']?.toString() ?? '',
      size: _int(json['size']) ?? 0,
      mtimeMs: _double(json['mtimeMs']) ?? 0,
    );
  }
}

class GitStatus {
  const GitStatus({
    required this.object,
    required this.isRepo,
    required this.branch,
    required this.upstream,
    required this.ahead,
    required this.behind,
    required this.clean,
    required this.data,
  });

  final String object;
  final bool isRepo;
  final String? branch;
  final String? upstream;
  final int ahead;
  final int behind;
  final bool clean;
  final List<GitStatusItem> data;

  factory GitStatus.empty() {
    return const GitStatus(
      object: 'git.status',
      isRepo: false,
      branch: null,
      upstream: null,
      ahead: 0,
      behind: 0,
      clean: true,
      data: [],
    );
  }

  factory GitStatus.fromJson(Map<String, Object?> json) {
    return GitStatus(
      object: json['object']?.toString() ?? 'git.status',
      isRepo: json['isRepo'] == true,
      branch: json['branch']?.toString(),
      upstream: json['upstream']?.toString(),
      ahead: _int(json['ahead']) ?? 0,
      behind: _int(json['behind']) ?? 0,
      clean: json['clean'] == true,
      data: _list(json['data']).map(GitStatusItem.fromJson).toList(),
    );
  }
}

class GitStatusItem {
  const GitStatusItem({
    required this.path,
    required this.status,
    this.from,
    this.index,
    this.worktree,
  });

  final String path;
  final String status;
  final String? from;
  final String? index;
  final String? worktree;

  factory GitStatusItem.fromJson(Map<String, Object?> json) {
    return GitStatusItem(
      path: json['path']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      from: json['from']?.toString(),
      index: json['index']?.toString(),
      worktree: json['worktree']?.toString(),
    );
  }
}

class GitDiff {
  const GitDiff({
    required this.object,
    required this.isRepo,
    required this.path,
    required this.diff,
  });

  final String object;
  final bool isRepo;
  final String path;
  final String diff;

  factory GitDiff.fromJson(Map<String, Object?> json) {
    return GitDiff(
      object: json['object']?.toString() ?? 'git.diff',
      isRepo: json['isRepo'] == true,
      path: json['path']?.toString() ?? '.',
      diff: json['diff']?.toString() ?? '',
    );
  }
}

Map<String, Object?> _map(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

Map<String, Object?>? _nullableMap(Object? value) {
  if (value == null) {
    return null;
  }
  return _map(value);
}

List<Map<String, Object?>> _list(Object? value) {
  if (value is List) {
    return value.map(_map).toList();
  }
  return const [];
}

List<Object?>? _nullableList(Object? value) {
  if (value is List) {
    return List<Object?>.of(value);
  }
  return null;
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}

DateTime? _date(Object? value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}

DateTime? _dateOrEpochSeconds(Object? value) {
  if (value == null) {
    return null;
  }
  final parsedDate = DateTime.tryParse(value.toString());
  if (parsedDate != null) {
    return parsedDate;
  }
  final epochSeconds = _double(value);
  if (epochSeconds == null) {
    return null;
  }
  return DateTime.fromMillisecondsSinceEpoch(
    (epochSeconds * 1000).round(),
    isUtc: true,
  );
}

int? _int(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '');
}

double? _double(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '');
}
