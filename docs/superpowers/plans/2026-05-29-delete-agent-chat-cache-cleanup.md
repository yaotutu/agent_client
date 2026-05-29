# Delete Agent Chat Cache Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deleting an agent must remove that agent's local chat cache and reset in-memory chat/session providers so old messages cannot reappear after deletion or same-name recreation.

**Architecture:** Keep backend deletion as the source of truth, then perform local cleanup through the existing chat cache port. The agent controller coordinates the cross-feature cleanup after backend delete succeeds, clears persistent cache by `agentId`, and invalidates Riverpod family providers that may still hold old in-memory state.

**Tech Stack:** Flutter, Dart, hooks_riverpod, Drift, flutter_test.

---

## File Structure

- Modify: `lib/features/chat/data/chat_cache_store.dart`
  - Add an agent-scoped `clearAgent(String agentId)` method to the cache port.
  - Implement it in `InMemoryChatCacheStore` for tests.
- Modify: `lib/features/chat/data/drift_chat_cache_store.dart`
  - Implement `clearAgent` for persistent Drift cache.
  - Delete `cached_messages` rows and `cached_conversations` rows for the deleted agent.
  - Do not change the Drift schema or generated file.
- Modify: `lib/features/agents/application/agent_controller.dart`
  - After backend deletion succeeds, clear local chat cache.
  - Invalidate `chatControllerProvider(agentId)` and `chatSessionsProvider(agentId)`.
  - Keep existing agent list refresh and current-agent selection behavior.
- Modify: `test/agent_controller_test.dart`
  - Add a regression test that proves deletion clears both persistent-style cache state and Riverpod in-memory chat/session state for the deleted agent only.

---

### Task 1: Add Failing Regression Test

**Files:**
- Modify: `test/agent_controller_test.dart`

- [ ] **Step 1: Add imports for chat cache, chat controller, chat sessions, and chat domain models**

Add these imports after the existing agent imports:

```dart
import 'package:agent_client/features/chat/application/chat_controller.dart';
import 'package:agent_client/features/chat/application/chat_sessions_controller.dart';
import 'package:agent_client/features/chat/data/chat_cache_provider.dart';
import 'package:agent_client/features/chat/data/chat_cache_store.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:agent_client/features/chat/domain/chat_session.dart';
```

- [ ] **Step 2: Add the failing test**

Add this test after the existing `deleteAgent deletes through backend and selects the first remaining agent` test:

```dart
  test(
    'deleteAgent clears local chat cache and invalidates chat state for deleted agent',
    () async {
      final api = _FakeAgentControlApi([
        _agentSummary('nanobot'),
        _agentSummary('reviewer'),
      ]);
      final cache = InMemoryChatCacheStore();
      final container = ProviderContainer(
        overrides: [
          agentControlApiClientProvider.overrideWithValue(api),
          chatCacheStoreProvider.overrideWithValue(cache),
        ],
      );
      addTearDown(container.dispose);

      await cache.saveMessage(
        ChatMessage(
          id: 'reviewer-message',
          agentId: 'reviewer',
          conversationId: 'reviewer-session',
          role: ChatRole.assistant,
          content: 'Old reviewer chat',
          status: ChatMessageStatus.completed,
          createdAt: DateTime(2026, 5, 28),
        ),
      );
      await cache.saveMessage(
        ChatMessage(
          id: 'nanobot-message',
          agentId: 'nanobot',
          conversationId: 'nanobot-session',
          role: ChatRole.assistant,
          content: 'Keep nanobot chat',
          status: ChatMessageStatus.completed,
          createdAt: DateTime(2026, 5, 28, 1),
        ),
      );
      await container
          .read(chatControllerProvider('reviewer').notifier)
          .loadRecentMessages();
      container
          .read(chatSessionsProvider('reviewer').notifier)
          .insertSession(
            const ChatSessionSummary(
              id: 'reviewer-session',
              title: 'Old reviewer chat',
              preview: 'Old reviewer chat',
              messageCount: 1,
            ),
          );

      expect(
        container.read(chatControllerProvider('reviewer')).messages.single.id,
        'reviewer-message',
      );
      expect(
        container.read(chatSessionsProvider('reviewer')).sessions.single.id,
        'reviewer-session',
      );

      await container
          .read(currentAgentIdProvider.notifier)
          .deleteAgent('reviewer');

      expect(api.deletedName, 'reviewer');
      expect(await cache.loadLatestMessages('reviewer'), isEmpty);
      expect(
        await cache.loadLatestMessages('nanobot'),
        isNotEmpty,
      );
      expect(
        container.read(chatControllerProvider('reviewer')).messages,
        isEmpty,
      );
      expect(
        container.read(chatSessionsProvider('reviewer')).sessions,
        isEmpty,
      );
    },
  );
```

