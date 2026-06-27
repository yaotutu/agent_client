# Nanobot-First Client Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the Flutter app as a nanobot WebUI-aligned native client that connects to an existing nanobot gateway, removes the old Agent Control/multi-agent architecture, and passes automated plus on-device verification.

**Architecture:** The app becomes a nanobot shell with connection, sidebar, thread, composer, workspace, and light secondary views. Data flows through nanobot WebUI HTTP APIs and the multiplexed nanobot WebSocket protocol, with Drift used only as a cache keyed by `gatewayBaseUrl + sessionKey`.

**Tech Stack:** Flutter, Dart, hooks_riverpod, Dio, Drift, web_socket_channel, flutter_test.

---

## Execution Notes

- The approved spec is `docs/superpowers/specs/2026-06-28-nanobot-first-redesign-design.md`.
- The live nanobot gateway for integration/device testing is `http://192.168.55.130:8765/`.
- The WebUI secret was provided in the thread. Do not write it into code, docs, commits, logs, shell history, or test fixtures.
- Existing uncommitted changes in `android/gradle/wrapper/gradle-wrapper.properties`, `android/settings.gradle.kts`, and `pubspec.lock` predate this plan. Inspect before editing those files and do not revert unrelated changes.
- Use small commits after each task. If a task touches generated files, include the generated files in the same task commit.

## File Map

Create or replace:

- `lib/app/nanobot_app.dart` - Material app entry that opens `NanobotShellPage`.
- `lib/core/config/nanobot_config.dart` - gateway URL, optional saved bootstrap secret, normalization.
- `lib/core/config/nanobot_config_store.dart` - file-backed config store and Riverpod providers.
- `lib/core/network/nanobot_http.dart` - Dio factory and authenticated JSON request helper.
- `lib/core/network/nanobot_websocket.dart` - WebSocket connector abstraction.
- `lib/data/local/nanobot_cache_database.dart` - Drift database with nanobot cache tables.
- `lib/data/local/nanobot_cache_store.dart` - cache API for sessions and thread pages.
- `lib/features/nanobot/data/protocol/nanobot_http_dto.dart` - HTTP payload parsing.
- `lib/features/nanobot/data/protocol/nanobot_ws_envelope.dart` - WebSocket envelope parsing/serialization.
- `lib/features/nanobot/data/nanobot_runtime_host.dart` - external gateway bootstrap runtime host.
- `lib/features/nanobot/data/nanobot_http_api.dart` - WebUI HTTP API wrapper.
- `lib/features/nanobot/data/nanobot_ws_client.dart` - nanobot WebSocket client.
- `lib/features/nanobot/domain/nanobot_connection.dart` - connection state models.
- `lib/features/nanobot/domain/nanobot_session.dart` - session summary and delete result.
- `lib/features/nanobot/domain/nanobot_thread_message.dart` - UI thread message model.
- `lib/features/nanobot/domain/nanobot_thread_state.dart` - reducer state and actions.
- `lib/features/nanobot/domain/nanobot_workspace.dart` - workspace scope models.
- `lib/features/nanobot/application/nanobot_connection_controller.dart` - bootstrap and socket lifecycle.
- `lib/features/nanobot/application/nanobot_session_controller.dart` - sessions, create, attach, delete.
- `lib/features/nanobot/application/nanobot_thread_controller.dart` - history load, send, stop, live events.
- `lib/features/nanobot/application/nanobot_workspace_controller.dart` - workspace loading and selection.
- `lib/features/nanobot/presentation/shell/nanobot_shell_page.dart` - responsive shell.
- `lib/features/nanobot/presentation/sidebar/nanobot_sidebar.dart` - WebUI-aligned session sidebar.
- `lib/features/nanobot/presentation/thread/nanobot_thread_shell.dart` - thread layout.
- `lib/features/nanobot/presentation/thread/nanobot_thread_header.dart` - title, model, connection, workspace.
- `lib/features/nanobot/presentation/thread/nanobot_thread_messages.dart` - bottom-anchored message list.
- `lib/features/nanobot/presentation/thread/nanobot_message_bubble.dart` - user/assistant message bubble.
- `lib/features/nanobot/presentation/thread/nanobot_activity_cluster.dart` - reasoning/tool/file edit activity.
- `lib/features/nanobot/presentation/thread/nanobot_thread_composer.dart` - input, send, stop, slash commands.
- `lib/features/nanobot/presentation/settings/nanobot_settings_view.dart` - light overview and secondary entries.
- `test/helpers/nanobot_fakes.dart` - fake HTTP/runtime/socket/cache helpers.

Modify:

- `pubspec.yaml` - add `web_socket_channel`.
- `lib/main.dart` - load `NanobotConfig` and launch `NanobotApp`.
- `lib/app/adaptive/adaptive_layout_policy.dart` - rename workspace wording only when needed by shell code.
- `README.md` - rewrite as nanobot native client.
- `AGENTS.md` - update repository instructions to nanobot-first.

Delete old product code:

- `lib/features/agent_control/`
- `lib/features/agents/`
- `lib/features/chat/`
- `lib/features/files/`
- `lib/features/git/`
- `lib/features/settings/`
- `lib/features/tasks/`
- old Agent Control and multi-agent tests under `test/`
- old generated Drift database files tied to agent cache tables

The deletion happens after the new app compiles so each intermediate commit stays understandable.

---

## Task 1: Dependencies and Nanobot Config

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`
- Create: `lib/app/nanobot_app.dart`
- Create: `lib/core/config/nanobot_config.dart`
- Create: `lib/core/config/nanobot_config_store.dart`
- Test: `test/nanobot_config_test.dart`

- [ ] **Step 1: Write config tests**

Create `test/nanobot_config_test.dart`:

```dart
import 'dart:io';

import 'package:agent_client/core/config/nanobot_config.dart';
import 'package:agent_client/core/config/nanobot_config_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes gateway URLs by trimming trailing slashes', () {
    final config = NanobotConfig.fromJson({
      'gatewayBaseUrl': ' http://127.0.0.1:8765/// ',
      'bootstrapSecret': '  secret  ',
      'saveBootstrapSecret': true,
    });

    expect(config.gatewayBaseUrl, 'http://127.0.0.1:8765');
    expect(config.bootstrapSecret, 'secret');
    expect(config.saveBootstrapSecret, isTrue);
  });

  test('uses localhost nanobot gateway by default', () {
    expect(
      NanobotConfig.defaults.gatewayBaseUrl,
      'http://127.0.0.1:8765',
    );
    expect(NanobotConfig.defaults.bootstrapSecret, '');
  });

  test('does not serialize bootstrap secret when save is false', () {
    const config = NanobotConfig(
      gatewayBaseUrl: 'http://192.168.55.130:8765',
      bootstrapSecret: 'secret',
      saveBootstrapSecret: false,
    );

    expect(config.toJson(), {
      'gatewayBaseUrl': 'http://192.168.55.130:8765',
      'saveBootstrapSecret': false,
    });
  });

  test('file store round-trips saved config', () async {
    final dir = await Directory.systemTemp.createTemp('nanobot_config_test_');
    addTearDown(() => dir.delete(recursive: true));
    final store = FileNanobotConfigStore(directoryProvider: () async => dir);
    const config = NanobotConfig(
      gatewayBaseUrl: 'http://192.168.55.130:8765',
      bootstrapSecret: 'secret',
      saveBootstrapSecret: true,
    );

    await store.save(config);

    expect(await store.load(), config);
  });
}
```

- [ ] **Step 2: Run the failing config tests**

Run:

```sh
flutter test test/nanobot_config_test.dart
```

Expected: fail because `NanobotConfig` and `FileNanobotConfigStore` do not exist.

- [ ] **Step 3: Add dependency**

Modify `pubspec.yaml` dependencies:

```yaml
  web_socket_channel: ^3.0.1
```

Run:

```sh
flutter pub get
```

Expected: dependency resolution succeeds and `pubspec.lock` updates.

- [ ] **Step 4: Implement nanobot config**

Create `lib/core/config/nanobot_config.dart`:

```dart
class NanobotConfig {
  const NanobotConfig({
    required this.gatewayBaseUrl,
    this.bootstrapSecret = '',
    this.saveBootstrapSecret = false,
  });

  static const defaultGatewayBaseUrl = String.fromEnvironment(
    'NANOBOT_GATEWAY_BASE_URL',
    defaultValue: 'http://127.0.0.1:8765',
  );

  static const defaults = NanobotConfig(
    gatewayBaseUrl: defaultGatewayBaseUrl,
  );

  final String gatewayBaseUrl;
  final String bootstrapSecret;
  final bool saveBootstrapSecret;

  NanobotConfig copyWith({
    String? gatewayBaseUrl,
    String? bootstrapSecret,
    bool? saveBootstrapSecret,
  }) {
    return NanobotConfig(
      gatewayBaseUrl: gatewayBaseUrl ?? this.gatewayBaseUrl,
      bootstrapSecret: bootstrapSecret ?? this.bootstrapSecret,
      saveBootstrapSecret: saveBootstrapSecret ?? this.saveBootstrapSecret,
    );
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'gatewayBaseUrl': gatewayBaseUrl,
      'saveBootstrapSecret': saveBootstrapSecret,
    };
    if (saveBootstrapSecret && bootstrapSecret.trim().isNotEmpty) {
      json['bootstrapSecret'] = bootstrapSecret.trim();
    }
    return json;
  }

  factory NanobotConfig.fromJson(Map<String, Object?> json) {
    final gatewayBaseUrl = json['gatewayBaseUrl'];
    final bootstrapSecret = json['bootstrapSecret'];
    final saveBootstrapSecret = json['saveBootstrapSecret'];
    return NanobotConfig(
      gatewayBaseUrl: gatewayBaseUrl is String && gatewayBaseUrl.trim().isNotEmpty
          ? normalizeBaseUrl(gatewayBaseUrl)
          : defaultGatewayBaseUrl,
      bootstrapSecret: bootstrapSecret is String ? bootstrapSecret.trim() : '',
      saveBootstrapSecret: saveBootstrapSecret == true,
    );
  }

  static String normalizeBaseUrl(String value) {
    var normalized = value.trim();
    while (normalized.endsWith('/') && normalized.length > 'https://'.length) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  Uri get gatewayUri => Uri.parse(gatewayBaseUrl);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NanobotConfig &&
            other.gatewayBaseUrl == gatewayBaseUrl &&
            other.bootstrapSecret == bootstrapSecret &&
            other.saveBootstrapSecret == saveBootstrapSecret;
  }

  @override
  int get hashCode => Object.hash(
        gatewayBaseUrl,
        bootstrapSecret,
        saveBootstrapSecret,
      );
}
```

- [ ] **Step 5: Implement config store and providers**

Create `lib/core/config/nanobot_config_store.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:agent_client/core/config/nanobot_config.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';

abstract interface class NanobotConfigStore {
  Future<NanobotConfig?> load();
  Future<void> save(NanobotConfig config);
}

typedef NanobotConfigDirectoryProvider = Future<Directory> Function();

class FileNanobotConfigStore implements NanobotConfigStore {
  FileNanobotConfigStore({NanobotConfigDirectoryProvider? directoryProvider})
      : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final NanobotConfigDirectoryProvider _directoryProvider;

  @override
  Future<NanobotConfig?> load() async {
    try {
      final file = await _configFile();
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, Object?>) {
        return NanobotConfig.fromJson(decoded);
      }
      if (decoded is Map) {
        return NanobotConfig.fromJson(Map<String, Object?>.from(decoded));
      }
    } on Object {
      return null;
    }
    return null;
  }

  @override
  Future<void> save(NanobotConfig config) async {
    final file = await _configFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(config.toJson()));
  }

  Future<File> _configFile() async {
    final directory = await _directoryProvider();
    return File('${directory.path}/nanobot_client_config.json');
  }
}

