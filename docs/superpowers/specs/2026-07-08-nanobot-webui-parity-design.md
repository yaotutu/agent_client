# Nanobot WebUI Parity Client

## Status

Approved direction for implementation planning.

This spec supersedes the narrower
`docs/superpowers/specs/2026-06-28-nanobot-first-redesign-design.md` scope.
The previous redesign established a minimal nanobot-only client. This spec
defines the next goal: Flutter must become an equivalent native implementation
of nanobot WebUI.

## Source of Truth

The only product and protocol reference is the nanobot WebUI source at:

```text
/home/yaotutu/Desktop/code/nanobot/webui/src
```

The Flutter project is:

```text
/home/yaotutu/Desktop/code/agent_client
```

The live gateway used for integration and device verification is:

```text
http://192.168.200.149:8765/
```

Authentication uses the WebUI bootstrap secret provided by the user in the
conversation. The secret must not be written into source, committed docs,
fixtures, logs, screenshots, or shell scripts.

## Goal

Build the Flutter app as a nanobot-only WebUI parity client. Functionality,
layout hierarchy, controls, action flows, HTTP APIs, WebSocket APIs, error
states, real-time updates, responsive behavior, and interaction logic must map
to nanobot WebUI with equivalent native Flutter implementations.

This is not a new UI design exercise. Flutter should reproduce nanobot WebUI's
information architecture and behavior, adapting implementation details only
where required by Flutter and Android.

## Non-Goals

- Reintroducing Agent Control, multi-backend routing, generic agent registry
  concepts, or old `agentId + sessionId` state models.
- Designing a different product experience.
- Treating unit tests as the primary acceptance gate.
- Starting, stopping, or managing the nanobot process from Flutter unless the
  WebUI parity surface already requires a host action and the gateway exposes
  it.
- Pixel-perfect CSS reproduction when native Flutter widgets need different
  internals. The required match is page structure, control presence, state,
  action flow, and visible behavior.

## Current Baseline

The current Flutter app already contains a nanobot-only minimal client:

- App entry: `lib/app/nanobot_client_app.dart`
- Config: `lib/core/config/app_config*.dart`
- Nanobot data/domain/application/presentation under `lib/features/nanobot/`
- Default gateway: `http://192.168.200.149:8765`
- Minimal bootstrap, session listing, WebSocket attach/new chat/message, and
  streaming response support.

The baseline is intentionally incomplete for WebUI parity. It lacks full
settings/apps/automations/skills/MCP surfaces, complete WebUI composer
behavior, rich activity rendering, complete REST API coverage, and full
responsive shell parity.

## Hard Decisions

1. Nanobot WebUI is the product contract.
2. Flutter remains nanobot-only. Old backend abstractions are not preserved.
3. Session identity follows WebUI: `sessionKey` such as `websocket:<chat_id>`
   plus `chatId`.
4. Protocol DTOs stay in data/protocol boundaries. UI and controllers consume
   typed Flutter domain/application models, not raw maps.
5. Real-device behavior has priority over local test assumptions.
6. Every implementation stage must be verifiable against the real gateway on an
   Android device.
7. Staged delivery is allowed, but each stage must move toward full parity and
   must not create throwaway UI paths.

## WebUI Parity Surface

### Shell and Navigation

Flutter must implement WebUI's shell views:

- Chat view.
- Settings view.
- Apps view.
- Automations view.
- Skills view.

It must mirror WebUI route/state behavior in native form:

- Active chat selection.
- New chat state.
- Settings section selection.
- Preserve active chat when entering secondary views where WebUI does so.
- Sidebar open/collapsed behavior adapted to mobile and tablet.
- Connection, model, runtime, and session status indicators.

### Sidebar and Sessions

Flutter must match WebUI session flows:

- Load sessions from `/api/sessions`.
- Show title, preview, updated time, workspace scope, and running state.
- Create new chat through WebSocket `new_chat`.
- Attach to existing chats through WebSocket `attach`.
- Search sessions.
- Rename chat through sidebar `title_overrides`.
- Rename project groups through sidebar `project_name_overrides`.
- Pin and unpin chats through sidebar `pinned_keys`.
- Archive and unarchive chats through sidebar `archived_keys` and
  `view.show_archived`.