- [ ] **Step 3: Run the focused test and verify it fails**

Run:

```bash
flutter test --no-pub test/agent_controller_test.dart
```

Expected: FAIL. The deleted agent still has `reviewer-message` in cache and/or old provider state because deletion does not clear chat cache or invalidate chat providers yet.

---

### Task 2: Add Agent-Scoped Cache Clear API

**Files:**
- Modify: `lib/features/chat/data/chat_cache_store.dart`
- Test: `test/agent_controller_test.dart`

- [ ] **Step 1: Add `clearAgent` to the `ChatCacheStore` interface**

Update the interface:

```dart
abstract interface class ChatCacheStore {
  Future<void> saveMessage(ChatMessage message);

  Future<void> clearAgent(String agentId);

  Future<void> clearSession({
    required String agentId,
    required String sessionId,
  });

  Future<List<ChatMessage>> loadMessages({
    required String agentId,
    required String sessionId,
    int limit = 50,
  });

  Future<List<ChatMessage>> loadLatestMessages(
    String agentId, {
    int limit = 50,
  });
}
```

- [ ] **Step 2: Implement `clearAgent` in `InMemoryChatCacheStore`**

Add this method before `clearSession`:

```dart
  @override
  Future<void> clearAgent(String agentId) async {
    _messagesByAgent.remove(agentId);
  }
```

- [ ] **Step 3: Run the focused test and verify it still fails**

Run:

```bash
flutter test --no-pub test/agent_controller_test.dart
```

Expected: FAIL. The API exists, but `CurrentAgentController.deleteAgent` does not call it yet.

---

### Task 3: Implement Drift Persistent Cleanup

**Files:**
- Modify: `lib/features/chat/data/drift_chat_cache_store.dart`

- [ ] **Step 1: Add `clearAgent` to `DriftChatCacheStore`**

Add this method before `clearSession`:

```dart
  @override
  Future<void> clearAgent(String agentId) {
    return _database.transaction(() async {
      await (_database.delete(_database.cachedMessages)
            ..where((table) => table.agentId.equals(agentId)))
          .go();
      await (_database.delete(_database.cachedConversations)
            ..where((table) => table.agentId.equals(agentId)))
          .go();
    });
  }
```

- [ ] **Step 2: Run analyzer to catch interface implementation mistakes**

Run:

```bash
flutter analyze
```

Expected: Analyzer may still report failures until Task 4 wires all imports, but there should be no Drift schema-generation requirement because no table shape changed.

---

### Task 4: Wire Cleanup Into Agent Deletion

**Files:**
- Modify: `lib/features/agents/application/agent_controller.dart`
- Test: `test/agent_controller_test.dart`

- [ ] **Step 1: Add imports**

Add these imports near the top of `agent_controller.dart`:

```dart
import 'package:agent_client/features/chat/application/chat_controller.dart';
import 'package:agent_client/features/chat/application/chat_sessions_controller.dart';
import 'package:agent_client/features/chat/data/chat_cache_provider.dart';
```