final initialNanobotConfigProvider = Provider<NanobotConfig>((ref) {
  return NanobotConfig.defaults;
});

final nanobotConfigStoreProvider = Provider<NanobotConfigStore>((ref) {
  return FileNanobotConfigStore();
});

final nanobotConfigControllerProvider =
    NotifierProvider<NanobotConfigController, NanobotConfig>(
  NanobotConfigController.new,
);

final nanobotConfigProvider = Provider<NanobotConfig>((ref) {
  return ref.watch(nanobotConfigControllerProvider);
});

class NanobotConfigController extends Notifier<NanobotConfig> {
  @override
  NanobotConfig build() => ref.watch(initialNanobotConfigProvider);

  Future<void> save(NanobotConfig config) async {
    final normalized = config.copyWith(
      gatewayBaseUrl: NanobotConfig.normalizeBaseUrl(config.gatewayBaseUrl),
      bootstrapSecret: config.bootstrapSecret.trim(),
    );
    await ref.read(nanobotConfigStoreProvider).save(normalized);
    state = normalized;
  }
}
```

- [ ] **Step 6: Replace app bootstrap with NanobotApp**

Modify `lib/app/nanobot_app.dart`:

```dart
import 'package:agent_client/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class NanobotApp extends StatelessWidget {
  const NanobotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nanobot',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const Scaffold(
        body: Center(child: Text('Nanobot client bootstrapping')),
      ),
    );
  }
}
```

Modify `lib/main.dart`:

```dart
import 'package:agent_client/app/nanobot_app.dart';
import 'package:agent_client/core/config/nanobot_config.dart';
import 'package:agent_client/core/config/nanobot_config_store.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configStore = FileNanobotConfigStore();
  final initialConfig = await configStore.load() ?? NanobotConfig.defaults;

  runApp(
    ProviderScope(
      overrides: [
        nanobotConfigStoreProvider.overrideWithValue(configStore),
        initialNanobotConfigProvider.overrideWithValue(initialConfig),
      ],
      child: const NanobotApp(),
    ),
  );
}
```

- [ ] **Step 7: Run config tests**

Run:

```sh
flutter test test/nanobot_config_test.dart
```

Expected: all tests pass.

- [ ] **Step 8: Commit**

```sh
git add pubspec.yaml pubspec.lock lib/main.dart lib/app/nanobot_app.dart lib/core/config/nanobot_config.dart lib/core/config/nanobot_config_store.dart test/nanobot_config_test.dart
git commit -m "feat: add nanobot config foundation"
```

---

## Task 2: Protocol DTOs

**Files:**
- Create: `lib/features/nanobot/data/protocol/nanobot_http_dto.dart`
- Create: `lib/features/nanobot/data/protocol/nanobot_ws_envelope.dart`
- Test: `test/nanobot_protocol_test.dart`

- [ ] **Step 1: Write protocol tests**

Create `test/nanobot_protocol_test.dart`:

```dart
import 'dart:convert';

import 'package:agent_client/features/nanobot/data/protocol/nanobot_http_dto.dart';
import 'package:agent_client/features/nanobot/data/protocol/nanobot_ws_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses bootstrap payload', () {
    final payload = NanobotBootstrapDto.fromJson({
      'token': 'tok',
      'ws_path': '/',
      'ws_url': 'ws://127.0.0.1:8765/',
      'expires_in': 300,
      'model_name': 'openai/gpt-4.1-mini',
      'runtime_surface': 'browser',
      'runtime_capabilities': {
        'can_restart_engine': false,
        'can_pick_folder': false,
        'can_open_logs': false,
        'can_export_diagnostics': false,
      },
    });

    expect(payload.token, 'tok');
    expect(payload.wsPath, '/');
    expect(payload.expiresIn, const Duration(seconds: 300));
    expect(payload.modelName, 'openai/gpt-4.1-mini');
  });

  test('parses sessions payload and splits websocket key', () {
    final payload = NanobotSessionsDto.fromJson({
      'sessions': [
        {
          'key': 'websocket:chat-1',
          'created_at': '2026-06-28T00:00:00Z',
          'updated_at': '2026-06-28T00:01:00Z',
          'title': 'Hello',
          'preview': 'Preview',
          'run_started_at': 123.0,
          'workspace_scope': {
            'project_path': '/tmp/project',
            'project_name': 'project',
            'access_mode': 'restricted',
          },
        },
      ],
    });

    expect(payload.sessions.single.key, 'websocket:chat-1');
    expect(payload.sessions.single.chatId, 'chat-1');
    expect(payload.sessions.single.channel, 'websocket');
  });

  test('serializes outbound message envelope', () {
    final envelope = NanobotOutboundEnvelope.message(
      chatId: 'chat-1',
      content: 'hello',
      turnId: 'turn-1',
      workspaceScope: {
        'project_path': '/tmp/project',
        'access_mode': 'restricted',
      },
    );

    expect(envelope.toJson(), {
      'type': 'message',
      'chat_id': 'chat-1',
      'content': 'hello',
      'workspace_scope': {
        'project_path': '/tmp/project',
        'access_mode': 'restricted',
      },
      'turn_id': 'turn-1',
      'webui': true,
    });
  });

  test('parses inbound delta and unknown events', () {
    final delta = NanobotInboundEnvelope.fromJson(
      jsonDecode('{"event":"delta","chat_id":"chat-1","text":"hi"}')
          as Map<String, Object?>,
    );
    final unknown = NanobotInboundEnvelope.fromJson(
      {'event': 'new_future_event', 'value': 1},
    );

    expect(delta.event, NanobotInboundEventType.delta);
    expect(delta.chatId, 'chat-1');
    expect(delta.text, 'hi');
    expect(unknown.event, NanobotInboundEventType.unknown);
  });
}
```

- [ ] **Step 2: Run failing protocol tests**

Run:

```sh
flutter test test/nanobot_protocol_test.dart
```

Expected: fail because protocol files do not exist.

- [ ] **Step 3: Implement HTTP DTOs**

Create `lib/features/nanobot/data/protocol/nanobot_http_dto.dart` with:

```dart
class NanobotBootstrapDto {
  const NanobotBootstrapDto({
    required this.token,
    required this.wsPath,
    required this.expiresIn,
    this.wsUrl,
    this.modelName,
    this.runtimeSurface = 'browser',
    this.runtimeCapabilities = const {},
  });

  final String token;
  final String wsPath;
  final String? wsUrl;
  final Duration expiresIn;
  final String? modelName;
  final String runtimeSurface;
  final Map<String, Object?> runtimeCapabilities;

  factory NanobotBootstrapDto.fromJson(Map<String, Object?> json) {
    final token = json['token'];
    final wsPath = json['ws_path'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('bootstrap token missing');
    }
    if (wsPath is! String || wsPath.isEmpty) {
      throw const FormatException('bootstrap ws_path missing');
    }
    final expiresIn = json['expires_in'];
    return NanobotBootstrapDto(
      token: token,
      wsPath: wsPath,
      wsUrl: json['ws_url'] is String ? json['ws_url'] as String : null,
      expiresIn: Duration(
        seconds: expiresIn is num ? expiresIn.toInt() : 300,
      ),
      modelName: json['model_name'] is String
          ? json['model_name'] as String
          : null,
      runtimeSurface: json['runtime_surface'] is String
          ? json['runtime_surface'] as String
          : 'browser',
      runtimeCapabilities: json['runtime_capabilities'] is Map
          ? Map<String, Object?>.from(json['runtime_capabilities'] as Map)
          : const {},
    );
  }
}

class NanobotSessionDto {
  const NanobotSessionDto({
    required this.key,
    required this.channel,
    required this.chatId,
    this.createdAt,
    this.updatedAt,
    this.title = '',
    this.preview = '',
    this.runStartedAt,
    this.workspaceScope,
  });

  final String key;
  final String channel;
  final String chatId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String title;
  final String preview;
  final double? runStartedAt;
  final Map<String, Object?>? workspaceScope;

  factory NanobotSessionDto.fromJson(Map<String, Object?> json) {
    final key = json['key'];
    if (key is! String || key.isEmpty) {
      throw const FormatException('session key missing');
    }
    final split = _splitSessionKey(key);
    final runStartedAt = json['run_started_at'];
    return NanobotSessionDto(
      key: key,
      channel: split.$1,
      chatId: split.$2,
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
      title: json['title'] is String ? json['title'] as String : '',
      preview: json['preview'] is String ? json['preview'] as String : '',
      runStartedAt: runStartedAt is num ? runStartedAt.toDouble() : null,
      workspaceScope: json['workspace_scope'] is Map
          ? Map<String, Object?>.from(json['workspace_scope'] as Map)
          : null,
    );
  }
}

class NanobotSessionsDto {
  const NanobotSessionsDto({required this.sessions});

  final List<NanobotSessionDto> sessions;

  factory NanobotSessionsDto.fromJson(Map<String, Object?> json) {
    final rows = json['sessions'];
    return NanobotSessionsDto(
      sessions: rows is List
          ? [
              for (final row in rows)
                if (row is Map) NanobotSessionDto.fromJson(Map<String, Object?>.from(row)),
            ]
          : const [],
    );
  }
}

DateTime? _date(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

(String, String) _splitSessionKey(String key) {
  final index = key.indexOf(':');
  if (index < 0) return ('', key);
  return (key.substring(0, index), key.substring(index + 1));
}
```

- [ ] **Step 4: Implement WebSocket envelopes**

Create `lib/features/nanobot/data/protocol/nanobot_ws_envelope.dart` with:

```dart
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
    required this.event,
    required this.raw,
    this.chatId,
    this.clientId,
    this.text,
    this.detail,
    this.reason,
    this.turnId,
    this.turnPhase,
    this.turnSeq,
  });

  final NanobotInboundEventType event;
  final Map<String, Object?> raw;
  final String? chatId;
  final String? clientId;
  final String? text;
  final String? detail;
  final String? reason;
  final String? turnId;
  final String? turnPhase;
  final int? turnSeq;

  factory NanobotInboundEnvelope.fromJson(Map<String, Object?> json) {
    final eventName = json['event'] is String ? json['event'] as String : '';
    return NanobotInboundEnvelope(
      event: _eventType(eventName),
      raw: json,
      chatId: json['chat_id'] is String ? json['chat_id'] as String : null,
      clientId: json['client_id'] is String ? json['client_id'] as String : null,
      text: json['text'] is String ? json['text'] as String : null,
      detail: json['detail'] is String ? json['detail'] as String : null,
      reason: json['reason'] is String ? json['reason'] as String : null,
      turnId: json['turn_id'] is String ? json['turn_id'] as String : null,
      turnPhase: json['turn_phase'] is String ? json['turn_phase'] as String : null,
      turnSeq: json['turn_seq'] is num ? (json['turn_seq'] as num).toInt() : null,
    );
  }
}

sealed class NanobotOutboundEnvelope {
  const NanobotOutboundEnvelope();

  Map<String, Object?> toJson();

  const factory NanobotOutboundEnvelope.newChat({
    Map<String, Object?>? workspaceScope,
  }) = NanobotNewChatEnvelope;

  const factory NanobotOutboundEnvelope.attach({
    required String chatId,
  }) = NanobotAttachEnvelope;

  const factory NanobotOutboundEnvelope.message({
    required String chatId,
    required String content,
    Map<String, Object?>? workspaceScope,
    String? turnId,
  }) = NanobotMessageEnvelope;

  const factory NanobotOutboundEnvelope.setWorkspaceScope({
    required String chatId,
    required Map<String, Object?> workspaceScope,
  }) = NanobotSetWorkspaceScopeEnvelope;
}

class NanobotNewChatEnvelope extends NanobotOutboundEnvelope {
  const NanobotNewChatEnvelope({this.workspaceScope});

  final Map<String, Object?>? workspaceScope;

