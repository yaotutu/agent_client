# Agent Client Responsive UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the approved adaptive UI so phone, tablet, and large screens feel coherent while every non-phone layout stays two columns.

**Architecture:** Keep changes in Flutter presentation widgets and app theme files. The app shell owns the responsive Agent navigation mode; Chat owns session selection through a lower-left composer button and dialog; Files and Tasks keep their existing data flow and receive visual density updates only.

**Tech Stack:** Flutter, Material 3, hooks_riverpod, flutter_test.

---

## File Structure

- Modify `test/agent_shell_test.dart` to encode the approved responsive behavior.
- Modify `lib/app/theme/app_theme.dart` and create `lib/app/theme/app_theme_tokens.dart` for shared UI tokens.
- Modify `lib/features/agents/presentation/agent_workspace_page.dart` for compact, medium, and wide shell layout.
- Modify `lib/features/agents/presentation/agent_side_rail.dart` to support compact and full Agent navigation variants.
- Modify `lib/features/chat/presentation/chat_panel.dart` so Chat never renders a permanent session rail.
- Modify `lib/features/chat/presentation/widgets/chat_input_bar.dart` to keep the session switch button at the lower-left of the composer.
- Modify `lib/features/chat/presentation/widgets/chat_session_picker.dart` and `lib/features/chat/presentation/widgets/chat_session_rail.dart` for the session dialog styling.
- Modify `lib/features/chat/presentation/widgets/chat_message_list.dart` and `lib/features/chat/presentation/widgets/chat_message_bubble.dart` for roomier chat rhythm.
- Modify `lib/features/files/presentation/files_panel.dart` and `lib/features/tasks/presentation/tasks_panel.dart` for flatter workspace rows.

### Task 1: Responsive Behavior Tests

**Files:**
- Modify: `test/agent_shell_test.dart`

- [x] **Step 1: Write failing responsive shell tests**

Update the phone session test to expect the composer session button and no top picker:

```dart
expect(find.byKey(const Key('chat-session-rail')), findsNothing);
expect(find.byKey(const Key('chat-session-picker-button')), findsNothing);
expect(find.byKey(const Key('chat-session-switch-button')), findsOneWidget);

await tester.tap(find.byKey(const Key('chat-session-switch-button')));
await tester.pumpAndSettle();
```

Update the desktop session test to enforce two columns:

```dart
expect(find.byKey(const Key('agent-side-rail')), findsOneWidget);
expect(find.byKey(const Key('chat-session-rail')), findsNothing);
expect(find.byKey(const Key('chat-session-picker-button')), findsNothing);
expect(find.byKey(const Key('chat-session-switch-button')), findsOneWidget);

await tester.tap(find.byKey(const Key('chat-session-switch-button')));
await tester.pumpAndSettle();
await tester.tap(find.byKey(const Key('chat-session-session-flaky-test')));
await tester.pumpAndSettle();
```

Replace the tablet title test with a compact-rail test:

```dart
expect(find.byKey(const Key('agent-compact-rail')), findsOneWidget);
expect(find.byKey(const Key('agent-side-rail')), findsNothing);
expect(find.byKey(const Key('agent-navigation-button')), findsNothing);
expect(find.byKey(const Key('current-agent-title')), findsOneWidget);
expect(find.byKey(const Key('chat-session-rail')), findsNothing);
expect(find.byKey(const Key('chat-session-picker-button')), findsNothing);
expect(find.byKey(const Key('chat-session-switch-button')), findsOneWidget);
```

- [x] **Step 2: Verify tests fail before production code**

Run:

```sh
flutter test --no-pub test/agent_shell_test.dart
```

Expected: FAIL because the existing Chat panel still renders `chat-session-rail` on desktop/tablet, the new two-column shell is absent, and `agent-compact-rail` does not exist.

### Task 2: Shared Visual Tokens

**Files:**
- Create: `lib/app/theme/app_theme_tokens.dart`
- Modify: `lib/app/theme/app_theme.dart`

- [x] **Step 1: Add token file**

Create `AppThemeTokens` with these constants:

```dart
import 'package:flutter/material.dart';

abstract final class AppThemeTokens {
  static const brand = Color(0xFF256D85);
  static const workspace = Color(0xFFF4F6F8);
  static const panel = Colors.white;
  static const border = Color(0xFFE4E7EC);
  static const strongBorder = Color(0xFFD0D5DD);
  static const text = Color(0xFF101828);
  static const mutedText = Color(0xFF667085);
  static const subtleText = Color(0xFF98A2B3);
  static const brandSoft = Color(0xFFEAF3F5);
  static const dangerText = Color(0xFFB42318);
  static const dangerSoft = Color(0xFFFFF1F3);
  static const success = Color(0xFF027A48);
  static const successSoft = Color(0xFFECFDF3);
  static const radius = 8.0;
  static const compactRailWidth = 80.0;
  static const fullRailWidth = 280.0;
}
```

- [x] **Step 2: Wire theme to tokens**

Update `buildAppTheme()` to use `AppThemeTokens.brand`, `workspace`, `panel`, `border`, `strongBorder`, `text`, and `mutedText`.

- [x] **Step 3: Run formatting for changed Dart files**

Run:

```sh
dart format lib/app/theme/app_theme.dart lib/app/theme/app_theme_tokens.dart
```

