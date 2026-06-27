# Nanobot-First Client Redesign

## Status

Approved direction for design planning. This document captures the target
architecture before implementation planning starts.

## Background

The current Flutter app was designed as a general multi-agent client with an
Agent Control v1 backend adapter. The product direction has changed. The client
will now target nanobot first and should behave as a native Flutter
implementation of nanobot's WebUI, not as a generic agent platform.

The local nanobot source at `/Users/yaotutu/Desktop/code/nanobot` shows that the
WebUI public surface is:

- `GET /webui/bootstrap` for short-lived auth tokens, WebSocket URL, runtime
  surface, capabilities, and model name.
- HTTP WebUI APIs such as `/api/sessions`,
  `/api/sessions/:key/webui-thread`, `/api/workspaces`, `/api/commands`,
  `/api/settings`, `/api/webui/skills`, and automation routes.
- A multiplexed WebSocket protocol with typed outbound envelopes:
  `new_chat`, `attach`, `fork_chat`, `message`, `set_workspace_scope`, and
  `transcribe_audio`.
- WebSocket inbound events including `ready`, `attached`, `delta`,
  `stream_end`, `reasoning_delta`, `reasoning_end`, `message`, `file_edit`,
  `turn_end`, `goal_status`, `goal_state`, `session_updated`,
  `runtime_model_updated`, and `error`.

## Goals

- Make the Flutter app nanobot-first at the architecture, protocol, state, and
  UI levels.
- Align all APIs with nanobot WebUI behavior and payloads.
- Align the UI information architecture with nanobot WebUI: sidebar, thread,
  composer, settings/apps/skills/automations entries, and activity rendering.
- Connect to an already running nanobot gateway in the first release, typically
  `http://127.0.0.1:8765`.
- Keep a narrow runtime host boundary so a future native host can start,
  restart, and diagnose a local nanobot process without another rewrite.
- Delete old Agent Control and multi-agent code. Do not preserve legacy
  compatibility or hidden legacy entry points.

## Non-Goals

- Supporting Agent Control v1 after this redesign.
- Keeping the previous generic backend port architecture.
- Migrating old local agent chat cache data.
- Starting or managing the nanobot process in the first release.
- Pixel-perfect CSS reproduction. Flutter should match WebUI structure,
  behavior, hierarchy, and states, while using native Flutter implementation
  details.

## Hard Decisions

1. Nanobot WebUI is the source of truth for protocol and UI behavior.
2. The main app entry becomes a nanobot shell, not an agent workspace.
3. Session identity is `sessionKey = websocket:<chat_id>` and `chatId`, not
   `agentId + sessionId`.
4. Local cache keys use `gatewayBaseUrl + sessionKey`.
5. Old code is removed rather than marked legacy.
6. The first runtime mode is "external gateway": the user runs
   `nanobot gateway`, and Flutter connects to it.
7. A future "managed local runtime" is represented by an interface only, not by
   first-release process management.

## Target Directory Shape

```text
lib/
  app/
    adaptive/
    theme/
    nanobot_app.dart

  core/
    config/
      nanobot_config.dart
      nanobot_config_store.dart
    network/
      nanobot_http.dart
      nanobot_websocket.dart

  data/local/
    nanobot_cache_database.dart
    nanobot_thread_cache_store.dart

  features/
    nanobot/
      data/
        protocol/
          nanobot_http_dto.dart
          nanobot_ws_envelope.dart
        nanobot_bootstrap_repository.dart
        nanobot_session_repository.dart
        nanobot_thread_repository.dart
        nanobot_workspace_repository.dart
        nanobot_settings_repository.dart
      domain/
        nanobot_bootstrap.dart
        nanobot_connection.dart
        nanobot_session.dart
        nanobot_thread_message.dart
        nanobot_stream_event.dart
        nanobot_workspace.dart
      application/
        nanobot_connection_controller.dart
        nanobot_session_controller.dart
        nanobot_thread_controller.dart
        nanobot_workspace_controller.dart
      presentation/
        shell/
        sidebar/
        thread/
        settings/
        shared/
```

The exact file list can change during implementation, but ownership should not:
transport DTOs live in `data/protocol`, domain models expose nanobot concepts,
controllers own UI state transitions, and presentation widgets do not parse raw
protocol maps.