  @override
  Map<String, Object?> toJson() => {
        'type': 'new_chat',
        if (workspaceScope != null) 'workspace_scope': workspaceScope,
      };
}

class NanobotAttachEnvelope extends NanobotOutboundEnvelope {
  const NanobotAttachEnvelope({required this.chatId});

  final String chatId;

  @override
  Map<String, Object?> toJson() => {
        'type': 'attach',
        'chat_id': chatId,
      };
}

class NanobotMessageEnvelope extends NanobotOutboundEnvelope {
  const NanobotMessageEnvelope({
    required this.chatId,
    required this.content,
    this.workspaceScope,
    this.turnId,
  });

  final String chatId;
  final String content;
  final Map<String, Object?>? workspaceScope;
  final String? turnId;

  @override
  Map<String, Object?> toJson() => {
        'type': 'message',
        'chat_id': chatId,
        'content': content,
        if (workspaceScope != null) 'workspace_scope': workspaceScope,
        if (turnId != null) 'turn_id': turnId,
        'webui': true,
      };
}

class NanobotSetWorkspaceScopeEnvelope extends NanobotOutboundEnvelope {
  const NanobotSetWorkspaceScopeEnvelope({
    required this.chatId,
    required this.workspaceScope,
  });

  final String chatId;
  final Map<String, Object?> workspaceScope;

  @override
  Map<String, Object?> toJson() => {
        'type': 'set_workspace_scope',
        'chat_id': chatId,
        'workspace_scope': workspaceScope,
      };
}

NanobotInboundEventType _eventType(String event) {
  return switch (event) {
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
```

- [ ] **Step 5: Run protocol tests**

Run:

```sh
flutter test test/nanobot_protocol_test.dart
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```sh
git add lib/features/nanobot/data/protocol/nanobot_http_dto.dart lib/features/nanobot/data/protocol/nanobot_ws_envelope.dart test/nanobot_protocol_test.dart
git commit -m "feat: add nanobot protocol models"
```

---

## Task 3: HTTP Runtime Host and API

**Files:**
- Create: `lib/core/network/nanobot_http.dart`
- Create: `lib/features/nanobot/domain/nanobot_connection.dart`
- Create: `lib/features/nanobot/domain/nanobot_session.dart`
- Create: `lib/features/nanobot/domain/nanobot_workspace.dart`
- Create: `lib/features/nanobot/data/nanobot_runtime_host.dart`
- Create: `lib/features/nanobot/data/nanobot_http_api.dart`
- Test: `test/nanobot_http_api_test.dart`

- [ ] **Step 1: Write HTTP API tests**

Create `test/nanobot_http_api_test.dart` with fake Dio responses:

```dart
import 'dart:convert';

import 'package:agent_client/features/nanobot/data/nanobot_http_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bootstrap sends X-Nanobot-Auth and parses token', () async {
    final adapter = _FakeAdapter((options) {
      expect(options.path, '/webui/bootstrap');
      expect(options.headers['X-Nanobot-Auth'], 'secret');
      return ResponseBody.fromString(
        jsonEncode({
          'token': 'tok',
          'ws_path': '/',
          'ws_url': 'ws://127.0.0.1:8765/',
          'expires_in': 300,
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    });
    final api = NanobotHttpApi(
      dio: Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8765'))
        ..httpClientAdapter = adapter,
    );

    final bootstrap = await api.bootstrap(secret: 'secret');

    expect(bootstrap.token, 'tok');
  });

  test('listSessions attaches bearer token', () async {
    final adapter = _FakeAdapter((options) {
      expect(options.path, '/api/sessions');
      expect(options.headers['Authorization'], 'Bearer tok');
      return ResponseBody.fromString(
        jsonEncode({'sessions': []}),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    });
    final api = NanobotHttpApi(
      dio: Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8765'))
        ..httpClientAdapter = adapter,
    );

    final sessions = await api.listSessions(token: 'tok');

    expect(sessions, isEmpty);
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
```

- [ ] **Step 2: Run failing HTTP API tests**

Run:

```sh
flutter test test/nanobot_http_api_test.dart
```

Expected: fail because HTTP API files do not exist.

- [ ] **Step 3: Implement HTTP client helper**

Create `lib/core/network/nanobot_http.dart`:

```dart
import 'package:dio/dio.dart';

Dio createNanobotDio({required String baseUrl}) {
  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
    ),
  );
}

class NanobotApiException implements Exception {
  const NanobotApiException({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() {
    final status = statusCode == null ? '' : ' ($statusCode)';
    return 'NanobotApiException$status: $message';
  }
}
```

- [ ] **Step 4: Implement domain models**

Create `lib/features/nanobot/domain/nanobot_connection.dart`:

```dart
class NanobotBootstrap {
  const NanobotBootstrap({
    required this.token,
    required this.wsPath,
    required this.expiresIn,
    required this.fetchedAt,
    this.wsUrl,
    this.modelName,
    this.runtimeSurface = 'browser',
    this.runtimeCapabilities = const {},
  });

  final String token;
  final String wsPath;
  final String? wsUrl;
  final Duration expiresIn;
  final DateTime fetchedAt;
  final String? modelName;
  final String runtimeSurface;
  final Map<String, Object?> runtimeCapabilities;

  DateTime get expiresAt => fetchedAt.add(expiresIn);
}

enum NanobotConnectionPhase {
  unconfigured,
  authRequired,
  bootstrapLoading,
  connected,
  websocketConnecting,
  websocketOpen,
  reconnecting,
  offline,
  authFailed,
  tokenRefreshFailed,
}
```

Create `lib/features/nanobot/domain/nanobot_session.dart`:

```dart
import 'package:agent_client/features/nanobot/domain/nanobot_workspace.dart';

class NanobotSessionSummary {
  const NanobotSessionSummary({
    required this.key,
    required this.channel,
    required this.chatId,
    this.createdAt,
    this.updatedAt,
    this.title = '',
    this.preview = '',
    this.runStartedAt,
    this.workspaceScope,
  });

  final String key;
  final String channel;
  final String chatId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String title;
  final String preview;
  final double? runStartedAt;
  final NanobotWorkspaceScope? workspaceScope;
}
```

Create `lib/features/nanobot/domain/nanobot_workspace.dart`:

```dart
class NanobotWorkspaceScope {
  const NanobotWorkspaceScope({
    required this.projectPath,
    required this.accessMode,
    this.projectName,
    this.raw = const {},
  });

  final String projectPath;
  final String? projectName;
  final String accessMode;
  final Map<String, Object?> raw;

  Map<String, Object?> toJson() => {
        ...raw,
        'project_path': projectPath,
        if (projectName != null) 'project_name': projectName,
        'access_mode': accessMode,
      };

  factory NanobotWorkspaceScope.fromJson(Map<String, Object?> json) {
    return NanobotWorkspaceScope(
      projectPath: json['project_path'] is String
          ? json['project_path'] as String
          : '',
      projectName: json['project_name'] is String
          ? json['project_name'] as String
          : null,
      accessMode: json['access_mode'] is String
          ? json['access_mode'] as String
          : 'restricted',
      raw: json,
    );
  }
}
```

- [ ] **Step 5: Implement HTTP API wrapper**

Create `lib/features/nanobot/data/nanobot_http_api.dart` with methods:

```dart
import 'package:agent_client/core/network/nanobot_http.dart';
import 'package:agent_client/features/nanobot/data/protocol/nanobot_http_dto.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_connection.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_workspace.dart';
import 'package:dio/dio.dart';

class NanobotHttpApi {
  const NanobotHttpApi({required this.dio});

  final Dio dio;

  Future<NanobotBootstrap> bootstrap({String? secret}) async {
    final response = await _getJson(
      '/webui/bootstrap',
      headers: {
        if (secret != null && secret.trim().isNotEmpty)
          'X-Nanobot-Auth': secret.trim(),
      },
    );
    final dto = NanobotBootstrapDto.fromJson(response);
    return NanobotBootstrap(
      token: dto.token,
      wsPath: dto.wsPath,
      wsUrl: dto.wsUrl,
      expiresIn: dto.expiresIn,
      fetchedAt: DateTime.now(),
      modelName: dto.modelName,
      runtimeSurface: dto.runtimeSurface,
      runtimeCapabilities: dto.runtimeCapabilities,
    );
  }

  Future<List<NanobotSessionSummary>> listSessions({
    required String token,
  }) async {
    final response = await _getJson('/api/sessions', token: token);
    final dto = NanobotSessionsDto.fromJson(response);
    return [
      for (final session in dto.sessions)
        NanobotSessionSummary(
          key: session.key,
          channel: session.channel,
          chatId: session.chatId,
          createdAt: session.createdAt,
          updatedAt: session.updatedAt,
          title: session.title,
          preview: session.preview,
          runStartedAt: session.runStartedAt,
          workspaceScope: session.workspaceScope == null
              ? null
              : NanobotWorkspaceScope.fromJson(session.workspaceScope!),
        ),
    ];
  }

  Future<Map<String, Object?>> fetchThread({
    required String token,
    required String sessionKey,
    int limit = 160,
    String? direction = 'latest',
    String? before,
  }) async {
    final query = <String, Object?>{
      'limit': limit,
      if (direction != null) 'direction': direction,
      if (before != null) 'before': before,
    };
    return _getJson(
      '/api/sessions/${Uri.encodeComponent(sessionKey)}/webui-thread',
      token: token,
      queryParameters: query,
    );
  }

  Future<Map<String, Object?>> fetchWorkspaces({required String token}) {
    return _getJson('/api/workspaces', token: token);
  }

  Future<List<Map<String, Object?>>> listCommands({required String token}) async {
    final body = await _getJson('/api/commands', token: token);
    final commands = body['commands'];
    if (commands is! List) return const [];
    return [
      for (final command in commands)
        if (command is Map) Map<String, Object?>.from(command),
    ];
  }

  Future<Map<String, Object?>> _getJson(
    String path, {
    String? token,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  }) async {
    try {
      final response = await dio.get<Object?>(
        path,
        queryParameters: queryParameters,
        options: Options(
          headers: {
            ...?headers,
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      final data = response.data;
      if (data is Map<String, Object?>) return data;
      if (data is Map) return Map<String, Object?>.from(data);
      throw const NanobotApiException(message: 'Gateway returned non-JSON data');
    } on DioException catch (error) {
      throw NanobotApiException(
        message: error.response?.data?.toString() ?? error.message ?? 'Request failed',
        statusCode: error.response?.statusCode,
      );
    }
  }
}
```

- [ ] **Step 6: Implement runtime host**

Create `lib/features/nanobot/data/nanobot_runtime_host.dart`:

```dart
import 'package:agent_client/core/network/nanobot_http.dart';
import 'package:agent_client/features/nanobot/data/nanobot_http_api.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_connection.dart';

abstract interface class NanobotRuntimeHost {
  Future<NanobotBootstrap> bootstrap({
    required Uri gatewayBaseUrl,
    String? secret,
  });

  Stream<NanobotRuntimeHostStatus> watchStatus();
}

class NanobotRuntimeHostStatus {
  const NanobotRuntimeHostStatus({required this.ready});

  final bool ready;
}

class ExternalGatewayRuntimeHost implements NanobotRuntimeHost {
  const ExternalGatewayRuntimeHost();

  @override
  Future<NanobotBootstrap> bootstrap({
    required Uri gatewayBaseUrl,
    String? secret,
  }) {
    final api = NanobotHttpApi(
      dio: createNanobotDio(baseUrl: gatewayBaseUrl.toString()),
    );
    return api.bootstrap(secret: secret);
  }

  @override
  Stream<NanobotRuntimeHostStatus> watchStatus() {
    return const Stream<NanobotRuntimeHostStatus>.empty();
  }
}
```

- [ ] **Step 7: Run HTTP API tests**

Run:

```sh
flutter test test/nanobot_http_api_test.dart
```

Expected: all tests pass.

- [ ] **Step 8: Commit**

```sh
git add lib/core/network/nanobot_http.dart lib/features/nanobot/domain/nanobot_connection.dart lib/features/nanobot/domain/nanobot_session.dart lib/features/nanobot/domain/nanobot_workspace.dart lib/features/nanobot/data/nanobot_runtime_host.dart lib/features/nanobot/data/nanobot_http_api.dart test/nanobot_http_api_test.dart
git commit -m "feat: add nanobot http runtime API"
```

---

## Task 4: WebSocket Client

**Files:**
- Create: `lib/core/network/nanobot_websocket.dart`
- Create: `lib/features/nanobot/data/nanobot_ws_client.dart`
- Test: `test/nanobot_ws_client_test.dart`

- [ ] **Step 1: Write WebSocket client tests**

Create `test/nanobot_ws_client_test.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:agent_client/features/nanobot/data/nanobot_ws_client.dart';
import 'package:agent_client/features/nanobot/data/protocol/nanobot_ws_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('connect parses inbound events and sends outbound JSON', () async {
    final fake = FakeNanobotSocket();
    final client = NanobotWsClient(connector: (_) async => fake);
    final events = <NanobotInboundEnvelope>[];
    final sub = client.events.listen(events.add);
    addTearDown(sub.cancel);

    await client.connect(Uri.parse('ws://127.0.0.1:8765/?token=tok'));
    fake.serverAdd('{"event":"ready","chat_id":"chat-1","client_id":"client"}');
    await pumpEventQueue();

    client.send(const NanobotOutboundEnvelope.attach(chatId: 'chat-1'));

    expect(events.single.event, NanobotInboundEventType.ready);
    expect(fake.clientFrames.single, '{"type":"attach","chat_id":"chat-1"}');
  });
}

class FakeNanobotSocket implements NanobotSocket {
  final _server = StreamController<String>.broadcast();
  final clientFrames = <String>[];

  @override
  Stream<String> get stream => _server.stream;

  @override
  void add(String text) {
    clientFrames.add(text);
  }

  void serverAdd(String text) {
    _server.add(text);
  }

  @override
  Future<void> close() async {
    await _server.close();
  }
}
```

- [ ] **Step 2: Run failing WebSocket tests**

Run:

```sh
flutter test test/nanobot_ws_client_test.dart
```

Expected: fail because socket abstractions do not exist.

- [ ] **Step 3: Implement socket abstraction**

Create `lib/core/network/nanobot_websocket.dart`:

```dart
import 'package:web_socket_channel/web_socket_channel.dart';

abstract interface class NanobotSocket {
  Stream<String> get stream;
  void add(String text);
  Future<void> close();
}

typedef NanobotSocketConnector = Future<NanobotSocket> Function(Uri uri);

class WebSocketChannelNanobotSocket implements NanobotSocket {
  WebSocketChannelNanobotSocket(this._channel);

  final WebSocketChannel _channel;

  @override
  Stream<String> get stream => _channel.stream.where((event) => event is String).cast<String>();

  @override
  void add(String text) {
    _channel.sink.add(text);
  }

  @override
  Future<void> close() async {
    await _channel.sink.close();
  }
}

Future<NanobotSocket> connectNanobotSocket(Uri uri) async {
  return WebSocketChannelNanobotSocket(WebSocketChannel.connect(uri));
}
```

- [ ] **Step 4: Implement WebSocket client**

Create `lib/features/nanobot/data/nanobot_ws_client.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:agent_client/core/network/nanobot_websocket.dart';
import 'package:agent_client/features/nanobot/data/protocol/nanobot_ws_envelope.dart';

class NanobotWsClient {
  NanobotWsClient({NanobotSocketConnector connector = connectNanobotSocket})
      : _connector = connector;

  final NanobotSocketConnector _connector;
  final _events = StreamController<NanobotInboundEnvelope>.broadcast();
  NanobotSocket? _socket;

  Stream<NanobotInboundEnvelope> get events => _events.stream;

  Future<void> connect(Uri uri) async {
    await close();
    final socket = await _connector(uri);
    _socket = socket;
    socket.stream.listen(
      _handleText,
      onError: (Object error, StackTrace stackTrace) {
        _events.add(
          NanobotInboundEnvelope(
            event: NanobotInboundEventType.error,
            raw: {'event': 'error', 'detail': error.toString()},
            detail: error.toString(),
          ),
        );
      },
    );
  }

  void send(NanobotOutboundEnvelope envelope) {
    _socket?.add(jsonEncode(envelope.toJson()));
  }

  Future<void> close() async {
    final socket = _socket;
    _socket = null;
    await socket?.close();
  }

  Future<void> dispose() async {
    await close();
    await _events.close();
  }

  void _handleText(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        _events.add(
          NanobotInboundEnvelope.fromJson(Map<String, Object?>.from(decoded)),
        );
      }
    } on Object {
      _events.add(
        const NanobotInboundEnvelope(
          event: NanobotInboundEventType.unknown,
          raw: {'event': 'unknown'},
        ),
      );
    }
  }
}
```

- [ ] **Step 5: Run WebSocket tests**

Run:

```sh
flutter test test/nanobot_ws_client_test.dart
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```sh
git add lib/core/network/nanobot_websocket.dart lib/features/nanobot/data/nanobot_ws_client.dart test/nanobot_ws_client_test.dart
git commit -m "feat: add nanobot websocket client"
```

---

## Task 5: Thread Domain and Reducer

**Files:**
- Create: `lib/features/nanobot/domain/nanobot_thread_message.dart`
- Create: `lib/features/nanobot/domain/nanobot_thread_state.dart`
- Test: `test/nanobot_thread_reducer_test.dart`

- [ ] **Step 1: Write reducer tests**

Create `test/nanobot_thread_reducer_test.dart`:

```dart
import 'package:agent_client/features/nanobot/data/protocol/nanobot_ws_envelope.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_thread_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('delta creates and updates streaming assistant message', () {
    final initial = NanobotThreadState.empty(sessionKey: 'websocket:chat-1');
    final next = reduceNanobotThread(
      initial,
      NanobotInboundEnvelope.fromJson({
        'event': 'delta',
        'chat_id': 'chat-1',
        'text': 'hello',
        'turn_id': 'turn-1',
      }),
    );

    expect(next.isStreaming, isTrue);
    expect(next.messages.single.role, NanobotThreadRole.assistant);
    expect(next.messages.single.content, 'hello');
  });

  test('reasoning delta and end update reasoning state', () {
    final initial = NanobotThreadState.empty(sessionKey: 'websocket:chat-1');
    final withReasoning = reduceNanobotThread(
      initial,
      NanobotInboundEnvelope.fromJson({
        'event': 'reasoning_delta',
        'chat_id': 'chat-1',
        'text': 'thinking',
      }),
    );
    final closed = reduceNanobotThread(
      withReasoning,
      NanobotInboundEnvelope.fromJson({
        'event': 'reasoning_end',
        'chat_id': 'chat-1',
      }),
    );

    expect(withReasoning.messages.single.reasoning, 'thinking');
    expect(withReasoning.messages.single.reasoningStreaming, isTrue);
    expect(closed.messages.single.reasoningStreaming, isFalse);
  });

  test('turn end finalizes streaming', () {
    final streaming = NanobotThreadState.empty(sessionKey: 'websocket:chat-1')
        .copyWith(isStreaming: true);
    final next = reduceNanobotThread(
      streaming,
      NanobotInboundEnvelope.fromJson({
        'event': 'turn_end',
        'chat_id': 'chat-1',
        'latency_ms': 42,
      }),
    );

    expect(next.isStreaming, isFalse);
  });
}
```

- [ ] **Step 2: Run failing reducer tests**

Run:

```sh
flutter test test/nanobot_thread_reducer_test.dart
```

Expected: fail because thread domain files do not exist.

- [ ] **Step 3: Implement thread message model**

Create `lib/features/nanobot/domain/nanobot_thread_message.dart`:

```dart
enum NanobotThreadRole { user, assistant, tool, system }