- [ ] **Step 2: Replace `deleteAgent` with cleanup-aware orchestration**

Replace the existing `deleteAgent` method with:

```dart
  Future<void> deleteAgent(String agentId) async {
    final currentAgentId = await _effectiveCurrentAgentId();
    await ref.read(agentRegistryRepositoryProvider).deleteAgent(agentId);

    try {
      await ref.read(chatCacheStoreProvider).clearAgent(agentId);
    } finally {
      ref.invalidate(chatControllerProvider(agentId));
      ref.invalidate(chatSessionsProvider(agentId));
      ref.invalidate(agentsProvider);
      final remainingAgents = await ref.read(agentsProvider.future).catchError((
        _,
      ) {
        return <Agent>[];
      });

      if (currentAgentId == agentId) {
        state = remainingAgents.isEmpty ? '' : remainingAgents.first.id;
      }
    }
  }
```

This keeps backend delete as the gate. Local cache is not cleared if backend deletion fails. If local cleanup throws after backend deletion succeeds, the agent list and provider state still refresh in `finally`.

- [ ] **Step 3: Run the focused regression test**

Run:

```bash
flutter test --no-pub test/agent_controller_test.dart
```

Expected: PASS.

---

### Task 5: Verify Existing Chat Session Semantics Still Hold

**Files:**
- Test: `test/chat_controller_test.dart`
- Test: `test/agent_shell_test.dart`

- [ ] **Step 1: Run chat controller tests**

Run:

```bash
flutter test --no-pub test/chat_controller_test.dart
```

Expected: PASS. In particular, `startNewSession creates a fresh backend session without clearing other sessions` must still pass. This confirms the new `clearAgent` behavior does not change `startNewSession`.

- [ ] **Step 2: Run shell/widget tests that cover delete UI**

Run:

```bash
flutter test --no-pub test/agent_shell_test.dart
```

Expected: PASS. This confirms the UI confirmation flow still calls the same controller path.

---

### Task 6: Format And Final Verification

**Files:**
- Modify: `lib/features/chat/data/chat_cache_store.dart`
- Modify: `lib/features/chat/data/drift_chat_cache_store.dart`
- Modify: `lib/features/agents/application/agent_controller.dart`
- Modify: `test/agent_controller_test.dart`

- [ ] **Step 1: Format touched Dart files**

Run:

```bash
dart format lib/features/chat/data/chat_cache_store.dart lib/features/chat/data/drift_chat_cache_store.dart lib/features/agents/application/agent_controller.dart test/agent_controller_test.dart
```

Expected: Formatter completes successfully.

- [ ] **Step 2: Run full test suite**

Run:

```bash
flutter test --no-pub
```

Expected: PASS.

- [ ] **Step 3: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: PASS.

- [ ] **Step 4: Check whitespace**

Run:

```bash
git diff --check
```

Expected: no output.

---

## Acceptance Criteria

- Deleting an agent calls backend `DELETE /agents/{agentName}` first.
- If backend deletion fails, local chat cache is not cleared.
- If backend deletion succeeds, local cached messages for the deleted `agentId` are removed.
- Cached messages for other agents are preserved.
- `chatControllerProvider(deletedAgentId)` no longer holds old messages after deletion.
- `chatSessionsProvider(deletedAgentId)` no longer holds old session summaries after deletion.
- Creating a new agent with the same name cannot display old local messages from the deleted agent.
- Existing behavior for starting a new session remains unchanged: it does not clear other sessions for the same agent.

## Self-Review

- Spec coverage: The plan covers persistent Drift cache, in-memory test cache, Riverpod provider state, backend-delete ordering, and regression tests.
- Placeholder scan: No implementation steps rely on TBD or unspecified error handling.
- Type consistency: `clearAgent(String agentId)` is used consistently in the port, in-memory store, Drift store, and agent controller.
