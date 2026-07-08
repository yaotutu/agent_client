# Nanobot Protocol State Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the protocol and state foundation required for Flutter to match nanobot WebUI behavior.

**Architecture:** Start with protocol fidelity before UI. Add typed WebUI-compatible HTTP and WebSocket protocol models under `features/nanobot/data/protocol`, preserve all fields needed by reducers and widgets, then wire current clients/controllers to those models in small slices.

**Tech Stack:** Flutter, Dart, hooks_riverpod, Dio, `dart:io` WebSocket, `flutter_test`.

---

## Scope

This plan follows the Phase 1 audit:

```text
docs/superpowers/audits/2026-07-08-nanobot-webui-parity-map.md
```

The first implementation slice covers WebSocket envelope fidelity. It does not
attempt to complete all UI parity in one change.

## Task 1: WebSocket Envelope Fidelity

**Files:**
- Create: `lib/features/nanobot/data/protocol/nanobot_ws_envelope.dart`
- Modify: `lib/features/nanobot/domain/nanobot_event.dart`
- Test: `test/nanobot_ws_envelope_test.dart`
- Test: `test/nanobot_domain_test.dart`

- [ ] **Step 1: Write WebSocket envelope tests**

Create `test/nanobot_ws_envelope_test.dart` with tests for:

- Rich `message` frames preserving media URLs, tool events, source, latency,
  and turn metadata.
- `file_edit` frames preserving edit rows.
- `goal_state` and `turn_end` frames preserving goal state.
- `transcription_result` and `transcription_error` frames.
- Outbound `message` serialization with media, image generation, CLI apps, MCP
  presets, workspace scope, turn ID, and `webui: true`.
- Outbound `fork_chat`, `set_workspace_scope`, and `transcribe_audio`
  serialization.

- [ ] **Step 2: Run the failing test**

Run:

```sh
.fvm/flutter_sdk/bin/flutter test --no-pub test/nanobot_ws_envelope_test.dart
```

Expected: fail because `nanobot_ws_envelope.dart` does not exist.

- [ ] **Step 3: Implement `nanobot_ws_envelope.dart`**

Create a typed parser and serializer:

- `NanobotInboundEnvelope`
- `NanobotInboundEventType`
- `NanobotOutboundEnvelope`
- `NanobotOutboundMedia`
- `NanobotOutboundImageGeneration`
- `NanobotOutboundMention`

The parser must retain unknown structured maps and lists as `Object?` values
instead of dropping them.

- [ ] **Step 4: Wire `NanobotEvent` to use the envelope parser**

Keep the existing `NanobotEvent` public fields working, then add fields needed
for future reducers:

- `streamId`
- `clientId`
- `requestId`
- `provider`
- `modelPreset`
- `latencyMs`
- `goalState`
- `mediaUrls`
- `toolEvents`
- `fileEdits`
- `source`
- `agentUi`
- `turnId`
- `turnPhase`
- `turnSeq`

- [ ] **Step 5: Run targeted tests**

Run:

```sh
.fvm/flutter_sdk/bin/flutter test --no-pub test/nanobot_ws_envelope_test.dart test/nanobot_domain_test.dart
```

Expected: pass.

- [ ] **Step 6: Run regression checks**

Run:

```sh
.fvm/flutter_sdk/bin/flutter analyze --no-pub
.fvm/flutter_sdk/bin/flutter test --no-pub
git diff --check
```

Expected: all pass.

- [ ] **Step 7: Commit**

Run:

```sh
git add docs/superpowers/plans/2026-07-08-nanobot-protocol-state-foundation.md \
  lib/features/nanobot/data/protocol/nanobot_ws_envelope.dart \
  lib/features/nanobot/domain/nanobot_event.dart \
  test/nanobot_ws_envelope_test.dart \
  test/nanobot_domain_test.dart
git commit -m "feat: preserve nanobot websocket envelopes"
```

Expected: commit excludes `.codex/config.toml`.

## Task 2: WebSocket Client Behavior Parity

**Files:**
- Modify: `lib/features/nanobot/data/nanobot_ws_client.dart`
- Modify: `lib/features/nanobot/data/nanobot_repository.dart`
- Test: `test/nanobot_ws_client_test.dart`

- [ ] **Step 1: Add tests for outbound frame serialization**

Test that the client sends typed outbound envelopes for `new_chat`, `attach`,
`message`, `fork_chat`, `set_workspace_scope`, and `transcribe_audio`.

- [ ] **Step 2: Add tests for connection lifecycle**

Test status transitions, pending `new_chat` completion, pending fork completion,
pending transcription completion, known chat reattach, and close-code `1009`
mapping.

- [ ] **Step 3: Implement client changes**

Use `NanobotOutboundEnvelope` for all outbound frames, parse inbound frames into
`NanobotInboundEnvelope`, then expose `NanobotEvent` to current callers until
controllers are refactored.

- [ ] **Step 4: Verify**

Run targeted tests, full Flutter tests, analyze, and whitespace check.

## Task 3: Thread Reducer Foundation

**Files:**
- Create: `lib/features/nanobot/domain/nanobot_thread_state.dart`
- Create: `lib/features/nanobot/application/nanobot_thread_reducer.dart`
- Test: `test/nanobot_thread_reducer_test.dart`

- [ ] **Step 1: Add reducer tests mirroring WebUI stream behavior**

Cover `delta`, `stream_end`, `reasoning_delta`, `reasoning_end`, `message`
tool hints, `file_edit`, `turn_end`, `goal_status`, and `goal_state`.

- [ ] **Step 2: Implement reducer**

Preserve activity segments, trace rows, file edits, latency, source metadata,
and run/goal state.

- [ ] **Step 3: Verify**

Run targeted tests, full Flutter tests, analyze, and whitespace check.

## Task 4: HTTP DTO Foundation

**Files:**
- Create: `lib/features/nanobot/data/protocol/nanobot_http_dto.dart`
- Modify: `lib/features/nanobot/data/nanobot_api_client.dart`
- Test: `test/nanobot_http_dto_test.dart`

- [ ] **Step 1: Add HTTP DTO tests**

Cover sessions, webui-thread page metadata, file preview, settings shell
payload, sidebar state, workspaces, slash commands, skills, automations, apps,
MCP presets, provider models, and settings update result parsing.

- [ ] **Step 2: Implement DTOs and API methods**

Mirror `webui/src/lib/api.ts` paths and payload behavior.

- [ ] **Step 3: Verify**

Run targeted tests, full Flutter tests, analyze, and whitespace check.