enum NanobotThreadMessageKind { message, trace }

class NanobotThreadMessage {
  const NanobotThreadMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.kind = NanobotThreadMessageKind.message,
    this.isStreaming = false,
    this.reasoning,
    this.reasoningStreaming = false,
    this.turnId,
    this.turnPhase,
    this.turnSeq,
    this.toolEvents = const [],
    this.fileEdits = const [],
  });

  final String id;
  final NanobotThreadRole role;
  final String content;
  final DateTime createdAt;
  final NanobotThreadMessageKind kind;
  final bool isStreaming;
  final String? reasoning;
  final bool reasoningStreaming;
  final String? turnId;
  final String? turnPhase;
  final int? turnSeq;
  final List<Map<String, Object?>> toolEvents;
  final List<Map<String, Object?>> fileEdits;

  NanobotThreadMessage copyWith({
    String? id,
    NanobotThreadRole? role,
    String? content,
    DateTime? createdAt,
    NanobotThreadMessageKind? kind,
    bool? isStreaming,
    String? reasoning,
    bool? reasoningStreaming,
    String? turnId,
    String? turnPhase,
    int? turnSeq,
    List<Map<String, Object?>>? toolEvents,
    List<Map<String, Object?>>? fileEdits,
  }) {
    return NanobotThreadMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      kind: kind ?? this.kind,
      isStreaming: isStreaming ?? this.isStreaming,
      reasoning: reasoning ?? this.reasoning,
      reasoningStreaming: reasoningStreaming ?? this.reasoningStreaming,
      turnId: turnId ?? this.turnId,
      turnPhase: turnPhase ?? this.turnPhase,
      turnSeq: turnSeq ?? this.turnSeq,
      toolEvents: toolEvents ?? this.toolEvents,
      fileEdits: fileEdits ?? this.fileEdits,
    );
  }
}
```

- [ ] **Step 4: Implement reducer**

Create `lib/features/nanobot/domain/nanobot_thread_state.dart`:

```dart
import 'package:agent_client/features/nanobot/data/protocol/nanobot_ws_envelope.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_thread_message.dart';

class NanobotThreadState {
  const NanobotThreadState({
    required this.sessionKey,
    this.messages = const [],
    this.isStreaming = false,
    this.errorMessage,
  });

  factory NanobotThreadState.empty({required String sessionKey}) {
    return NanobotThreadState(sessionKey: sessionKey);
  }

  final String sessionKey;
  final List<NanobotThreadMessage> messages;
  final bool isStreaming;
  final String? errorMessage;