- Delete chat through the WebUI delete API and handle deletion blocked by
  automations.
- Refresh session list on `session_updated`.
- Preserve optimistic local sessions until the gateway catches up.
- Persist sidebar density, sorting, title overrides, project name overrides,
  pinned keys, archived keys, and archived visibility through
  `/api/webui/sidebar-state` and `/api/webui/sidebar-state/update`.

### Thread and Message Rendering

Flutter must reproduce WebUI thread behavior:

- Load persisted WebUI thread pages through
  `/api/sessions/:key/webui-thread`.
- Use bottom-anchored, performance-aware rendering.
- Render user, assistant, tool/trace, and system roles.
- Render Markdown, code blocks, links, inline code, lists, and copy actions
  with native Flutter equivalents.
- Render images, media attachments, CLI app mentions, MCP preset mentions, and
  unavailable media placeholders.
- Merge live stream events with persisted history without replacing newer
  local/live messages with stale snapshots.
- Support older-page loading through the `before` cursor when present.
- Render proactive automation source metadata.
- Fork assistant replies through WebSocket `fork_chat` using the same global
  user message index semantics as WebUI.

### Composer and Input Flows

Flutter must match WebUI composer behavior:

- Text input with send button and keyboard behavior appropriate for Android.
- Disable or change controls while a turn is running.
- Slash command listing from `/api/commands`, including lifecycle handling:
  side-channel commands, active-turn finalization, stop-active-turn, agent turn,
  and agent-turn-with-args.
- Attach images/media using WebUI's outbound `media` payload shape.
- Image preview, remove, and size/error handling.
- Queued prompts for running sessions using the same local queued-prompt
  behavior as WebUI composer.
- CLI app mention palette from installed apps.
- MCP preset mention palette.
- Workspace scope controls and rejection handling.
- Voice/transcription controls when the WebUI API and device permission path
  are implemented.

### Live Stream and Activity State

Flutter must match `webui/src/hooks/useNanobotStream.ts` behavior:

- `delta`
- `reasoning_delta`
- `reasoning_end`
- `stream_end`
- `message`
- `file_edit`
- `turn_end`
- `goal_status`
- `goal_state`
- `session_updated`
- `runtime_model_updated`
- `error`

The UI must render equivalent state for:

- Streaming answer text.
- Reasoning rows and reasoning completion.
- Tool hint and structured tool progress events.
- File edit rows with added/deleted counts and error states.
- Activity clusters grouped by turn phase/segment.
- Runtime running strip and elapsed time.
- Goal summary/objective panel.
- Workspace-scope rejection.
- Message-too-large WebSocket close handling.
- Reconnect and token refresh state.

### File, Media, and Preview Surfaces

Flutter must implement WebUI-equivalent surfaces for:

- File reference chips.
- File preview panel through `/api/sessions/:key/file-preview`.
- Image lightbox or native full-screen image preview.
- Attachment tiles.
- Code diff/file edit previews where activity rows expose file edits.

### Settings and Secondary Surfaces

Flutter must reproduce the WebUI settings information architecture and action
flows. The section list follows WebUI's `SettingsSectionKey` values:

- Overview.
- Appearance.
- Models.
- Image.
- Voice.
- Browser.
- Apps.
- Automations.
- Skills.
- Runtime.
- Advanced.

The settings implementation must cover the WebUI REST APIs used by
`webui/src/lib/api.ts`:

