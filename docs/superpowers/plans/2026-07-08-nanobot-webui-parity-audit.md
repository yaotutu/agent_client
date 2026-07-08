# Nanobot WebUI Parity Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce the Phase 1 parity audit for making Flutter a nanobot-only WebUI parity client.

**Architecture:** This phase is documentation and evidence gathering only. It inspects nanobot WebUI source, inspects current Flutter nanobot code, then writes a parity map with implementation status, gaps, and verification requirements that subsequent implementation plans can consume.

**Tech Stack:** Shell, ripgrep, Git, Markdown, Flutter project source, nanobot WebUI TypeScript/React source.

---

## Scope

This plan implements Phase 1 from
`docs/superpowers/specs/2026-07-08-nanobot-webui-parity-design.md`.

No Flutter product code changes are allowed in this phase. The only expected
new artifact is:

```text
docs/superpowers/audits/2026-07-08-nanobot-webui-parity-map.md
```

The current unrelated local deletion of `.codex/config.toml` must remain
untouched.

## Task 1: Create Audit Directory and Skeleton

**Files:**
- Create: `docs/superpowers/audits/2026-07-08-nanobot-webui-parity-map.md`

- [ ] **Step 1: Create the audit skeleton**

Create the file with these sections:

```markdown
# Nanobot WebUI Parity Map

## Source Snapshot

## Current Flutter Snapshot

## Status Legend

## Shell and Navigation

## Sidebar and Sessions

## Thread and Message Rendering

## Composer and Input Flows

## Live Stream and Activity State

## File, Media, and Preview Surfaces

## Settings and Secondary Surfaces

## HTTP API Coverage

## WebSocket Coverage

## Responsive and Interaction Coverage

## True-Device Verification Matrix

## Phase 2 Recommendations
```

- [ ] **Step 2: Record the source snapshot**

Run:

```sh
git -C /home/yaotutu/Desktop/code/nanobot log -1 --format='%h %ci %s'
git -C /home/yaotutu/Desktop/code/agent_client log -1 --format='%h %ci %s'
git -C /home/yaotutu/Desktop/code/agent_client status --short
```

Add the results under `Source Snapshot` and `Current Flutter Snapshot`.

Expected: `agent_client` may still show `D .codex/config.toml`; document it as
unrelated local state.

## Task 2: Audit WebUI Product Surface

**Files:**
- Modify: `docs/superpowers/audits/2026-07-08-nanobot-webui-parity-map.md`

- [ ] **Step 1: List WebUI source files**

Run:

```sh
find /home/yaotutu/Desktop/code/nanobot/webui/src -maxdepth 4 -type f \
  \( -name '*.tsx' -o -name '*.ts' -o -name '*.json' \) | sort
```

Use this to identify all product areas: app shell, sidebar, chat list, thread,
composer, settings, apps, automations, skills, MCP, media, activity, i18n, and
hooks.

- [ ] **Step 2: Extract shell views and settings sections**

Run:

```sh
rg -n "type ShellView|SETTINGS_SECTION_KEYS|export type SettingsSectionKey" \
  /home/yaotutu/Desktop/code/nanobot/webui/src/App.tsx \
  /home/yaotutu/Desktop/code/nanobot/webui/src/components/settings/SettingsView.tsx
```

Record shell views and settings section keys in the map.

- [ ] **Step 3: Extract major component surfaces**

Run:

```sh
find /home/yaotutu/Desktop/code/nanobot/webui/src/components -maxdepth 3 \
  -type f \( -name '*.tsx' -o -name '*.ts' \) | sort
```

Group components under the parity map sections. Include both top-level
components and thread/activity/settings subcomponents.

- [ ] **Step 4: Extract local preference and sidebar state behavior**

Run:

```sh
rg -n "localStorage|sessionStorage|SIDEBAR|sidebarState|title_overrides|project_name_overrides|pinned_keys|archived_keys|queuedPrompts|readQueuedPrompts|storeQueuedPrompts" \
  /home/yaotutu/Desktop/code/nanobot/webui/src/App.tsx \
  /home/yaotutu/Desktop/code/nanobot/webui/src/hooks \
  /home/yaotutu/Desktop/code/nanobot/webui/src/components
```

Record WebUI local and server-persisted state that Flutter must reproduce.

## Task 3: Audit WebUI HTTP and WebSocket Protocol

**Files:**
- Modify: `docs/superpowers/audits/2026-07-08-nanobot-webui-parity-map.md`

- [ ] **Step 1: Extract HTTP API methods**

Run:

```sh
rg -n "^export async function|^export class ApiError|const API_READ_TIMEOUT_MS|request<" \
  /home/yaotutu/Desktop/code/nanobot/webui/src/lib/api.ts
```

For each exported API function, record:

- WebUI function name.
- Endpoint path.
- Request details.
- Flutter coverage status.
- Notes for parity.

- [ ] **Step 2: Extract WebSocket outbound and inbound types**

Run:

```sh
sed -n '824,1040p' /home/yaotutu/Desktop/code/nanobot/webui/src/lib/types.ts
rg -n "export class NanobotClient|type: \"|parsed.event ===|recordGoal|pendingNewChat|pendingTranscriptions|message_too_big|workspace_scope_rejected" \
  /home/yaotutu/Desktop/code/nanobot/webui/src/lib/nanobot-client.ts
```

Record every outbound frame, inbound event, and special client behavior.

- [ ] **Step 3: Extract stream reducer behavior**