  NanobotThreadState copyWith({
    String? sessionKey,
    List<NanobotThreadMessage>? messages,
    bool? isStreaming,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NanobotThreadState(
      sessionKey: sessionKey ?? this.sessionKey,
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

NanobotThreadState reduceNanobotThread(
  NanobotThreadState state,
  NanobotInboundEnvelope event,
) {
  return switch (event.event) {
    NanobotInboundEventType.delta => _appendDelta(state, event),
    NanobotInboundEventType.streamEnd => _closeAssistantStream(state),
    NanobotInboundEventType.reasoningDelta => _appendReasoning(state, event),
    NanobotInboundEventType.reasoningEnd => _closeReasoning(state),
    NanobotInboundEventType.turnEnd => _closeAssistantStream(
        state.copyWith(isStreaming: false),
      ),
    NanobotInboundEventType.error => state.copyWith(
        errorMessage: event.detail ?? event.reason ?? 'Nanobot error',
        isStreaming: false,
      ),
    _ => state,
  };
}

NanobotThreadState _appendDelta(
  NanobotThreadState state,
  NanobotInboundEnvelope event,
) {
  final messages = [...state.messages];
  final index = _lastStreamingAssistant(messages);
  if (index == null) {
    messages.add(_assistantMessage(event).copyWith(content: event.text ?? ''));
  } else {
    final current = messages[index];
    messages[index] = current.copyWith(
      content: '${current.content}${event.text ?? ''}',
      isStreaming: true,
    );
  }
  return state.copyWith(messages: messages, isStreaming: true, clearError: true);
}

NanobotThreadState _appendReasoning(
  NanobotThreadState state,
  NanobotInboundEnvelope event,
) {
  final messages = [...state.messages];
  final index = _lastStreamingAssistant(messages);
  if (index == null) {
    messages.add(
      _assistantMessage(event).copyWith(
        reasoning: event.text ?? '',
        reasoningStreaming: true,
      ),
    );
  } else {
    final current = messages[index];
    messages[index] = current.copyWith(
      reasoning: '${current.reasoning ?? ''}${event.text ?? ''}',
      reasoningStreaming: true,
      isStreaming: true,
    );
  }
  return state.copyWith(messages: messages, isStreaming: true, clearError: true);
}

NanobotThreadState _closeReasoning(NanobotThreadState state) {
  final messages = [
    for (final message in state.messages)
      if (message.reasoningStreaming)
        message.copyWith(reasoningStreaming: false)
      else
        message,
  ];
  return state.copyWith(messages: messages);
}

NanobotThreadState _closeAssistantStream(NanobotThreadState state) {
  final messages = [
    for (final message in state.messages)
      if (message.isStreaming)
        message.copyWith(isStreaming: false, reasoningStreaming: false)
      else
        message,
  ];
  return state.copyWith(messages: messages, isStreaming: false);
}

NanobotThreadMessage _assistantMessage(NanobotInboundEnvelope event) {
  return NanobotThreadMessage(
    id: 'assistant-${DateTime.now().microsecondsSinceEpoch}',
    role: NanobotThreadRole.assistant,
    content: '',
    createdAt: DateTime.now(),
    isStreaming: true,
    turnId: event.turnId,
    turnPhase: event.turnPhase,
    turnSeq: event.turnSeq,
  );
}

int? _lastStreamingAssistant(List<NanobotThreadMessage> messages) {
  for (var index = messages.length - 1; index >= 0; index -= 1) {
    final message = messages[index];
    if (message.role == NanobotThreadRole.assistant && message.isStreaming) {
      return index;
    }
    if (message.role == NanobotThreadRole.user) break;
  }
  return null;
}
```

- [ ] **Step 5: Run reducer tests**

Run:

```sh
flutter test test/nanobot_thread_reducer_test.dart
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```sh
git add lib/features/nanobot/domain/nanobot_thread_message.dart lib/features/nanobot/domain/nanobot_thread_state.dart test/nanobot_thread_reducer_test.dart
git commit -m "feat: add nanobot thread reducer"
```

---

## Task 6: Drift Nanobot Cache

**Files:**
- Delete: `lib/data/local/app_database.dart`
- Delete: `lib/data/local/app_database.g.dart`
- Delete: `lib/data/local/app_database_provider.dart`
- Create: `lib/data/local/nanobot_cache_database.dart`
- Create: `lib/data/local/nanobot_cache_store.dart`
- Test: `test/nanobot_cache_store_test.dart`

- [ ] **Step 1: Write cache tests**

Create `test/nanobot_cache_store_test.dart`:

```dart
import 'package:agent_client/data/local/nanobot_cache_database.dart';
import 'package:agent_client/data/local/nanobot_cache_store.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late NanobotCacheDatabase database;
  late NanobotCacheStore store;

  setUp(() {
    database = NanobotCacheDatabase(NativeDatabase.memory());
    store = DriftNanobotCacheStore(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('stores latest thread by gateway and session key', () async {
    await store.replaceLatestThread(
      gatewayBaseUrl: 'http://127.0.0.1:8765',
      sessionKey: 'websocket:chat-1',
      messagesJson: '[{"id":"m1"}]',
    );

    expect(
      await store.loadLatestThread(
        gatewayBaseUrl: 'http://127.0.0.1:8765',
        sessionKey: 'websocket:chat-1',
      ),
      '[{"id":"m1"}]',
    );
    expect(
      await store.loadLatestThread(
        gatewayBaseUrl: 'http://other',
        sessionKey: 'websocket:chat-1',
      ),
      isNull,
    );
  });
}
```

- [ ] **Step 2: Run failing cache tests**

Run:

```sh
flutter test test/nanobot_cache_store_test.dart
```

Expected: fail because nanobot cache files do not exist.

- [ ] **Step 3: Replace Drift database**

Create `lib/data/local/nanobot_cache_database.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'nanobot_cache_database.g.dart';

@DataClassName('CachedNanobotThreadRow')
class CachedNanobotThreads extends Table {
  TextColumn get gatewayBaseUrl => text()();
  TextColumn get sessionKey => text()();
  TextColumn get messagesJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {gatewayBaseUrl, sessionKey};
}

@DriftDatabase(tables: [CachedNanobotThreads])
class NanobotCacheDatabase extends _$NanobotCacheDatabase {
  NanobotCacheDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'nanobot_client_cache',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
```

- [ ] **Step 4: Add cache store**

Create `lib/data/local/nanobot_cache_store.dart`:

```dart
import 'package:agent_client/data/local/nanobot_cache_database.dart';
import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract interface class NanobotCacheStore {
  Future<String?> loadLatestThread({
    required String gatewayBaseUrl,
    required String sessionKey,
  });

  Future<void> replaceLatestThread({
    required String gatewayBaseUrl,
    required String sessionKey,
    required String messagesJson,
  });
}

class DriftNanobotCacheStore implements NanobotCacheStore {
  const DriftNanobotCacheStore(this.database);

  final NanobotCacheDatabase database;

  @override
  Future<String?> loadLatestThread({
    required String gatewayBaseUrl,
    required String sessionKey,
  }) async {
    final row = await (database.select(database.cachedNanobotThreads)
          ..where((table) =>
              table.gatewayBaseUrl.equals(gatewayBaseUrl) &
              table.sessionKey.equals(sessionKey)))
        .getSingleOrNull();
    return row?.messagesJson;
  }

  @override
  Future<void> replaceLatestThread({
    required String gatewayBaseUrl,
    required String sessionKey,
    required String messagesJson,
  }) {
    return database.into(database.cachedNanobotThreads).insertOnConflictUpdate(
          CachedNanobotThreadsCompanion(
            gatewayBaseUrl: Value(gatewayBaseUrl),
            sessionKey: Value(sessionKey),
            messagesJson: Value(messagesJson),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }
}

final nanobotCacheDatabaseProvider = Provider<NanobotCacheDatabase>((ref) {
  final database = NanobotCacheDatabase();
  ref.onDispose(database.close);
  return database;
});

final nanobotCacheStoreProvider = Provider<NanobotCacheStore>((ref) {
  return DriftNanobotCacheStore(ref.watch(nanobotCacheDatabaseProvider));
});
```

- [ ] **Step 5: Generate Drift code**

Run:

```sh
dart run build_runner build --delete-conflicting-outputs
```

Expected: creates `lib/data/local/nanobot_cache_database.g.dart`.

- [ ] **Step 6: Delete old cache files**

Delete:

```sh
rm lib/data/local/app_database.dart lib/data/local/app_database.g.dart lib/data/local/app_database_provider.dart
```

Expected: files are removed. If another new file still imports them, fix that import in the same task before committing.

- [ ] **Step 7: Run cache tests**

Run:

```sh
flutter test test/nanobot_cache_store_test.dart
```

Expected: all tests pass.

- [ ] **Step 8: Commit**

```sh
git add lib/data/local test/nanobot_cache_store_test.dart
git add -u lib/data/local
git commit -m "feat: add nanobot drift cache"
```

---

## Task 7: Application Controllers

**Files:**
- Create: `lib/features/nanobot/application/nanobot_connection_controller.dart`
- Create: `lib/features/nanobot/application/nanobot_session_controller.dart`
- Create: `lib/features/nanobot/application/nanobot_thread_controller.dart`
- Create: `lib/features/nanobot/application/nanobot_workspace_controller.dart`
- Create: `test/helpers/nanobot_fakes.dart`
- Test: `test/nanobot_controllers_test.dart`

- [ ] **Step 1: Write controller tests**

Create `test/helpers/nanobot_fakes.dart`:

```dart
import 'package:agent_client/features/nanobot/domain/nanobot_connection.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';

class FakeNanobotBootstrap {
  static NanobotBootstrap value() {
    return NanobotBootstrap(
      token: 'tok',
      wsPath: '/',
      wsUrl: 'ws://127.0.0.1:8765/',
      expiresIn: const Duration(seconds: 300),
      fetchedAt: DateTime.now(),
      modelName: 'test-model',
    );
  }
}

class FakeNanobotSessions {
  static List<NanobotSessionSummary> value() {
    return const [
      NanobotSessionSummary(
        key: 'websocket:chat-1',
        channel: 'websocket',
        chatId: 'chat-1',
        title: 'Chat 1',
        preview: 'Preview',
      ),
    ];
  }
}
```

Create `test/nanobot_controllers_test.dart`:

```dart
import 'package:agent_client/core/config/nanobot_config.dart';
import 'package:agent_client/features/nanobot/application/nanobot_connection_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('connection controller starts in unconfigured-like disconnected state', () {
    final container = ProviderContainer(
      overrides: [
        nanobotConnectionInitialConfigProvider.overrideWithValue(
          const NanobotConfig(gatewayBaseUrl: 'http://127.0.0.1:8765'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = container.read(nanobotConnectionControllerProvider);

    expect(state.phase, NanobotConnectionPhase.unconfigured);
  });
}
```

- [ ] **Step 2: Run failing controller tests**

Run:

```sh
flutter test test/nanobot_controllers_test.dart
```

Expected: fail because controller files do not exist.

- [ ] **Step 3: Implement connection controller skeleton**

Create `lib/features/nanobot/application/nanobot_connection_controller.dart`:

```dart
import 'package:agent_client/core/config/nanobot_config.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_connection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NanobotConnectionState {
  const NanobotConnectionState({
    required this.config,
    this.phase = NanobotConnectionPhase.unconfigured,
    this.bootstrap,
    this.errorMessage,
  });

  final NanobotConfig config;
  final NanobotConnectionPhase phase;
  final NanobotBootstrap? bootstrap;
  final String? errorMessage;

  NanobotConnectionState copyWith({
    NanobotConfig? config,
    NanobotConnectionPhase? phase,
    NanobotBootstrap? bootstrap,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NanobotConnectionState(
      config: config ?? this.config,
      phase: phase ?? this.phase,
      bootstrap: bootstrap ?? this.bootstrap,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final nanobotConnectionInitialConfigProvider = Provider<NanobotConfig>((ref) {
  return NanobotConfig.defaults;
});

final nanobotConnectionControllerProvider =
    NotifierProvider<NanobotConnectionController, NanobotConnectionState>(
  NanobotConnectionController.new,
);

class NanobotConnectionController extends Notifier<NanobotConnectionState> {
  @override
  NanobotConnectionState build() {
    return NanobotConnectionState(
      config: ref.watch(nanobotConnectionInitialConfigProvider),
    );
  }
}
```

- [ ] **Step 4: Add session/thread/workspace controller skeletons**

Create each file with a compiling provider:

```dart
// lib/features/nanobot/application/nanobot_session_controller.dart
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NanobotSessionState {
  const NanobotSessionState({
    this.sessions = const [],
    this.activeSessionKey,
    this.loading = false,
    this.errorMessage,
  });

  final List<NanobotSessionSummary> sessions;
  final String? activeSessionKey;
  final bool loading;
  final String? errorMessage;
}

final nanobotSessionControllerProvider =
    NotifierProvider<NanobotSessionController, NanobotSessionState>(
  NanobotSessionController.new,
);

class NanobotSessionController extends Notifier<NanobotSessionState> {
  @override
  NanobotSessionState build() => const NanobotSessionState();
}
```

```dart
// lib/features/nanobot/application/nanobot_thread_controller.dart
import 'package:agent_client/features/nanobot/domain/nanobot_thread_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final nanobotThreadControllerProvider = NotifierProvider.family<
    NanobotThreadController,
    NanobotThreadState,
    String>(NanobotThreadController.new);

class NanobotThreadController extends FamilyNotifier<NanobotThreadState, String> {
  @override
  NanobotThreadState build(String arg) {
    return NanobotThreadState.empty(sessionKey: arg);
  }
}
```

```dart
// lib/features/nanobot/application/nanobot_workspace_controller.dart
import 'package:agent_client/features/nanobot/domain/nanobot_workspace.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NanobotWorkspaceState {
  const NanobotWorkspaceState({this.defaultScope, this.loading = false});

  final NanobotWorkspaceScope? defaultScope;
  final bool loading;
}

final nanobotWorkspaceControllerProvider =
    NotifierProvider<NanobotWorkspaceController, NanobotWorkspaceState>(
  NanobotWorkspaceController.new,
);

class NanobotWorkspaceController extends Notifier<NanobotWorkspaceState> {
  @override
  NanobotWorkspaceState build() => const NanobotWorkspaceState();
}
```

- [ ] **Step 5: Run controller tests**

Run:

```sh
flutter test test/nanobot_controllers_test.dart
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```sh
git add lib/features/nanobot/application test/helpers/nanobot_fakes.dart test/nanobot_controllers_test.dart
git commit -m "feat: add nanobot application controllers"
```

---

## Task 8: Nanobot Shell App Entry

**Files:**
- Modify: `lib/app/nanobot_app.dart`
- Create: `lib/features/nanobot/presentation/shell/nanobot_shell_page.dart`
- Test: `test/nanobot_shell_test.dart`

- [ ] **Step 1: Write shell widget tests**

Create `test/nanobot_shell_test.dart`:

```dart
import 'package:agent_client/app/nanobot_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets('NanobotApp renders shell title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NanobotApp()));

    expect(find.text('Nanobot'), findsWidgets);
    expect(find.byKey(const Key('nanobot-shell-page')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run failing shell test**

Run:

```sh
flutter test test/nanobot_shell_test.dart
```

Expected: fail because shell page does not exist or title is missing.

- [ ] **Step 3: Implement shell page**

Create `lib/features/nanobot/presentation/shell/nanobot_shell_page.dart`:

```dart
import 'package:flutter/material.dart';

class NanobotShellPage extends StatelessWidget {
  const NanobotShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('nanobot-shell-page'),
      body: SafeArea(
        child: Center(
          child: Text(
            'Nanobot',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
```

Modify `lib/app/nanobot_app.dart`:

```dart
import 'package:agent_client/app/theme/app_theme.dart';
import 'package:agent_client/features/nanobot/presentation/shell/nanobot_shell_page.dart';
import 'package:flutter/material.dart';

class NanobotApp extends StatelessWidget {
  const NanobotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nanobot',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const NanobotShellPage(),
    );
  }
}
```

- [ ] **Step 4: Run shell test**

Run:

```sh
flutter test test/nanobot_shell_test.dart
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```sh
git add lib/app/nanobot_app.dart lib/features/nanobot/presentation/shell/nanobot_shell_page.dart test/nanobot_shell_test.dart
git commit -m "feat: add nanobot shell entry"
```

---

## Task 9: Sidebar and Responsive Layout

**Files:**
- Modify: `lib/features/nanobot/presentation/shell/nanobot_shell_page.dart`
- Create: `lib/features/nanobot/presentation/sidebar/nanobot_sidebar.dart`
- Test: `test/nanobot_sidebar_test.dart`

- [ ] **Step 1: Write sidebar widget tests**

Create `test/nanobot_sidebar_test.dart`:

```dart
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';
import 'package:agent_client/features/nanobot/presentation/sidebar/nanobot_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sidebar renders new chat and sessions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NanobotSidebar(
          sessions: [
            NanobotSessionSummary(
              key: 'websocket:chat-1',
              channel: 'websocket',
              chatId: 'chat-1',
              title: 'Chat 1',
              preview: 'Preview',
            ),
          ],
        ),
      ),
    );