## Code Removal Scope

Implementation should remove the old product architecture, including:

- `features/agent_control/`.
- The old multi-agent registry and navigation in `features/agents/`.
- The old `features/chat/` repository/controller/cache model built around
  `AgentChatRepository` and `agentId + sessionId`.
- Agent Control oriented files/git/settings ports and adapters.
- Tests that only validate Agent Control, generic multi-backend routing, old
  agent registry behavior, or old cache semantics.
- README and architecture docs that describe the app as a generic multi-agent
  client.

Reusable infrastructure may stay if it is renamed or reshaped for nanobot:

- Flutter platform folders and build configuration.
- Theme tokens, after visual review against WebUI.
- Adaptive layout policy, after renaming workspace concepts to nanobot shell
  concepts.
- Drift as the local cache technology, with destructive schema rebuild.
- Chat UI performance lessons, applied to nanobot thread rendering.

## Runtime and Connection

Introduce a runtime host boundary:

```dart
abstract interface class NanobotRuntimeHost {
  Future<NanobotBootstrap> bootstrap({
    required Uri gatewayBaseUrl,
    String? secret,
  });

  Stream<NanobotRuntimeHostStatus> watchStatus();
}
```

First implementation:

- `ExternalGatewayRuntimeHost`
- Calls `GET /webui/bootstrap`.
- Sends `X-Nanobot-Auth` when a secret is configured.
- Does not start or stop a process.

Future implementation:

- `ManagedLocalRuntimeHost`
- Starts, restarts, and diagnoses a local nanobot process.
- Can reuse the same connection/session/thread controllers.

Connection controller states:

```text
unconfigured
authRequired
bootstrapLoading
connected
websocketConnecting
websocketOpen
reconnecting
offline
authFailed
tokenRefreshFailed
```

Token handling:

- Store the bootstrap secret only if the user opts into saving it.
- Keep short-lived API tokens in memory.
- Refresh before expiry using the same bootstrap path.
- Reconnect WebSocket after token refresh and re-attach known chat IDs.

## HTTP API Alignment

The HTTP layer should mirror `webui/src/lib/api.ts` from nanobot.

First-release required APIs:

- `GET /webui/bootstrap`
- `GET /api/sessions`
- `GET /api/sessions/:key/webui-thread?limit=&direction=latest&before=`
- `GET /api/workspaces`
- `GET /api/commands`
- `GET /api/settings` for basic model/runtime display

First-release optional or light APIs:

- `GET /api/webui/skills`
- `GET /api/sessions/:key/automations`
- `GET /api/webui/sidebar-state`

Later APIs:

- Full settings update endpoints.
- CLI apps endpoints.
- MCP preset endpoints.
- Automation action endpoints.
- File preview endpoints.
- Transcription settings and audio submission UI.

All authenticated HTTP requests use `Authorization: Bearer <token>`. If an API
returns WebUI HTML instead of JSON, surface a gateway mismatch error.

## WebSocket API Alignment

The WebSocket client should mirror `webui/src/lib/nanobot-client.ts`.

Outbound envelopes:

```text
new_chat
attach
fork_chat
message
set_workspace_scope
transcribe_audio
```

The first release must support:

- `new_chat`
- `attach`
- `message`
- `set_workspace_scope`

`fork_chat` can be implemented after the main flow works. `transcribe_audio`
can wait for voice input work.

Inbound events:

```text
ready
attached
message
file_edit
delta
stream_end
reasoning_delta
reasoning_end
runtime_model_updated
turn_end
goal_status
goal_state
session_updated
transcription_result
transcription_error
error
```

Unknown events must not crash the app. They should be ignored after structured
debug logging.

## Session Model

Domain model aligns with WebUI `ChatSummary`:

```text
NanobotSessionSummary
  key
  chatId
  channel
  title
  preview
  createdAt
  updatedAt
  runStartedAt
  workspaceScope
```

Rules:

- `key` is server-side session identity, for example `websocket:<chat_id>`.
- `chatId` is used for WebSocket envelopes.
- Creating a chat sends WebSocket `new_chat` and waits for `attached`.
- Opening a chat sends WebSocket `attach` and then loads
  `/api/sessions/:key/webui-thread`.
