# Project Code Cleanup Implementation Plan

> Superseded note: this historical plan predates the current
> `mobile/`, `tablet/`, `desktop/`, and `shared/` presentation layout. Use
> `docs/superpowers/specs/2026-06-02-mobile-first-adaptive-ui-strategy.md` and
> `AGENTS.md` for current file locations.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 整理 Flutter 客户端代码结构，让 Agent Control adapter 边界更清晰，并拆分明显过大的展示代码，同时保持现有行为不变。

**Architecture:** Feature repository port 继续由各 feature 暴露；Agent Control 的 DTO 映射和具体 repository 实现移动到 `features/agent_control/data`。Provider 默认仍注入 Agent Control 实现，但 UI/controller 不直接依赖 Agent Control。大文件拆分只处理职责明确的私有 widget/helper，不扩大 public API。

**Tech Stack:** Flutter, Dart, hooks_riverpod, flutter_test.

---

## File Structure

- Create: `lib/features/agent_control/data/agent_control_agent_registry_repository.dart`
  - Agent Control implementation of `AgentRegistryRepository`.
- Create: `lib/features/agent_control/data/agent_control_resources_repository.dart`
  - Agent Control implementation of `AgentResourcesRepository`.
- Create: `lib/features/agent_control/data/agent_control_settings_repository.dart`
  - Agent Control implementation of `AgentSettingsRepository`.
- Create: `lib/features/agent_control/data/agent_control_git_repository.dart`
  - Agent Control implementation of `AgentGitRepository`.
- Create: `lib/features/agents/domain/agent_registry_repository.dart`
  - Agent registry repository port.
- Create: `lib/features/files/domain/agent_resources_repository.dart`
  - Workspace resource repository port.
- Create: `lib/features/settings/domain/agent_settings_repository.dart`
  - Settings repository port.
- Create: `lib/features/git/domain/agent_git_repository.dart`
  - Git repository port.
- Move: `lib/features/chat/data/agent_control_chat_repository.dart`
  - New path: `lib/features/agent_control/data/agent_control_chat_repository.dart`.
- Move: `lib/features/chat/data/agent_control_chat_services.dart`
  - New path: `lib/features/agent_control/data/agent_control_chat_services.dart`.
- Modify: `lib/features/agents/data/agent_registry_repository.dart`
  - Keep local avatar decorator and provider wiring; no compatibility export.
- Modify: `lib/features/files/data/agent_resources_repository.dart`
  - Keep provider wiring; no compatibility export.
- Modify: `lib/features/settings/data/agent_settings_repository.dart`
  - Keep feature providers; no compatibility export.
- Modify: `lib/features/git/data/agent_git_repository.dart`
  - Keep feature providers; no compatibility export.
- Modify: `lib/features/chat/data/agent_chat_repository_provider.dart`
  - Point provider wiring to the moved Agent Control chat adapter.
- Create: `lib/features/agents/presentation/agent_workspace_conversation_helpers.dart`
  - Private conversation list helpers and delete confirmation dialog as a `part` file.
- Modify: `lib/features/agents/presentation/agent_workspace_page.dart`
  - Add the new `part`.
- Modify: `lib/features/agents/presentation/agent_workspace_conversation_list.dart`
  - Remove helpers moved to the new part file.
- Modify: tests that import moved adapter files.

---

### Task 1: Move Agent Control Repository Implementations

**Files:**
- Create: `lib/features/agent_control/data/agent_control_agent_registry_repository.dart`
- Create: `lib/features/agent_control/data/agent_control_resources_repository.dart`
- Create: `lib/features/agent_control/data/agent_control_settings_repository.dart`
- Create: `lib/features/agent_control/data/agent_control_git_repository.dart`
- Create: `lib/features/agents/domain/agent_registry_repository.dart`
- Create: `lib/features/files/domain/agent_resources_repository.dart`
- Create: `lib/features/settings/domain/agent_settings_repository.dart`
- Create: `lib/features/git/domain/agent_git_repository.dart`
- Modify: `lib/features/agents/data/agent_registry_repository.dart`
- Modify: `lib/features/files/data/agent_resources_repository.dart`
- Modify: `lib/features/settings/data/agent_settings_repository.dart`
- Modify: `lib/features/git/data/agent_git_repository.dart`

- [x] **Step 1: Create Agent Control registry adapter**

Create `lib/features/agents/domain/agent_registry_repository.dart` with the `AgentRegistryRepository` port, then create `lib/features/agent_control/data/agent_control_agent_registry_repository.dart` with `AgentControlAgentRegistryRepository`, `_toAgent`, and `_statusFor`. Keep the existing mapping from `AgentSummary` and `CreateAgentResponse` to `Agent`.