    expect(find.text('New chat'), findsOneWidget);
    expect(find.text('Chat 1'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run failing sidebar test**

Run:

```sh
flutter test test/nanobot_sidebar_test.dart
```

Expected: fail because `NanobotSidebar` does not exist.

- [ ] **Step 3: Implement sidebar**

Create `lib/features/nanobot/presentation/sidebar/nanobot_sidebar.dart`:

```dart
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';
import 'package:flutter/material.dart';

class NanobotSidebar extends StatelessWidget {
  const NanobotSidebar({
    super.key,
    this.sessions = const [],
    this.activeSessionKey,
    this.onNewChat,
    this.onSelectSession,
  });

  final List<NanobotSessionSummary> sessions;
  final String? activeSessionKey;
  final VoidCallback? onNewChat;
  final ValueChanged<NanobotSessionSummary>? onSelectSession;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: FilledButton.icon(
              onPressed: onNewChat,
              icon: const Icon(Icons.add),
              label: const Text('New chat'),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final selected = session.key == activeSessionKey;
                return ListTile(
                  key: Key('nanobot-session-${session.key}'),
                  selected: selected,
                  title: Text(
                    session.title.isEmpty ? 'Untitled chat' : session.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    session.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: session.runStartedAt == null
                      ? null
                      : const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                  onTap: () => onSelectSession?.call(session),
                );
              },
            ),
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Wire responsive shell**

Modify `lib/features/nanobot/presentation/shell/nanobot_shell_page.dart`:

```dart
import 'package:agent_client/app/adaptive/adaptive_layout_policy.dart';
import 'package:agent_client/features/nanobot/presentation/sidebar/nanobot_sidebar.dart';
import 'package:flutter/material.dart';

class NanobotShellPage extends StatelessWidget {
  const NanobotShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('nanobot-shell-page'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final policy = AdaptiveLayoutPolicy.fromWidth(constraints.maxWidth);
            if (policy.usesMobileWorkspace) {
              return const NanobotSidebar();
            }
            return const Row(
              children: [
                SizedBox(width: 300, child: NanobotSidebar()),
                VerticalDivider(width: 1),
                Expanded(
                  child: Center(child: Text('Nanobot')),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run sidebar test**

Run:

```sh
flutter test test/nanobot_sidebar_test.dart test/nanobot_shell_test.dart
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```sh
git add lib/features/nanobot/presentation/shell/nanobot_shell_page.dart lib/features/nanobot/presentation/sidebar/nanobot_sidebar.dart test/nanobot_sidebar_test.dart
git commit -m "feat: add nanobot sidebar shell"
```

---

## Task 10: Thread UI and Composer

**Files:**
- Create: `lib/features/nanobot/presentation/thread/nanobot_thread_shell.dart`
- Create: `lib/features/nanobot/presentation/thread/nanobot_thread_header.dart`
- Create: `lib/features/nanobot/presentation/thread/nanobot_thread_messages.dart`
- Create: `lib/features/nanobot/presentation/thread/nanobot_message_bubble.dart`
- Create: `lib/features/nanobot/presentation/thread/nanobot_activity_cluster.dart`
- Create: `lib/features/nanobot/presentation/thread/nanobot_thread_composer.dart`
- Modify: `lib/features/nanobot/presentation/shell/nanobot_shell_page.dart`
- Test: `test/nanobot_thread_widgets_test.dart`

- [ ] **Step 1: Write thread widget tests**

Create `test/nanobot_thread_widgets_test.dart`:

```dart
import 'package:agent_client/features/nanobot/domain/nanobot_thread_message.dart';
import 'package:agent_client/features/nanobot/presentation/thread/nanobot_thread_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('thread shell renders messages and composer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NanobotThreadShell(
          title: 'Chat 1',
          messages: [
            NanobotThreadMessage(
              id: 'm1',
              role: NanobotThreadRole.user,
              content: 'hello',
              createdAt: DateTime(2026),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Chat 1'), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
    expect(find.byKey(const Key('nanobot-thread-composer')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run failing thread widget tests**

Run:

```sh
flutter test test/nanobot_thread_widgets_test.dart
```

Expected: fail because thread widgets do not exist.

- [ ] **Step 3: Implement thread widgets**

Create `NanobotThreadShell`, header, messages, bubble, activity cluster, and composer with this minimum API:

```dart
// lib/features/nanobot/presentation/thread/nanobot_thread_shell.dart
import 'package:agent_client/features/nanobot/domain/nanobot_thread_message.dart';
import 'package:agent_client/features/nanobot/presentation/thread/nanobot_thread_composer.dart';
import 'package:agent_client/features/nanobot/presentation/thread/nanobot_thread_header.dart';
import 'package:agent_client/features/nanobot/presentation/thread/nanobot_thread_messages.dart';
import 'package:flutter/material.dart';

class NanobotThreadShell extends StatelessWidget {
  const NanobotThreadShell({
    super.key,
    required this.title,
    this.messages = const [],
    this.isStreaming = false,
    this.onSend,
    this.onStop,
  });

  final String title;
  final List<NanobotThreadMessage> messages;
  final bool isStreaming;
  final ValueChanged<String>? onSend;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NanobotThreadHeader(title: title),
        Expanded(child: NanobotThreadMessages(messages: messages)),
        NanobotThreadComposer(
          isStreaming: isStreaming,
          onSend: onSend,
          onStop: onStop,
        ),
      ],
    );
  }
}
```

```dart
// lib/features/nanobot/presentation/thread/nanobot_thread_header.dart
import 'package:flutter/material.dart';

class NanobotThreadHeader extends StatelessWidget {
  const NanobotThreadHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title.isEmpty ? 'New chat' : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}
```

```dart
// lib/features/nanobot/presentation/thread/nanobot_thread_messages.dart
import 'package:agent_client/features/nanobot/domain/nanobot_thread_message.dart';
import 'package:agent_client/features/nanobot/presentation/thread/nanobot_message_bubble.dart';
import 'package:flutter/material.dart';

class NanobotThreadMessages extends StatelessWidget {
  const NanobotThreadMessages({super.key, this.messages = const []});

  final List<NanobotThreadMessage> messages;

  @override
  Widget build(BuildContext context) {
    final reversed = messages.reversed.toList(growable: false);
    return ListView.builder(
      key: const Key('nanobot-thread-messages'),
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: reversed.length,
      itemBuilder: (context, index) {
        final message = reversed[index];
        return NanobotMessageBubble(
          key: ValueKey(message.id),
          message: message,
        );
      },
    );
  }
}
```

```dart
// lib/features/nanobot/presentation/thread/nanobot_message_bubble.dart
import 'package:agent_client/features/nanobot/domain/nanobot_thread_message.dart';
import 'package:agent_client/features/nanobot/presentation/thread/nanobot_activity_cluster.dart';
import 'package:flutter/material.dart';

class NanobotMessageBubble extends StatelessWidget {
  const NanobotMessageBubble({super.key, required this.message});

  final NanobotThreadMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == NanobotThreadRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isUser
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.reasoning?.isNotEmpty == true)
                    NanobotActivityCluster(label: 'Reasoning', text: message.reasoning!),
                  if (message.content.isNotEmpty) Text(message.content),
                  if (message.isStreaming)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

```dart
// lib/features/nanobot/presentation/thread/nanobot_activity_cluster.dart
import 'package:flutter/material.dart';

class NanobotActivityCluster extends StatelessWidget {
  const NanobotActivityCluster({
    super.key,
    required this.label,
    required this.text,
  });

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$label\n$text',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
```

```dart
// lib/features/nanobot/presentation/thread/nanobot_thread_composer.dart
import 'package:flutter/material.dart';

class NanobotThreadComposer extends StatefulWidget {
  const NanobotThreadComposer({
    super.key,
    this.isStreaming = false,
    this.onSend,
    this.onStop,
  });

  final bool isStreaming;
  final ValueChanged<String>? onSend;
  final VoidCallback? onStop;

  @override
  State<NanobotThreadComposer> createState() => _NanobotThreadComposerState();
}

class _NanobotThreadComposerState extends State<NanobotThreadComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('nanobot-thread-composer'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Message nanobot',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: widget.isStreaming ? 'Stop response' : 'Send',
              icon: Icon(widget.isStreaming ? Icons.stop : Icons.send),
              onPressed: widget.isStreaming ? widget.onStop : _send,
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend?.call(text);
    _controller.clear();
  }
}
```

- [ ] **Step 4: Run thread widget tests**

Run:

```sh
flutter test test/nanobot_thread_widgets_test.dart
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```sh
git add lib/features/nanobot/presentation/thread test/nanobot_thread_widgets_test.dart
git commit -m "feat: add nanobot thread widgets"
```

---

## Task 11: Wire Live Session and Thread Flow

**Files:**
- Modify: `lib/features/nanobot/application/nanobot_connection_controller.dart`
- Modify: `lib/features/nanobot/application/nanobot_session_controller.dart`
- Modify: `lib/features/nanobot/application/nanobot_thread_controller.dart`
- Modify: `lib/features/nanobot/presentation/shell/nanobot_shell_page.dart`
- Modify: `lib/features/nanobot/presentation/sidebar/nanobot_sidebar.dart`
- Modify: `lib/features/nanobot/presentation/thread/nanobot_thread_shell.dart`
- Test: `test/nanobot_live_flow_test.dart`

- [ ] **Step 1: Write live flow controller test**

Create `test/nanobot_live_flow_test.dart`:

```dart
import 'package:agent_client/features/nanobot/domain/nanobot_thread_message.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_thread_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('optimistic user message can be represented in thread state', () {
    final state = NanobotThreadState.empty(sessionKey: 'websocket:chat-1');
    final next = state.copyWith(
      messages: [
        NanobotThreadMessage(
          id: 'user-1',
          role: NanobotThreadRole.user,
          content: 'hello',
          createdAt: DateTime(2026),
        ),
      ],
      isStreaming: true,
    );

    expect(next.messages.single.content, 'hello');
    expect(next.isStreaming, isTrue);
  });
}
```

- [ ] **Step 2: Run live flow test**

Run:

```sh
flutter test test/nanobot_live_flow_test.dart
```

Expected: pass after Task 5. This locks the optimistic state shape before wiring.

- [ ] **Step 3: Add controller methods**

Extend `NanobotThreadController` with these methods:

```dart
Future<void> sendText(String text) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty || state.isStreaming) return;
  final userMessage = NanobotThreadMessage(
    id: 'user-${DateTime.now().microsecondsSinceEpoch}',
    role: NanobotThreadRole.user,
    content: trimmed,
    createdAt: DateTime.now(),
  );
  state = state.copyWith(
    messages: [...state.messages, userMessage],
    isStreaming: true,
    clearError: true,
  );
}

Future<void> stop() async {
  state = state.copyWith(isStreaming: false);
}
```

Then wire real WebSocket send in the same controller after `NanobotWsClient` and active `chatId` providers are available:

```dart
ref.read(nanobotWsClientProvider).send(
  NanobotOutboundEnvelope.message(
    chatId: chatId,
    content: trimmed,
    workspaceScope: workspaceScope?.toJson(),
    turnId: userMessage.id,
  ),
);
```

For stop:

```dart
ref.read(nanobotWsClientProvider).send(
  NanobotOutboundEnvelope.message(
    chatId: chatId,
    content: '/stop',
    workspaceScope: workspaceScope?.toJson(),
  ),
);
```

- [ ] **Step 4: Wire widgets to controllers**

Modify shell so selecting a session sets `activeSessionKey` and shows `NanobotThreadShell`.
The selected thread reads:

```dart
final thread = ref.watch(nanobotThreadControllerProvider(activeSessionKey));
```

Pass:

```dart
NanobotThreadShell(
  title: activeSession.title,
  messages: thread.messages,
  isStreaming: thread.isStreaming,
  onSend: (text) => ref
      .read(nanobotThreadControllerProvider(activeSessionKey).notifier)
      .sendText(text),
  onStop: () => ref
      .read(nanobotThreadControllerProvider(activeSessionKey).notifier)
      .stop(),
)
```

- [ ] **Step 5: Run focused tests**

Run:

```sh
flutter test test/nanobot_live_flow_test.dart test/nanobot_thread_widgets_test.dart test/nanobot_sidebar_test.dart
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```sh
git add lib/features/nanobot/application lib/features/nanobot/presentation test/nanobot_live_flow_test.dart
git commit -m "feat: wire nanobot session thread flow"
```

---

## Task 12: Light Secondary Views and Workspace Display

**Files:**
- Create: `lib/features/nanobot/presentation/settings/nanobot_settings_view.dart`
- Modify: `lib/features/nanobot/application/nanobot_workspace_controller.dart`
- Modify: `lib/features/nanobot/presentation/shell/nanobot_shell_page.dart`
- Modify: `lib/features/nanobot/presentation/thread/nanobot_thread_header.dart`
- Test: `test/nanobot_secondary_views_test.dart`

- [ ] **Step 1: Write secondary view tests**

Create `test/nanobot_secondary_views_test.dart`:

```dart
import 'package:agent_client/features/nanobot/presentation/settings/nanobot_settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('settings overview renders connection labels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NanobotSettingsView(
          gatewayBaseUrl: 'http://127.0.0.1:8765',
          modelName: 'test-model',
        ),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('http://127.0.0.1:8765'), findsOneWidget);
    expect(find.text('test-model'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run failing secondary view tests**

Run:

```sh
flutter test test/nanobot_secondary_views_test.dart
```

Expected: fail because settings view does not exist.

- [ ] **Step 3: Implement settings view**

Create `lib/features/nanobot/presentation/settings/nanobot_settings_view.dart`:

```dart
import 'package:flutter/material.dart';

class NanobotSettingsView extends StatelessWidget {
  const NanobotSettingsView({
    super.key,
    required this.gatewayBaseUrl,
    this.modelName,
  });

  final String gatewayBaseUrl;
  final String? modelName;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.link),
          title: const Text('Gateway'),
          subtitle: Text(gatewayBaseUrl),
        ),
        ListTile(
          leading: const Icon(Icons.memory),
          title: const Text('Model'),
          subtitle: Text(modelName?.isNotEmpty == true ? modelName! : 'Not reported'),
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.apps),
          title: Text('Apps'),
          subtitle: Text('Available after the core chat flow is stable.'),
        ),
        const ListTile(
          leading: Icon(Icons.auto_awesome),
          title: Text('Skills'),
          subtitle: Text('Available after the core chat flow is stable.'),
        ),
        const ListTile(
          leading: Icon(Icons.schedule),
          title: Text('Automations'),
          subtitle: Text('Available after the core chat flow is stable.'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Add workspace text to header**

Extend `NanobotThreadHeader` constructor:

```dart
const NanobotThreadHeader({
  super.key,
  required this.title,
  this.workspaceLabel,
  this.modelName,
});

final String? workspaceLabel;
final String? modelName;
```

Render a compact subtitle:

```dart
if (workspaceLabel?.isNotEmpty == true || modelName?.isNotEmpty == true)
  Text(
    [
      if (workspaceLabel?.isNotEmpty == true) workspaceLabel!,
      if (modelName?.isNotEmpty == true) modelName!,
    ].join(' • '),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.bodySmall,
  ),
```

- [ ] **Step 5: Run secondary tests**

Run:

```sh
flutter test test/nanobot_secondary_views_test.dart test/nanobot_thread_widgets_test.dart
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```sh
git add lib/features/nanobot/presentation/settings lib/features/nanobot/presentation/thread/nanobot_thread_header.dart test/nanobot_secondary_views_test.dart
git commit -m "feat: add nanobot settings overview"
```

---

## Task 13: Complete API Wiring and Cache Reconciliation

**Files:**
- Modify: `lib/features/nanobot/data/nanobot_http_api.dart`
- Modify: `lib/features/nanobot/domain/nanobot_thread_message.dart`
- Modify: `lib/features/nanobot/application/nanobot_connection_controller.dart`
- Modify: `lib/features/nanobot/application/nanobot_session_controller.dart`
- Modify: `lib/features/nanobot/application/nanobot_thread_controller.dart`
- Modify: `lib/data/local/nanobot_cache_store.dart`
- Test: `test/nanobot_api_wiring_test.dart`

- [ ] **Step 1: Write API wiring tests**

Create `test/nanobot_api_wiring_test.dart`:

```dart
import 'dart:convert';

import 'package:agent_client/features/nanobot/domain/nanobot_thread_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses WebUI thread messages into domain messages', () {
    final payload = {
      'messages': [
        {
          'id': 'm1',
          'role': 'user',
          'content': 'hello',
          'createdAt': 1782583290000,
        },
        {
          'id': 'm2',
          'role': 'assistant',
          'content': 'hi',
          'reasoning': 'thinking',
          'reasoningStreaming': false,
          'toolEvents': [
            {'name': 'read_file', 'phase': 'end'},
          ],
        },
      ],
    };

    final messages = nanobotThreadMessagesFromJsonList(
      payload['messages']! as List<Object?>,
    );

    expect(messages, hasLength(2));
    expect(messages.first.role, NanobotThreadRole.user);
    expect(messages.last.role, NanobotThreadRole.assistant);
    expect(messages.last.reasoning, 'thinking');
    expect(messages.last.toolEvents.single['name'], 'read_file');
  });

  test('thread messages serialize for cache', () {
    final messages = [
      NanobotThreadMessage(
        id: 'm1',
        role: NanobotThreadRole.user,
        content: 'hello',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1782583290000),
      ),
    ];

    final encoded = jsonEncode([
      for (final message in messages) message.toJson(),
    ]);
    final decoded = nanobotThreadMessagesFromJsonList(
      jsonDecode(encoded) as List<Object?>,
    );

    expect(decoded.single.id, 'm1');
    expect(decoded.single.content, 'hello');
  });
}
```

- [ ] **Step 2: Run failing API wiring tests**

Run:

```sh
flutter test test/nanobot_api_wiring_test.dart
```

Expected: fail because thread JSON parsing helpers do not exist.

- [ ] **Step 3: Add thread JSON parsing and serialization**

Extend `lib/features/nanobot/domain/nanobot_thread_message.dart`:

```dart
List<NanobotThreadMessage> nanobotThreadMessagesFromJsonList(List<Object?> rows) {
  return [
    for (final row in rows)
      if (row is Map) NanobotThreadMessage.fromJson(Map<String, Object?>.from(row)),
  ];
}

extension NanobotThreadMessageJson on NanobotThreadMessage {
  Map<String, Object?> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'kind': kind.name,
      'isStreaming': isStreaming,
      'createdAt': createdAt.millisecondsSinceEpoch,
      if (reasoning != null) 'reasoning': reasoning,
      'reasoningStreaming': reasoningStreaming,
      if (turnId != null) 'turnId': turnId,
      if (turnPhase != null) 'turnPhase': turnPhase,
      if (turnSeq != null) 'turnSeq': turnSeq,
      if (toolEvents.isNotEmpty) 'toolEvents': toolEvents,
      if (fileEdits.isNotEmpty) 'fileEdits': fileEdits,
    };
  }
}

// Add this factory inside the NanobotThreadMessage class body.
factory NanobotThreadMessage.fromJson(Map<String, Object?> json) {
  return NanobotThreadMessage(
    id: json['id'] is String ? json['id'] as String : 'hist-${json.hashCode}',
    role: _role(json['role']),
    content: json['content'] is String ? json['content'] as String : '',
    kind: json['kind'] == 'trace'
        ? NanobotThreadMessageKind.trace
        : NanobotThreadMessageKind.message,
    isStreaming: json['isStreaming'] == true,
    createdAt: _createdAt(json['createdAt']),
    reasoning: json['reasoning'] is String ? json['reasoning'] as String : null,
    reasoningStreaming: json['reasoningStreaming'] == true,
    turnId: json['turnId'] is String ? json['turnId'] as String : null,
    turnPhase: json['turnPhase'] is String ? json['turnPhase'] as String : null,
    turnSeq: json['turnSeq'] is num ? (json['turnSeq'] as num).toInt() : null,
    toolEvents: _mapList(json['toolEvents']),
    fileEdits: _mapList(json['fileEdits']),
  );
}

NanobotThreadRole _role(Object? value) {
  return switch (value) {
    'user' => NanobotThreadRole.user,
    'tool' => NanobotThreadRole.tool,
    'system' => NanobotThreadRole.system,
    _ => NanobotThreadRole.assistant,
  };
}

DateTime _createdAt(Object? value) {
  if (value is num) {
    final number = value.toInt();
    if (number > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(number);
    }
    return DateTime.fromMillisecondsSinceEpoch(number * 1000);
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

List<Map<String, Object?>> _mapList(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map) Map<String, Object?>.from(item),
  ];
}
```

- [ ] **Step 4: Add thread API parser**

Add to `NanobotHttpApi`:

```dart
Future<List<NanobotThreadMessage>> fetchThreadMessages({
  required String token,
  required String sessionKey,
  int limit = 160,
  String? before,
}) async {
  final body = await fetchThread(
    token: token,
    sessionKey: sessionKey,
    limit: limit,
    direction: before == null ? 'latest' : null,
    before: before,
  );
  final rows = body['messages'];
  if (rows is! List) return const [];
  return nanobotThreadMessagesFromJsonList(rows.cast<Object?>());
}
```

Add import:

```dart
import 'package:agent_client/features/nanobot/domain/nanobot_thread_message.dart';
```

- [ ] **Step 5: Complete connection bootstrap behavior**

Add to `NanobotConnectionController`:

```dart
Future<void> connect() async {
  state = state.copyWith(
    phase: NanobotConnectionPhase.bootstrapLoading,
    clearError: true,
  );
  try {
    final bootstrap = await ref.read(nanobotRuntimeHostProvider).bootstrap(
          gatewayBaseUrl: state.config.gatewayUri,
          secret: state.config.bootstrapSecret,
        );
    state = state.copyWith(
      phase: NanobotConnectionPhase.connected,
      bootstrap: bootstrap,
      clearError: true,
    );
  } on Object catch (error) {
    state = state.copyWith(
      phase: NanobotConnectionPhase.authFailed,
      errorMessage: error.toString(),
    );
  }
}
```

Add the provider:

```dart
final nanobotRuntimeHostProvider = Provider<NanobotRuntimeHost>((ref) {
  return const ExternalGatewayRuntimeHost();
});
```

- [ ] **Step 6: Complete session refresh behavior**

Add to `NanobotSessionController`:

```dart
Future<void> refresh() async {
  final connection = ref.read(nanobotConnectionControllerProvider);
  final token = connection.bootstrap?.token;
  if (token == null) return;
  state = state.copyWith(loading: true, clearError: true);
  try {
    final sessions = await ref.read(nanobotHttpApiProvider).listSessions(
          token: token,
        );
    state = state.copyWith(sessions: sessions, loading: false, clearError: true);
  } on Object catch (error) {
    state = state.copyWith(loading: false, errorMessage: error.toString());
  }
}
```

If `NanobotSessionState.copyWith` does not exist yet, add it with:

```dart
NanobotSessionState copyWith({
  List<NanobotSessionSummary>? sessions,
  String? activeSessionKey,
  bool? loading,
  String? errorMessage,
  bool clearError = false,
}) {
  return NanobotSessionState(
    sessions: sessions ?? this.sessions,
    activeSessionKey: activeSessionKey ?? this.activeSessionKey,
    loading: loading ?? this.loading,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}
```

- [ ] **Step 7: Complete thread history load with cache-first reconciliation**

Add to `NanobotThreadController`:

```dart
Future<void> loadLatest() async {
  final connection = ref.read(nanobotConnectionControllerProvider);
  final token = connection.bootstrap?.token;
  if (token == null) return;
  final gateway = connection.config.gatewayBaseUrl;
  final cache = ref.read(nanobotCacheStoreProvider);
  final cached = await cache.loadLatestThread(
    gatewayBaseUrl: gateway,
    sessionKey: arg,
  );
  if (cached != null && cached.isNotEmpty && state.messages.isEmpty) {
    final rows = jsonDecode(cached);
    if (rows is List) {
      state = state.copyWith(
        messages: nanobotThreadMessagesFromJsonList(rows.cast<Object?>()),
      );
    }
  }
  final messages = await ref.read(nanobotHttpApiProvider).fetchThreadMessages(
        token: token,
        sessionKey: arg,
      );
  state = state.copyWith(messages: messages, clearError: true);
  await cache.replaceLatestThread(
    gatewayBaseUrl: gateway,
    sessionKey: arg,
    messagesJson: jsonEncode([
      for (final message in messages) message.toJson(),
    ]),
  );
}
```

Add imports:

```dart
import 'dart:convert';
import 'package:agent_client/data/local/nanobot_cache_store.dart';
import 'package:agent_client/features/nanobot/application/nanobot_connection_controller.dart';
import 'package:agent_client/features/nanobot/data/nanobot_http_api.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_thread_message.dart';
```

- [ ] **Step 8: Run API wiring tests**

Run:

```sh
flutter test test/nanobot_api_wiring_test.dart test/nanobot_http_api_test.dart test/nanobot_cache_store_test.dart
```

Expected: all tests pass.

- [ ] **Step 9: Commit**

```sh
git add lib/features/nanobot/data/nanobot_http_api.dart lib/features/nanobot/domain/nanobot_thread_message.dart lib/features/nanobot/application lib/data/local/nanobot_cache_store.dart test/nanobot_api_wiring_test.dart
git commit -m "feat: wire nanobot api and thread cache"
```

---

## Task 14: Delete Old Architecture and Obsolete Tests

**Files:**
- Delete: old feature directories and old tests listed in the file map.
- Modify: `README.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: List old imports**

Run:

```sh
rg "features/(agent_control|agents|chat|files|git|settings|tasks)|AgentControl|AgentChatRepository|AgentRegistryRepository" lib test
```

Expected: prints old references before deletion.

- [ ] **Step 2: Delete old product directories**

Run:

```sh
rm -rf lib/features/agent_control lib/features/agents lib/features/chat lib/features/files lib/features/git lib/features/settings lib/features/tasks
```

Expected: directories are removed.

- [ ] **Step 3: Delete old tests**

Run:

```sh
rm -f test/agent_control_api_client_test.dart test/agent_control_sse_parser_test.dart test/agent_control_chat_repository_test.dart test/agent_controller_test.dart test/agent_shell_test.dart test/chat_controller_test.dart test/chat_input_bar_test.dart test/chat_message_list_test.dart test/chat_message_test.dart test/chat_session_rail_test.dart
```

Expected: old tests are removed. If additional tests fail only because they target deleted old features, delete those tests in this task and record their filenames in the commit body.

- [ ] **Step 4: Update README**

Replace `README.md` with:

````markdown
# Nanobot Client

Flutter native client for nanobot's WebUI-compatible gateway.

The app connects to a running nanobot gateway, uses `/webui/bootstrap` for
authentication, reads WebUI HTTP APIs, and streams turns through nanobot's
multiplexed WebSocket protocol.

## Run

Start nanobot separately:

```sh
nanobot gateway
```

Then run the Flutter app:

```sh
flutter run
```

The default gateway URL is `http://127.0.0.1:8765`. You can override it at run
time:

```sh
flutter run --dart-define=NANOBOT_GATEWAY_BASE_URL=http://127.0.0.1:8765
```

## Development

```sh
flutter analyze
flutter test
git diff --check
```

Use `flutter test --no-pub` only when Flutter platform cache refresh blocks
normal tests.
````

- [ ] **Step 5: Update AGENTS.md**

Edit `AGENTS.md` so it states:

````markdown
# AGENTS.md

This repository is a Flutter native client for nanobot. Nanobot WebUI is the
source of truth for protocol, state, and UI behavior.

## Architecture

- Do not add generic multi-agent backend ports.
- Do not reintroduce Agent Control code.
- Keep nanobot HTTP DTOs and WebSocket envelopes in
  `lib/features/nanobot/data/protocol/`.
- Presentation widgets consume nanobot domain/application state, not raw maps.
- Session identity is `sessionKey = websocket:<chat_id>` and `chatId`.
- Local cache keys are `gatewayBaseUrl + sessionKey`.
- The first runtime mode connects to an already running nanobot gateway.
- Future local process management must enter through a runtime host boundary,
  not through UI widgets.

## Development Commands

```sh
flutter analyze
flutter test
git diff --check
```
````

- [ ] **Step 6: Verify no old imports remain**

Run:

```sh
rg "features/(agent_control|agents|chat|files|git|settings|tasks)|AgentControl|AgentChatRepository|AgentRegistryRepository" lib test README.md AGENTS.md
```

Expected: no matches.

- [ ] **Step 7: Run analyzer and tests**

Run:

```sh
flutter analyze
flutter test
```

Expected: both pass.

- [ ] **Step 8: Commit**

```sh
git add -A lib test README.md AGENTS.md
git commit -m "refactor: remove old agent architecture"
```

---

## Task 15: Gateway Integration and Device Testing

**Files:**
- Modify only if test failures reveal app bugs. Do not commit secrets.

- [ ] **Step 1: Verify gateway bootstrap from terminal without storing secret**

Run:

```sh
read -r -s NANOBOT_WEBUI_SECRET
printf '\n'
curl -sS -H "X-Nanobot-Auth: $NANOBOT_WEBUI_SECRET" http://192.168.55.130:8765/webui/bootstrap | python3 -m json.tool
unset NANOBOT_WEBUI_SECRET
```

Expected: JSON with `token`, `ws_path`, `ws_url`, and `expires_in`. The secret must not appear in terminal output.

- [ ] **Step 2: Run full static verification**

Run:

```sh
flutter analyze
flutter test
git diff --check
```

Expected: all pass.

- [ ] **Step 3: List devices**

Run:

```sh
flutter devices
```

Expected: at least one runnable target appears. Record the chosen device ID in the final implementation summary, not in code.

- [ ] **Step 4: Run on a device**

Run with a real device ID from the previous command:

```sh
flutter run --dart-define=NANOBOT_GATEWAY_BASE_URL=http://192.168.55.130:8765
```

Expected: app launches on the selected device. If multiple devices are attached, use Flutter's interactive device selection or add `-d` with the selected ID from `flutter devices`.

- [ ] **Step 5: Manual device test checklist**

On the device:

- Open the app.
- Enter gateway URL `http://192.168.55.130:8765`.
- Enter the WebUI secret supplied in the thread.
- Connect successfully.
- Confirm session list appears or empty state appears.
- Create a new chat.
- Send `hello`.
- Confirm streaming response appears.
- Send a longer prompt that triggers reasoning or activity if available.
- Press stop while a response is running and confirm streaming stops locally.
- Reopen the same session and confirm history loads from `/webui-thread`.
- Kill and relaunch the app; confirm cached state appears before remote refresh.

- [ ] **Step 6: Commit final fixes**

If device testing required fixes:

```sh
git add -A
git commit -m "fix: pass nanobot device smoke test"
```

If no fixes were required, do not create an empty commit.

---

## Final Verification Before Completion

Run:

```sh
flutter analyze
flutter test
git diff --check
flutter devices
```

Then repeat the device checklist against `http://192.168.55.130:8765`.

Completion requires:

- Automated checks pass.
- Device test passes.
- No old Agent Control or multi-agent code remains.
- No secret is committed.
- Final response reports the exact test commands used and the device target.