- Deleting a chat uses `/api/sessions/:key/delete`.
- `session_updated` refreshes the sidebar and, when relevant, thread metadata.

## Thread and Message Model

History should load from `/webui-thread`, not raw session messages. Nanobot
already builds the WebUI-compatible transcript there.

Flutter should model the returned UI message shape instead of reducing it to a
plain text chat message:

```text
NanobotThreadMessage
  id
  role
  content
  kind
  isStreaming
  createdAt
  traces
  toolEvents
  fileEdits
  activitySegmentId
  images
  media
  cliApps
  mcpPresets
  reasoning
  reasoningStreaming
  latencyMs
  source
  turnId
  turnPhase
  turnSeq
```

The live thread reducer applies WebSocket events using the same semantics as
`webui/src/hooks/useNanobotStream.ts`:

- `delta` appends answer text to the active assistant message.
- `stream_end` closes the current answer stream segment.
- `reasoning_delta` appends or creates reasoning content.
- `reasoning_end` closes reasoning streaming.
- `message` with `kind=tool_hint` or `kind=progress` becomes activity, not a
  normal assistant reply.
- `file_edit` updates activity rows.
- `turn_end` finalizes streaming and applies latency/goal state.
- `goal_status` updates run indicators.
- `goal_state` updates sustained goal state.

## Sending and Stopping

Message send flow:

```text
composer submit
  -> ensure chatId
  -> optimistic user message
  -> WebSocket type=message with chat_id/content/workspace_scope/webui=true/turn_id
  -> set thread streaming
  -> apply inbound events
  -> turn_end closes streaming
  -> session_updated refreshes sidebar metadata
```

Stop flow:

- Stop local streaming indicators immediately.
- Send WebSocket `message` with `content="/stop"` and `webui=true`.
- Rely on nanobot's WebUI behavior that `/stop` is a control message and is not
  persisted as a normal user bubble when it has no media.
- Refresh state when `turn_end` or `session_updated` arrives.

## Cache

Use Drift, but rebuild schema for nanobot.

Cache keys:

```text
gatewayBaseUrl + sessionKey
```

Tables:

- `nanobot_sessions_cache`
- `nanobot_thread_pages_cache`
- `nanobot_thread_messages_cache`
- `nanobot_sidebar_state_cache` if sidebar state is adopted

Cache rules:

- Cache is a startup accelerator, not the source of truth.
- Load cached latest page first for fast thread open.
- Then reconcile with `/webui-thread?limit=160&direction=latest`.
- Older messages load with `before_cursor`.
- Live WebSocket events update visible state immediately.
- After `turn_end` or relevant `session_updated`, reconcile with server
  transcript to avoid drift.
- Cache writes are scoped by gateway and session key.

Old cache data is not migrated.

## UI Alignment

Flutter UI is a native implementation of nanobot WebUI.

Primary shell:

```text
NanobotShellPage
  NanobotSidebar
  NanobotMainPane
    NanobotThreadShell
    NanobotSettingsView
    NanobotAppsView
    NanobotAutomationsView
    NanobotSkillsView
```

React to Flutter mapping:

```text
App.tsx                 -> NanobotShellPage
Sidebar                 -> NanobotSidebar
ThreadShell             -> NanobotThreadShell
ThreadHeader            -> NanobotThreadHeader
ThreadMessages          -> NanobotThreadMessages
MessageBubble           -> NanobotMessageBubble
AgentActivityCluster    -> NanobotActivityCluster
ThreadComposer          -> NanobotThreadComposer
SettingsView            -> NanobotSettingsView
```

First-release UI must include:

- Gateway login/connection screen.
- Sidebar with session list, new chat, selected session, preview, timestamp,
  and running state.
- Thread header with title, connection state, model display, and workspace
  summary.
- Thread messages for user messages, assistant messages, streaming deltas,
  reasoning, tool hints, progress, file edits, goal status, and media
  tiles where supported.
- Composer with text input, send, stop response, basic slash command display,
  and workspace scope attached to messages.
- Settings/apps/skills/automations entries in the same shell positions as
  WebUI.

Light first-release views:

- Settings: connection and runtime overview plus basic model display.
- Apps: shell entry and empty/light read-only state.
- Skills: list via `/api/webui/skills` if quick, otherwise empty/light
  read-only state.