- [x] **Step 2: Trim feature registry repository**

In `lib/features/agents/data/agent_registry_repository.dart`, remove direct imports of `agent_control_models.dart` and the `AgentControlAgentRegistryRepository` class. Keep:

```dart
final agentRegistryRepositoryProvider = Provider<AgentRegistryRepository>((ref) {
  return LocalAvatarAgentRegistryRepository(
    delegate: AgentControlAgentRegistryRepository(
      ref.watch(agentControlApiClientProvider),
    ),
    avatarStore: ref.watch(agentAvatarStoreProvider),
  );
});
```

- [x] **Step 3: Create resources, settings, and git adapters**

Create the `AgentResourcesRepository`, `AgentSettingsRepository`, and `AgentGitRepository` ports under the matching feature `domain/` directories. Move the existing `AgentControlResourcesRepository`, `AgentControlSettingsRepository`, and `AgentControlGitRepository` classes into matching files under `lib/features/agent_control/data`. Preserve all mapping methods exactly.

- [x] **Step 4: Trim feature resources, settings, and git files**

Keep only provider wiring in the feature data files. Providers should construct the moved Agent Control implementations with `ref.watch(agentControlApiClientProvider)`. Do not keep compatibility exports for the domain repository ports.

- [x] **Step 5: Run focused tests**

Run:

```sh
flutter test --no-pub test/agent_controller_test.dart test/agent_shell_test.dart
```

Expected: all tests pass.

---

### Task 2: Move Agent Control Chat Adapter

**Files:**
- Move: `lib/features/chat/data/agent_control_chat_repository.dart`
- Move: `lib/features/chat/data/agent_control_chat_services.dart`
- Modify: `lib/features/chat/data/agent_chat_repository_provider.dart`
- Modify: `test/agent_control_chat_repository_test.dart`

- [x] **Step 1: Move the chat adapter files**

Move both files to `lib/features/agent_control/data/`. Update imports inside the moved repository so it imports:

```dart
import 'package:agent_client/features/agent_control/data/agent_control_chat_services.dart';
```

- [x] **Step 2: Update provider wiring**

In `lib/features/chat/data/agent_chat_repository_provider.dart`, import the moved repository:

```dart
import 'package:agent_client/features/agent_control/data/agent_control_chat_repository.dart';
```

- [x] **Step 3: Update focused test imports**

In `test/agent_control_chat_repository_test.dart`, replace the old chat adapter import with:

```dart
import 'package:agent_client/features/agent_control/data/agent_control_chat_repository.dart';
```

- [x] **Step 4: Run focused chat adapter tests**

Run:

```sh
flutter test --no-pub test/agent_control_chat_repository_test.dart test/chat_controller_test.dart
```

Expected: all tests pass.

---

### Task 3: Split Conversation List Helpers

**Files:**
- Create: `lib/features/agents/presentation/agent_workspace_conversation_helpers.dart`
- Modify: `lib/features/agents/presentation/agent_workspace_page.dart`
- Modify: `lib/features/agents/presentation/agent_workspace_conversation_list.dart`
- Test: `test/agent_shell_test.dart`

- [x] **Step 1: Add the new part file**

Create `agent_workspace_conversation_helpers.dart` with:

```dart
part of 'agent_workspace_page.dart';
```

Move these private declarations from `agent_workspace_conversation_list.dart` into it:

- `_AgentMenuAction`
- `_confirmDeleteAgent`
- `_messagePreviewText`
- `_agentFallbackSubtitle`
- `_compactTime`

- [x] **Step 2: Register the part**

In `agent_workspace_page.dart`, add:

```dart
part 'agent_workspace_conversation_helpers.dart';
```

- [x] **Step 3: Run focused shell tests**

Run:

```sh
flutter test --no-pub test/agent_shell_test.dart
```

Expected: all tests pass.

---

### Task 4: Boundary Scan And Verification

**Files:**
- Modify only files needed to fix analyzer/test fallout from Tasks 1-3.

- [x] **Step 1: Scan Agent Control imports**

Run:

```sh
rg "features/agent_control" lib/features/*/presentation lib/features/*/application lib/features/*/domain
```

Expected: no matches.

- [x] **Step 2: Scan remaining adapter placement**

Run:

```sh
rg "agent_control_models|AgentControl.*Repository|AgentControlChat" lib/features/agents lib/features/files lib/features/settings lib/features/git lib/features/chat
```

Expected: feature files may reference moved Agent Control repository class names only in provider wiring; DTO imports should not remain outside `features/agent_control` and tests.

- [x] **Step 3: Run full verification**

Run:

```sh
flutter analyze
flutter test --no-pub
git diff --check
```

Expected: analyzer clean, tests pass, no whitespace errors.