Run:

```sh
rg -n "ev.event ===|event: \"|tool_events|file_edit|reasoning|goal_status|turn_end|stream_end|merge|stale|pending" \
  /home/yaotutu/Desktop/code/nanobot/webui/src/hooks/useNanobotStream.ts \
  /home/yaotutu/Desktop/code/nanobot/webui/src/components/thread/ThreadShell.tsx
```

Record reducer behavior that Flutter must match before UI rendering can be
considered complete.

## Task 4: Audit Current Flutter Coverage

**Files:**
- Modify: `docs/superpowers/audits/2026-07-08-nanobot-webui-parity-map.md`

- [ ] **Step 1: List current Flutter nanobot files**

Run:

```sh
find /home/yaotutu/Desktop/code/agent_client/lib/app \
     /home/yaotutu/Desktop/code/agent_client/lib/core \
     /home/yaotutu/Desktop/code/agent_client/lib/features/nanobot \
     -maxdepth 5 -type f | sort
```

Record current Flutter structure and compare it with the architecture target in
the spec.

- [ ] **Step 2: Extract Flutter HTTP and WebSocket coverage**

Run:

```sh
rg -n "class .*Api|Future<|Uri|/api/|/webui/bootstrap|WebSocket|new_chat|attach|message|goal_status|reasoning_delta|file_edit|stream_end|turn_end|session_updated|runtime_model_updated|transcription" \
  /home/yaotutu/Desktop/code/agent_client/lib/features/nanobot \
  /home/yaotutu/Desktop/code/agent_client/lib/core
```

Mark each protocol item as implemented, partial, missing, or unverified.

- [ ] **Step 3: Extract Flutter UI coverage**

Run:

```sh
rg -n "class .*Widget|ConsumerWidget|Scaffold|Navigation|Drawer|ListView|TextField|IconButton|Dropdown|Dialog|Sheet|Markdown|Image|File|Settings|Automation|Skill|Mcp|Workspace" \
  /home/yaotutu/Desktop/code/agent_client/lib/app \
  /home/yaotutu/Desktop/code/agent_client/lib/features/nanobot
```

Mark each WebUI product surface as implemented, partial, missing, or
unverified.

- [ ] **Step 4: Extract current tests**

Run:

```sh
find /home/yaotutu/Desktop/code/agent_client/test -type f | sort
rg -n "nanobot|workspace|config|adaptive|manifest|WebSocket|session|message|goal_status|reasoning|settings|automation|skill" \
  /home/yaotutu/Desktop/code/agent_client/test
```

Record what current tests cover and what remains untested.

## Task 5: Write Gap List and Phase 2 Recommendations

**Files:**
- Modify: `docs/superpowers/audits/2026-07-08-nanobot-webui-parity-map.md`

- [ ] **Step 1: Fill every parity section with status tables**

Use this table shape in each section:

```markdown
| WebUI item | WebUI source | Flutter source | Status | Gap / next action |
| --- | --- | --- | --- | --- |
```

Statuses:

- `Implemented`: covered in Flutter source and already verified.
- `Partial`: some Flutter support exists, but WebUI behavior is incomplete.
- `Missing`: no meaningful Flutter implementation exists.
- `Unverified`: likely implemented, but no current evidence proves it.
- `Blocked`: cannot be implemented or verified without a missing capability.

- [ ] **Step 2: Write a true-device verification matrix**

Include at least these rows:

- Fresh install or cleared app launch.
- Bootstrap/auth.
- Session list.
- New chat.
- Existing chat attach.
- Streaming reply.
- Reasoning/activity reply.
- File edit/tool trace.
- Sidebar search/pin/archive/title override.
- File/media preview.
- Settings overview.
- Models/provider section.
- Apps section.
- Automations section.
- Skills section.
- MCP section.
- Workspace scope rejection.
- Reconnect/token refresh.
- Phone portrait.
- Phone landscape.

- [ ] **Step 3: Recommend Phase 2 task order**

Write a short ordered list that starts with protocol/state foundation and
continues through core chat parity before settings surfaces.

## Task 6: Validate and Commit Audit Artifacts

**Files:**
- Commit: `docs/superpowers/plans/2026-07-08-nanobot-webui-parity-audit.md`
- Commit: `docs/superpowers/audits/2026-07-08-nanobot-webui-parity-map.md`

- [ ] **Step 1: Run whitespace check**

Run:

```sh
git diff --check -- docs/superpowers/plans/2026-07-08-nanobot-webui-parity-audit.md docs/superpowers/audits/2026-07-08-nanobot-webui-parity-map.md
```

Expected: no output.

- [ ] **Step 2: Review for unresolved markers**

Run:

```sh
rg -n "T[B]D|T[O]DO|fill[ ]in|placeholde[r]|late[r]|mayb[e]" \
  docs/superpowers/plans/2026-07-08-nanobot-webui-parity-audit.md \
  docs/superpowers/audits/2026-07-08-nanobot-webui-parity-map.md
```

Expected: no unresolved marker output.

- [ ] **Step 3: Commit the Phase 1 audit artifacts**

Run:

```sh
git add docs/superpowers/plans/2026-07-08-nanobot-webui-parity-audit.md docs/superpowers/audits/2026-07-08-nanobot-webui-parity-map.md
git commit -m "docs: audit nanobot webui parity surface"
```

Expected: commit includes only the plan and audit map. It must not include
`.codex/config.toml`.