- Automations: shell entry and empty/light read-only state.

Responsive behavior:

- Mobile: sidebar and thread are separate routes. Session list is the default
  entry, selecting a session opens thread.
- Tablet: sidebar and thread are side by side.
- Desktop: sidebar plus main view, matching WebUI layout hierarchy.

## Error Handling

Bootstrap:

- `401`: show authentication failure and re-prompt for secret.
- Connection refused or timeout: show gateway unavailable and mention
  `nanobot gateway`.
- Non-JSON response: show gateway mismatch or stale WebUI route error.

WebSocket:

- Close code `1009`: message too large.
- Reconnect with backoff.
- Re-bootstrap when token refresh is needed.
- Re-attach known chat IDs after reconnect.
- Preserve cached and visible thread state during reconnect.

Protocol errors:

- `workspace_scope_rejected`: show workspace access error.
- `image_rejected`: show media rejection reason.
- `invalid chat_id` or malformed envelope errors: show scoped send error.
- Unknown event: ignore safely.

## Testing Strategy

Protocol tests:

- Parse bootstrap payload.
- Parse session list.
- Parse `/webui-thread` messages.
- Parse all required WebSocket inbound events.
- Serialize outbound `new_chat`, `attach`, `message`, and
  `set_workspace_scope`.

Controller tests:

- Bootstrap success and auth failure.
- Token refresh.
- WebSocket ready and reconnect.
- New chat creates optimistic session after `attached`.
- Attach existing session.
- Send message reducer lifecycle.
- Stop sends `/stop`.
- `session_updated` refreshes sessions.

Thread reducer tests:

- `delta` and `stream_end`.
- `reasoning_delta` and `reasoning_end`.
- Tool hint and progress messages.
- File edits.
- `turn_end` with latency and goal state.
- Unknown event no-op.

Cache tests:

- Cache isolation by `gatewayBaseUrl + sessionKey`.
- Cache-first load followed by remote replacement.
- Older page append/prepend behavior.
- No old agent cache migration.

Widget tests:

- Mobile shell route behavior.
- Tablet and desktop shell layout selection.
- Sidebar session selection and running state.
- Thread composer send and stop controls.
- Plain text messages use lightweight rendering.
- Activity rows render without blocking message streaming.

Verification:

```sh
flutter analyze
flutter test
git diff --check
```

Use `flutter test --no-pub` only if Flutter platform cache issues block normal
test execution, and record that choice.

## Implementation Phases

Phase 1 - Remove old architecture and create nanobot shell foundation:

- Remove Agent Control and multi-agent features.
- Add nanobot config, runtime host, HTTP client, WebSocket client, and core
  domain models.
- Replace app entry with nanobot shell and connection screen.

Phase 2 - Sessions and thread:

- Implement session list, new chat, attach, and history loading.
- Implement cache-first latest thread load.
- Build sidebar and thread shell aligned with WebUI.

Phase 3 - Live streaming:

- Implement send message and stop.
- Implement thread reducer for required WebSocket events.
- Render reasoning, activity, file edits, and final assistant text.

Phase 4 - Workspace and commands:

- Fetch workspaces and commands.
- Attach workspace scope to new chats and messages.
- Show workspace/model/connection state in header/composer.

Phase 5 - Light secondary views:

- Add settings overview.
- Add apps, skills, and automations shell entries.
- Implement skills list if low-risk after core thread flow is stable.

Phase 6 - Cleanup and documentation:

- Remove obsolete tests and docs.
- Update README and AGENTS.md to nanobot-first constraints.
- Run full verification.

## Acceptance Criteria

- Fresh app launch can connect to a running nanobot gateway.
- Auth via `/webui/bootstrap` works with WebUI secret.
- Session list matches nanobot WebUI sessions.
- Creating a chat uses WebSocket `new_chat`.
- Opening a chat loads `/webui-thread`.
- Sending a message streams the same event semantics as WebUI.
- Stop response uses `/stop`.
- Reasoning, progress/tool hints, file edits, and final responses render in
  thread order.
- UI shell aligns with nanobot WebUI information architecture.
- No old Agent Control or multi-agent entry points remain.
- No compatibility path for old cache or old backend ports remains.
- `flutter analyze`, `flutter test`, and `git diff --check` pass before
  implementation is considered complete.