- `GET /api/settings`
- `GET /api/settings/usage`
- `GET /api/settings/version-check`
- `GET /api/workspaces`
- `GET /api/settings/cli-apps`
- `GET /api/settings/cli-apps?installed_only=1`
- `GET /api/settings/nanobot-features`
- `/api/settings/nanobot-features/enable?name=...`
- `/api/settings/nanobot-features/disable?name=...`
- `/api/settings/cli-apps/install?name=...`
- `/api/settings/cli-apps/update?name=...`
- `/api/settings/cli-apps/uninstall?name=...`
- `/api/settings/cli-apps/test?name=...`
- `GET /api/webui/skills`
- `GET /api/webui/skills/:name`
- `GET /api/webui/automations`
- `/api/webui/automations/enable?id=...`
- `/api/webui/automations/disable?id=...`
- `/api/webui/automations/delete?id=...`
- `/api/webui/automations/run?id=...`
- `/api/webui/automations/update?id=...`
- `GET /api/settings/mcp-presets`
- `/api/settings/mcp-presets/enable?name=...`
- `/api/settings/mcp-presets/remove?name=...`
- `/api/settings/mcp-presets/test?name=...`
- `/api/settings/mcp-presets/custom`
- `/api/settings/mcp-presets/import`
- `/api/settings/mcp-presets/tools`
- `GET /api/settings/provider-models?provider=...`
- `/api/settings/update?...`
- `/api/settings/model-configurations/create?...`
- `/api/settings/model-configurations/update?...`
- `/api/settings/provider/update?...`
- `/api/settings/provider/oauth-login?provider=...`
- `/api/settings/provider/oauth-logout?provider=...`
- `/api/settings/web-search/update?...`
- `/api/settings/network-safety/update?...`
- `/api/settings/image-generation/update?...`
- `/api/settings/transcription/update?...`
- `GET /api/webui/sidebar-state`
- `/api/webui/sidebar-state/update?state=...`

When an endpoint is unavailable or blocked by runtime capabilities, Flutter
must surface the same disabled/error state WebUI would show.

### HTTP Protocol

The Flutter HTTP layer must mirror `webui/src/lib/api.ts`.

Required behavior:

- Bootstrap via `GET /webui/bootstrap`.
- Send bootstrap secret as `X-Nanobot-Auth` only for bootstrap.
- Send `Authorization: Bearer <token>` for authenticated WebUI APIs.
- Apply request timeouts matching WebUI expectations where relevant.
- Treat HTML returned from JSON endpoints as a gateway mismatch error.
- Parse all documented payloads into typed DTO/domain models.
- Preserve unknown compatible fields where later rendering may need them.
- Produce user-visible errors with enough context to diagnose gateway/auth/API
  failures.

### WebSocket Protocol

The Flutter WebSocket layer must mirror `webui/src/lib/nanobot-client.ts`.

Outbound frames:

- `new_chat`
- `attach`
- `fork_chat`
- `message`
- `set_workspace_scope`
- `transcribe_audio`

Inbound events:

- `ready`
- `attached`
- `message`
- `delta`
- `reasoning_delta`
- `reasoning_end`
- `stream_end`
- `turn_end`
- `goal_status`
- `goal_state`
- `file_edit`
- `transcription_result`
- `transcription_error`
- `session_updated`
- `runtime_model_updated`
- `error`

Required client behavior:

- One multiplexed socket fans out events by `chat_id`.
- Reconnects refresh auth when needed and reattach known chats.
- Pending inbound events are buffered long enough to survive route switches.
- Pending `new_chat` and `transcribe_audio` requests resolve or fail
  predictably.
- Socket close code `1009` maps to message-too-large UI state.
- Workspace scope rejection becomes an immediate visible error.

## Responsive and Interaction Requirements

The adaptive policy remains mobile-first:

- Phone widths use a mobile shell.
- Tablet widths use a tablet shell.
- Desktop widths route to a desktop entry that can degrade to tablet until
  desktop-specific WebUI parity is implemented.

Presentation code must not scatter raw breakpoint checks. Whole-shell
decisions use `lib/app/adaptive/adaptive_layout_policy.dart`. Local sizing
within a selected layout may use local constraints.

Android true-device ergonomics are required:

- Controls fit on narrow screens.
- Text does not overflow buttons, chips, cards, or headers.
- Composer remains usable with the soft keyboard open.
- Side panels and sheets are reachable by touch.
- Long lists remain performant.
- Rotation does not lose the active chat or input state.

## Architecture Target

The Flutter feature should evolve toward this shape:

```text
lib/features/nanobot/
  data/
    protocol/
      nanobot_http_dto.dart
      nanobot_ws_envelope.dart
    nanobot_api_client.dart
    nanobot_ws_client.dart
    nanobot_repository.dart
  domain/
    nanobot_bootstrap.dart
    nanobot_config.dart
    nanobot_event.dart
    nanobot_message.dart
    nanobot_session.dart
    nanobot_settings.dart
    nanobot_workspace.dart
  application/
    nanobot_connection_controller.dart
    nanobot_sessions_controller.dart
    nanobot_thread_controller.dart
    nanobot_settings_controller.dart
    nanobot_workspace_controller.dart
  presentation/
    shell/
    sidebar/
    thread/
    settings/
    apps/
    automations/
    skills/
    shared/
```