Expected: formatter exits `0`.

### Task 3: Two-Column Agent Shell

**Files:**
- Modify: `lib/features/agents/presentation/agent_workspace_page.dart`
- Modify: `lib/features/agents/presentation/agent_side_rail.dart`

- [x] **Step 1: Implement shell breakpoints**

Use these breakpoints:

```dart
const _mediumMinWidth = 600.0;
const _wideMinWidth = 840.0;
```

Render modes:

```dart
final width = constraints.maxWidth;
final isCompact = width < _mediumMinWidth;
final isWide = width >= _wideMinWidth;
```

Compact uses drawer and no rail. Medium uses `AgentCompactRail`. Wide uses `AgentSideRail`.

- [x] **Step 2: Add medium workspace header**

Keep `_AgentHeader` on compact and medium screens. On compact it includes the menu button. On medium it shows only the current agent title because the compact rail already handles navigation.

- [x] **Step 3: Implement compact rail**

Add `AgentCompactRail` in `agent_side_rail.dart`. It has key `agent-compact-rail`, width `AppThemeTokens.compactRailWidth`, vertical agent avatars, selected state, and an add button that opens the existing create-agent dialog through `AgentNavigationPanel.openCreateAgentDialog(context)`.

- [x] **Step 4: Keep full rail readable**

Keep `AgentSideRail` at `AppThemeTokens.fullRailWidth`, key `agent-side-rail`, and use `AgentNavigationPanel`.

- [x] **Step 5: Run targeted shell tests**

Run:

```sh
flutter test --no-pub test/agent_shell_test.dart
```

Expected: remaining failures should be limited to Chat session picker/input behavior until Task 4 is complete.

### Task 4: Chat Session Dialog And Composer Button

**Files:**
- Modify: `lib/features/chat/presentation/chat_panel.dart`
- Modify: `lib/features/chat/presentation/widgets/chat_input_bar.dart`
- Modify: `lib/features/chat/presentation/widgets/chat_session_picker.dart`
- Modify: `lib/features/chat/presentation/widgets/chat_session_rail.dart`

- [x] **Step 1: Remove permanent session rail**

In `ChatPanel`, remove the `LayoutBuilder` branch that renders `ChatSessionRail`. Render:

```dart
Column(
  children: [
    Expanded(child: ChatMessageList(...)),
    if (state.errorMessage case final error?) InlineChatError(message: error),
    ChatInputBar(...),
  ],
)
```

- [x] **Step 2: Keep composer session button**

Keep `onSwitchSession` on `ChatInputBar`, keep the leading `IconButton` with key `chat-session-switch-button`, and place it before the text field so it sits at the lower-left of the composer.

- [x] **Step 3: Remove top picker**

Do not render `ChatSessionPickerBar` in the main Chat panel. Keep `showChatSessionDialog` available for the composer button.

- [x] **Step 4: Style session dialog**

Keep key `chat-session-dialog`. Keep `ChatSessionTile` keys as `chat-session-${session.id}`. Ensure `chat-session-dialog-new-button` starts a new session and closes the dialog.

- [x] **Step 5: Run targeted chat shell tests**

Run:

```sh
flutter test --no-pub test/agent_shell_test.dart
```

Expected: responsive shell tests pass. Any remaining failures should be from visual row text updates and must be handled before continuing.

### Task 5: Workspace Visual Polish

**Files:**
- Modify: `lib/features/chat/presentation/widgets/chat_message_list.dart`
- Modify: `lib/features/chat/presentation/widgets/chat_message_bubble.dart`
- Modify: `lib/features/files/presentation/files_panel.dart`
- Modify: `lib/features/tasks/presentation/tasks_panel.dart`

- [x] **Step 1: Adjust chat rhythm**

Use `AppThemeTokens.workspace` for the list background, `AppThemeTokens.panel` for assistant bubbles, `AppThemeTokens.brand` for user bubbles, and increase bubble max width from `680` to `760`.

- [x] **Step 2: Flatten Files rows**

Use the shared border, panel, brand-soft icon block, `12px` vertical padding, and `8px` radius. Keep keys and existing open/edit behavior unchanged.

- [x] **Step 3: Flatten Tasks rows**

Use the shared border, panel, muted text, and status colors. Keep the visible task title, detail, due label, and status pill text unchanged.

- [x] **Step 4: Run formatting**

Run:

```sh
dart format lib/app/theme lib/features/agents/presentation lib/features/chat/presentation lib/features/files/presentation lib/features/tasks/presentation test/agent_shell_test.dart
```

Expected: formatter exits `0`.

### Task 6: Full Verification

**Files:**
- Verify all changed files.

- [x] **Step 1: Run analyzer**

Run:

```sh
flutter analyze
```

Expected: exit `0`.

- [x] **Step 2: Run tests**

Run:

```sh
flutter test --no-pub
```

Expected: exit `0`.

- [x] **Step 3: Run whitespace check**

Run:

```sh
git diff --check
```

Expected: no output and exit `0`.

- [x] **Step 4: Inspect diff**

Run:

```sh
git diff --stat
git diff -- lib test docs/superpowers/plans/2026-05-29-agent-client-responsive-ui-implementation.md
```

Expected: diff only contains responsive UI, visual token, test, and plan changes.
