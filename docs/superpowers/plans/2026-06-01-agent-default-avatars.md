# Agent Default Avatars Implementation Plan

> Superseded note: this historical plan predates the current
> `mobile/`, `tablet/`, `desktop/`, and `shared/` presentation layout. Use
> `docs/superpowers/specs/2026-06-02-mobile-first-adaptive-ui-strategy.md` and
> `AGENTS.md` for current file locations.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add generated default avatar assets and let users choose one when creating an agent.

**Architecture:** Keep backend protocol handling unchanged. Store the selected avatar as client-local agent metadata, merge it into `Agent.avatarUrl` when listing agents, and render avatars through one reusable widget with a text fallback.

**Tech Stack:** Flutter, Dart, Riverpod, Drift, generated PNG assets.

---

### Task 1: Add Avatar Selection Behavior Tests

**Files:**
- Modify: `test/agent_controller_test.dart`
- Modify: `test/agent_shell_test.dart`

- [ ] Add a controller test that creates an agent with `avatarUrl: AgentAvatarOptions.defaults.first.assetPath`, then verifies the refreshed `agentsProvider` entry keeps that `avatarUrl`.
- [ ] Add a widget test that opens the create-agent dialog, taps an avatar option, creates the agent, and verifies the fake API still receives only the agent name and description while the UI exposes an avatar image.
- [ ] Run the focused tests and confirm they fail because `createAgent` has no avatar parameter and the dialog has no avatar selector.

### Task 2: Add Default Avatar Catalog and Assets

**Files:**
- Create: `lib/features/agents/domain/agent_avatar.dart`
- Create: `assets/agent_avatars/*.png`
- Modify: `pubspec.yaml`

- [ ] Generate six square PNG avatars for agent roles: coder, reviewer, researcher, planner, operator, designer.
- [ ] Register `assets/agent_avatars/` under Flutter assets.
- [ ] Add `AgentAvatarOption` and `AgentAvatarOptions.defaults` so UI and tests use stable ids and paths.

### Task 3: Persist Local Avatar Metadata

**Files:**
- Create: `lib/features/agents/data/agent_avatar_store.dart`
- Modify: `lib/features/agents/data/agent_registry_repository.dart`
- Modify: `lib/features/agents/application/agent_controller.dart`

- [ ] Add a Drift-backed avatar store using the existing `cachedAgents.avatarUrl` column.
- [ ] Wrap the backend repository so `listAgents()` merges local avatar paths into domain `Agent` objects.
- [ ] Extend `createAgent` to accept an optional `avatarUrl`, save it locally after backend creation, and return/select the created agent.
- [ ] Delete local avatar metadata when an agent is deleted.

### Task 4: Render and Pick Avatars

**Files:**
- Create: `lib/features/agents/presentation/agent_avatar_view.dart`
- Modify: `lib/features/agents/presentation/agent_navigation_panel.dart`
- Modify: `lib/features/agents/presentation/agent_side_rail.dart`
- Modify: `lib/features/agents/presentation/agent_workspace_conversation_list.dart`
- Modify: `lib/features/agents/presentation/agent_workspace_detail.dart`

- [ ] Add a shared `AgentAvatarView` that renders `Image.asset` for project asset avatar paths and falls back to the current initial-based `CircleAvatar`.
- [ ] Add a compact avatar picker to the create-agent dialog with deterministic keys for tests.
- [ ] Replace duplicated agent `CircleAvatar` rendering in the agent list, compact rail, conversation list, and chat header.

### Task 5: Verify

**Files:**
- Modify tests only if the new public API requires fixture updates.

- [ ] Run the focused tests from Task 1.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test --no-pub`.
- [ ] Run `git diff --check`.