The exact file list can change during implementation. The boundary cannot:

- Protocol parsing and serialization belong in data/protocol or data clients.
- Domain models describe nanobot concepts in Flutter terms.
- Controllers own state transitions, stream reducers, loading, and mutation
  flows.
- Widgets render typed state and send typed actions.

## Implementation Phases

### Phase 1: Parity Audit

Produce a checked parity map under `docs/superpowers/` that lists:

- WebUI pages and views.
- WebUI components and controls.
- HTTP endpoints and payloads used by WebUI.
- WebSocket outbound and inbound frames.
- Local preferences/storage behavior.
- Error states.
- Responsive shell behavior.
- Current Flutter support status.

This phase has no product-code changes except small probes if needed.

### Phase 2: Protocol and State Parity Foundation

Refactor Flutter's nanobot data/application layers so protocol coverage is
complete and typed:

- HTTP DTOs and API methods.
- WebSocket envelopes and reconnection behavior.
- Thread reducer matching WebUI stream behavior.
- Session reducer matching WebUI sidebar behavior.
- Settings/app/automation/skills state controllers.

Each controller must have targeted unit tests, but the stage is accepted only
after real gateway smoke tests pass.

### Phase 3: Core Chat Parity

Implement WebUI-equivalent chat shell:

- Sidebar/session flows.
- Thread header and messages.
- Composer, slash commands, attachments, mention palettes.
- Reasoning, activity, file edits, runtime strip, error notices.
- File/media preview surfaces.

Acceptance requires Android true-device screenshots or UI dumps for core flows.

### Phase 4: Settings and Management Surface Parity

Implement settings, apps, automations, skills, MCP, model/provider, browser,
image, voice, runtime, and advanced sections with equivalent action flows.

Acceptance requires real gateway reads and at least non-destructive actions for
each section. Destructive actions require explicit user approval before running
against the shared gateway.

### Phase 5: Responsive, Polish, and Regression Pass

Complete mobile/tablet/desktop-entry behavior:

- Phone portrait and landscape.
- Tablet-width emulator or physical device when available.
- Desktop route fallback behavior.
- Overflow and keyboard checks.
- Long history performance checks.
- Reconnect and offline/error checks.

## Acceptance Strategy

The primary acceptance source is real Android device behavior against:

```text
http://192.168.200.149:8765/
```

Each implementation phase must record:

- Device ID and Android version.
- Flutter run command.
- Gateway base URL.
- Screenshots or UI dumps for changed surfaces.
- Relevant `adb logcat` or Flutter logs for API/WS behavior.
- Manual action list performed.
- Pass/fail notes.

Automated checks are still required before commits:

```sh
.fvm/flutter_sdk/bin/flutter analyze --no-pub
.fvm/flutter_sdk/bin/flutter test --no-pub
git diff --check
```

These checks protect regressions but do not replace true-device verification.

## Safety Rules

- Do not commit the WebUI secret.
- Do not run destructive gateway actions, such as deleting sessions,
  uninstalling apps, deleting automations, or changing provider credentials,
  unless the user explicitly approves that exact action.
- Do not revert unrelated local changes. The current unrelated deletion of
  `.codex/config.toml` remains outside this goal.
- Keep commits focused by phase or task.
- When WebUI behavior is unclear, inspect nanobot WebUI source first, then
  verify against the real gateway.

## Completion Definition

The goal is complete when:

- The parity map shows every WebUI page/control/API/state as implemented,
  intentionally unsupported with a documented runtime reason, or blocked by a
  gateway capability unavailable on the target device.
- Flutter passes analyze, tests, and whitespace checks.
- Android true-device verification covers the full WebUI parity surface.
- The app can be cleared, launched, authenticated, used across chat/settings
  flows, rotated, reconnected, and used for live streaming without relying on
  legacy Agent Control code.
