# Nanobot WebUI Parity Map

## Source Snapshot

Nanobot source:

```text
ea7f4679 2026-07-08 12:16:47 +0800 fix(webui): keep prompt rail at original gutter offset
```

Nanobot worktree status was clean during this audit.

Primary WebUI reference path:

```text
/home/yaotutu/Desktop/code/nanobot/webui/src
```

## Current Flutter Snapshot

Flutter source:

```text
8579db9 2026-07-08 16:07:34 +0800 docs: define nanobot webui parity goal
```

Current Flutter worktree status during this audit:

```text
D .codex/config.toml
?? docs/superpowers/plans/2026-07-08-nanobot-webui-parity-audit.md
```

The `.codex/config.toml` deletion is unrelated local state and is not part of
this goal.

Primary Flutter nanobot files:

```text
lib/app/nanobot_client_app.dart
lib/app/adaptive/adaptive_layout_policy.dart
lib/core/config/app_config*.dart
lib/features/nanobot/application/nanobot_workspace_controller.dart
lib/features/nanobot/application/nanobot_workspace_state.dart
lib/features/nanobot/data/nanobot_api_client.dart
lib/features/nanobot/data/nanobot_repository.dart
lib/features/nanobot/data/nanobot_ws_client.dart
lib/features/nanobot/domain/nanobot_bootstrap.dart
lib/features/nanobot/domain/nanobot_config.dart
lib/features/nanobot/domain/nanobot_event.dart
lib/features/nanobot/domain/nanobot_message.dart
lib/features/nanobot/domain/nanobot_session.dart
lib/features/nanobot/presentation/nanobot_workspace_page.dart
```

## Status Legend

| Status | Meaning |
| --- | --- |
| Implemented | Covered in Flutter source and previously verified on device. |
| Partial | Some Flutter support exists, but WebUI behavior is incomplete. |
| Missing | No meaningful Flutter implementation exists. |
| Unverified | Likely implemented, but no current evidence proves parity. |
| Blocked | Cannot be implemented or verified without a missing capability. |

No item in this audit is considered complete for the final goal until it has
true-device evidence against `http://192.168.200.149:8765/`.

## Shell and Navigation

WebUI shell views are defined in `webui/src/App.tsx`:

```text
chat
settings
apps
automations
skills
```

| WebUI item | WebUI source | Flutter source | Status | Gap / next action |
| --- | --- | --- | --- | --- |
| Chat shell view | `App.tsx`, `ThreadShell.tsx` | `nanobot_workspace_page.dart` | Partial | Flutter has a single chat page, but not WebUI shell route state or secondary overlay behavior. |
| Settings shell view | `App.tsx`, `SettingsView.tsx` | settings dialog in `nanobot_workspace_page.dart` | Missing | Replace config-only dialog with WebUI settings view sections. |
| Apps shell view | `App.tsx`, `SettingsView.tsx` apps section | none | Missing | Add apps entry and settings apps surface. |
| Automations shell view | `App.tsx`, `SettingsView.tsx` automations section | none | Missing | Add automations entry and action flows. |
| Skills shell view | `App.tsx`, `SkillsCatalogSettings.tsx` | none | Missing | Add skills list/detail surface. |
| Hash/route-derived active view and chat | `readShellRoute`, `writeShellRoute` in `App.tsx` | none | Missing | Introduce native shell state for active view, active chat, and settings section. |
| Sidebar open/collapsed/mobile sheet | `App.tsx`, `Sidebar.tsx`, `Sheet` | `Drawer` and fixed wide side panel | Partial | Flutter lacks rail width, host chrome inset, mobile sheet width, and persisted sidebar open state. |
| Theme toggle | `useTheme.ts`, `SettingsView.tsx` | app theme only | Missing | Add WebUI-equivalent theme preference and settings control. |
| Language switcher | `LanguageSwitcher.tsx`, i18n locales | none | Missing | Add i18n infrastructure only if WebUI parity requires localized UI. |

## Sidebar and Sessions

| WebUI item | WebUI source | Flutter source | Status | Gap / next action |
| --- | --- | --- | --- | --- |
| Load sessions | `useSessions.ts`, `api.ts:listSessions` | `NanobotApiClient.listSessions` | Partial | Basic load exists; missing workspace grouping, pinned/archived, sidebar state, deferred title refresh. |
| Session title and preview | `ChatList.tsx`, `chat-groups.ts` | `_SessionTile`, `NanobotSessionSummary` | Partial | Basic title/preview exists; missing low-information title filtering and title overrides. |
| Running state in sidebar | `NanobotClient.onRunStatus`, `ChatList.tsx` | `runStartedAt`, `isStreaming` | Partial | Flutter reads initial run flag but lacks per-chat run fanout and elapsed run strip. |
| New chat | `NanobotClient.createChat`, `ThreadShell.tsx` | `NanobotWsClient.newChat` | Partial | Basic frame exists; missing workspace scope, pending first message behavior, and robust error mapping. |
| Attach existing chat | `NanobotClient.attach` | `NanobotWsClient.attach` | Partial | Basic frame exists; missing pending inbound buffering and reattach semantics equal to WebUI. |
| Session search | `SessionSearchDialog.tsx` | none | Missing | Add searchable session dialog/sheet. |
| Rename chat | `RenameChatDialog.tsx`, `useSidebarState.ts:title_overrides` | none | Missing | Implement title overrides through sidebar state. |
| Rename project group | `RenameChatDialog.tsx`, `project_name_overrides` | none | Missing | Implement project group name overrides. |
| Pin/unpin chat | `ChatList.tsx`, `pinned_keys` | none | Missing | Implement pin state and ordering. |
| Archive/unarchive chat | `ChatList.tsx`, `archived_keys`, `view.show_archived` | none | Missing | Implement archive state and visibility toggle. |
| Delete chat | `api.ts:deleteSession`, `DeleteConfirm.tsx` | none | Missing | Implement delete endpoint and automation-blocked confirmation. Destructive real-gateway tests require user approval. |
| Sidebar server state | `api.ts:fetchSidebarState/updateSidebarState`, `useSidebarState.ts` | none | Missing | Add typed sidebar state model and controller. |
| Deferred title refresh | `useDeferredTitleRefresh.ts` | `refreshSessions` on `turn_end` | Partial | Flutter refreshes once; WebUI retries untitled sessions after turn end. |

## Thread and Message Rendering

| WebUI item | WebUI source | Flutter source | Status | Gap / next action |
| --- | --- | --- | --- | --- |
| Persisted WebUI thread latest page | `api.ts:fetchWebuiThread` | `NanobotApiClient.fetchWebuiThread` | Partial | Basic latest fetch exists; missing `before`, page metadata, pending tool calls, fork boundary, workspace scope. |
| Older history pagination | `useSessions.ts`, `ThreadShell.tsx` | none | Missing | Implement `before` cursor and prepend behavior. |
| Stale snapshot protection | `ThreadShell.tsx` durable message helpers | `_loadGeneration` only | Partial | Flutter prevents cross-session stale loads but not canonical/live merge parity. |
| User/assistant roles | `MessageBubble.tsx` | `_MessageBubble` | Partial | Basic roles render. Missing rich role metadata and source labels. |
| Tool/trace rows | `MessageBubble.tsx`, `AgentActivityCluster.tsx` | activity text only | Missing | Add trace message model and activity cluster rendering. |
| Markdown rendering | `MarkdownText*.tsx`, `CodeBlock.tsx` | plain `Text` | Missing | Add Flutter Markdown/code block renderer with copy and wrapping behavior. |
| Reasoning rendering | `ReasoningRow.tsx`, `MessageBubble.tsx` | reasoning string display | Partial | Flutter shows reasoning text but lacks streaming state, collapse/grouping, latency, and activity segments. |
| Images/media attachments | `AttachmentTile.tsx`, `ImageLightbox.tsx`, `MessageBubble.tsx` | none | Missing | Add media model, thumbnail tiles, full-screen image preview, and unavailable media fallback tiles. |
| CLI app mentions | `CliAppMentionText.tsx`, `ThreadComposer.tsx` | none | Missing | Add mention attachment render support. |
| MCP preset mentions | `ThreadComposer.tsx`, `mcp-preset-events.ts` | none | Missing | Add preset mention attachment render support. |
| Proactive automation source metadata | `types.ts:UIMessageSource`, `MessageBubble.tsx` | none | Missing | Preserve and render message source labels. |
| Fork assistant replies | `ThreadShell.tsx:onForkChat`, `NanobotClient.forkChat` | none | Missing | Implement fork frame and global user message index mapping. |

## Composer and Input Flows

| WebUI item | WebUI source | Flutter source | Status | Gap / next action |
| --- | --- | --- | --- | --- |
| Basic text send | `ThreadComposer.tsx` | `_InputBar`, `sendMessage` | Partial | Send works, but keyboard, queued prompts, active-turn controls, and attachments are incomplete. |
| Stop active turn | slash lifecycle and `onStop` in `ThreadComposer.tsx` | sends `/stop` as message | Partial | WebUI slash command lifecycle must be respected; `/stop` frame behavior needs parity verification. |
| Slash commands | `api.ts:listSlashCommands`, `ThreadComposer.tsx` | none | Missing | Add command API, palette, recent commands, lifecycle handling. |
| Image/media attach | `useAttachedImages.ts`, `imageEncode.ts`, `ThreadComposer.tsx` | none | Missing | Add picker/preview/remove/base64 outbound media. |
| Queued prompts | `ThreadComposer.tsx:readQueuedPrompts/storeQueuedPrompts` | none | Missing | Add per-session queue persistence and automatic send after streaming completes. |
| CLI app mention palette | `fetchInstalledCliApps`, `ThreadComposer.tsx` | none | Missing | Add installed app fetch and mention payloads. |
| MCP preset mention palette | `fetchMcpPresets`, `ThreadComposer.tsx` | none | Missing | Add configured preset fetch and mention payloads. |
| Workspace scope controls | `WorkspaceControls.tsx`, `set_workspace_scope` | none | Missing | Add workspace API, selection UI, outbound frame, rejection handling. |
| Voice transcription | `useVoiceRecorder.ts`, `transcribe_audio` | none | Missing | Add permission flow, recorder, data URL frame, result/error handling. |
| Image generation option | `OutboundImageGeneration`, composer model badge | none | Missing | Add image generation send option when settings enable it. |

## Live Stream and Activity State

| WebUI item | WebUI source | Flutter source | Status | Gap / next action |
| --- | --- | --- | --- | --- |
| `delta` | `useNanobotStream.ts` | `_appendAssistantDelta` | Partial | Text append exists; missing turn metadata, debounce, closed stream tracking. |
| `stream_end` | `useNanobotStream.ts` | `_completeStreamingAssistant` | Partial | Completes current assistant only; lacks delayed closure and pending event flush. |
| `reasoning_delta` | `useNanobotStream.ts` | `reasoningText` append | Partial | Missing reasoning row merge rules and activity segment handling. |
| `reasoning_end` | `useNanobotStream.ts` | clears reasoning | Partial | WebUI finalizes reasoning on message row; Flutter clears transient reasoning. |
| `message` final answer | `useNanobotStream.ts` | `_appendCompleteAssistantMessage` | Partial | Missing tool/progress/reasoning kind handling, media URLs, latency, source, turn fields. |
| `message` tool hints/progress | `useNanobotStream.ts` | none | Missing | Add trace rows and structured tool event merge. |
| `file_edit` | `useNanobotStream.ts`, `FileEditRow.tsx` | `activityText: Editing files` | Partial | Event kind parsed but file edit payload is discarded. |
| `turn_end` | `useNanobotStream.ts` | completes stream, refreshes sessions | Partial | Missing latency, goal state snapshot, final stream flush, and title retry. |
| `goal_status` | `NanobotClient.recordGoalStatusForRunStrip` | `activityText` running/idle | Partial | Missing per-chat run started map and elapsed strip. |
| `goal_state` | `NanobotClient.recordGoalStateSnapshot` | ignored | Missing | Add sustained goal state model and UI summary/objective panel. |
| `session_updated` | `NanobotClient.onSessionUpdate` | refreshes all sessions | Partial | Missing scope-specific handling and workspace scope update. |
| `runtime_model_updated` | `NanobotClient.onRuntimeModelUpdate` | `modelName` update | Partial | Basic model name update exists; missing model preset/provider badge. |
| `transcription_result/error` | `NanobotClient` pending transcription map | none | Missing | Add event kinds and pending transcription behavior. |
| `error: workspace_scope_rejected` | `NanobotClient.onError` | generic error | Missing | Add structured workspace rejection UI. |
| Close code `1009` | `NanobotClient.onclose` | generic socket error | Missing | Map to message-too-large UI. |
| Pending inbound buffer | `NanobotClient.pendingInboundByChat` | none | Missing | Buffer events for chats with no active subscriber. |
| Reconnect and reauth | `NanobotClient.onReauth/updateUrl` | reconnect not implemented | Missing | Add token refresh, reconnect backoff, known chat reattach. |

## File, Media, and Preview Surfaces

| WebUI item | WebUI source | Flutter source | Status | Gap / next action |
| --- | --- | --- | --- | --- |
| File reference chip | `FileReferenceChip.tsx` | none | Missing | Add chip model and renderer. |
| File preview API | `api.ts:fetchFilePreview` | none | Missing | Add endpoint and UI panel. |
| File preview panel | `FilePreviewPanel.tsx` | none | Missing | Add code/text preview with truncation state. |
| Image lightbox | `ImageLightbox.tsx` | none | Missing | Add full-screen image preview. |
| Attachment tile | `AttachmentTile.tsx` | none | Missing | Add media/file attachment tile rendering. |
| Activity evidence preview | `ActivityEvidencePreview.tsx` | none | Missing | Add activity evidence cards when tool events include embeds/files. |
| Diff/file edit preview | `DiffPair.tsx`, `FileEditRow.tsx` | none | Missing | Preserve file edit payload and render edit rows. |

## Settings and Secondary Surfaces

WebUI settings sections from `SettingsView.tsx`:

```text
overview
appearance
models
image
voice
browser
apps
automations
skills
runtime
advanced
```

| WebUI item | WebUI source | Flutter source | Status | Gap / next action |
| --- | --- | --- | --- | --- |
| Overview | `SettingsView.tsx` | none | Missing | Add settings controller and overview rows. |
| Appearance | `SettingsView.tsx`, `useTheme.ts`, `LanguageSwitcher.tsx` | theme tokens only | Missing | Add theme, language, density, activity detail, code wrap, brand logo preferences. |
| Models/provider configuration | `SettingsView.tsx`, `fetchProviderModels` | model label only | Missing | Add model preset, provider picker, provider credentials/OAuth flows. |
| Image generation settings | `SettingsView.tsx` | none | Missing | Add image generation settings and save endpoint. |
| Voice/transcription settings | `SettingsView.tsx` | none | Missing | Add transcription settings and save endpoint. |
| Browser/web search settings | `SettingsView.tsx` | none | Missing | Add web search and provider settings. |
| Apps catalog | `SettingsView.tsx`, CLI app APIs | none | Missing | Add catalog, installed list, install/update/uninstall/test actions. |
| Automations | `SettingsView.tsx`, automation APIs | none | Missing | Add list, filters, edit, run, enable/disable, delete flows. |
| Skills catalog/detail | `SkillsCatalogSettings.tsx`, skills APIs | none | Missing | Add list/detail/requirements display. |
| Runtime | `SettingsView.tsx` | connection status only | Missing | Add runtime identity/system/safety rows and restart actions where capability allows. |
| Advanced/network safety | `SettingsView.tsx` | none | Missing | Add local service access and default access controls. |
| Token usage heatmap | `TokenUsageHeatmap.tsx`, `fetchSettingsUsage` | none | Missing | Add usage fetch and heatmap or equivalent native visualization. |

## HTTP API Coverage

| WebUI API function | Endpoint / behavior | Flutter source | Status | Gap / next action |
| --- | --- | --- | --- | --- |
| `fetchBootstrap` | `GET /webui/bootstrap`, `X-Nanobot-Auth` | `NanobotApiClient.bootstrap` | Partial | Implement token refresh scheduling and HTML/non-JSON mismatch handling. |
| `listSessions` | `GET /api/sessions` | `NanobotApiClient.listSessions` | Partial | Preserve workspace scope and complete run metadata. |
| `fetchWebuiThread` | `GET /api/sessions/:key/webui-thread` with `limit`, `direction`, `before` | `fetchWebuiThread` | Partial | Add page metadata, `before`, pending tool calls, workspace scope. |
| `fetchFilePreview` | `GET /api/sessions/:key/file-preview?path=...` | none | Missing | Add file preview endpoint. |
| `fetchSessionAutomations` | `GET /api/sessions/:key/automations` | none | Missing | Add session automation endpoint. |
| `fetchAutomations` | `GET /api/webui/automations` | none | Missing | Add automations endpoint. |
| `runAutomationAction` | `/api/webui/automations/{enable,disable,delete,run}` | none | Missing | Add actions; destructive delete requires explicit user approval for live tests. |
| `updateAutomation` | `/api/webui/automations/update` | none | Missing | Add header-based update payload. |
| `fetchSkills` | `GET /api/webui/skills` | none | Missing | Add skills endpoint. |
| `fetchSkillDetail` | `GET /api/webui/skills/:name` | none | Missing | Add skill detail endpoint. |
| `deleteSession` | `/api/sessions/:key/delete` | none | Missing | Add delete endpoint and blocked automation result. |
| `fetchSettings` | `GET /api/settings` | none | Missing | Add settings payload model. |
| `fetchSettingsUsage` | `GET /api/settings/usage` | none | Missing | Add usage endpoint. |
| `checkVersion` | `GET /api/settings/version-check` | none | Missing | Add version check endpoint. |
| `fetchWorkspaces` | `GET /api/workspaces` | none | Missing | Add workspace model/controller. |
| `fetchCliApps` | `GET /api/settings/cli-apps` | none | Missing | Add CLI app catalog endpoint. |
| `fetchInstalledCliApps` | `GET /api/settings/cli-apps?installed_only=1` | none | Missing | Add installed apps endpoint for composer mentions. |
| `fetchNanobotFeatures` | `GET /api/settings/nanobot-features` | none | Missing | Add feature catalog endpoint. |
| `enableNanobotFeature` | `/api/settings/nanobot-features/enable` | none | Missing | Add action with confirmation flow. |
| `disableNanobotFeature` | `/api/settings/nanobot-features/disable` | none | Missing | Add action. |
| `runCliAppAction` | `/api/settings/cli-apps/{install,update,uninstall,test}` | none | Missing | Add actions; destructive/uninstall requires explicit user approval for live tests. |
| `fetchMcpPresets` | `GET /api/settings/mcp-presets` | none | Missing | Add MCP preset endpoint. |
| `fetchProviderModels` | `GET /api/settings/provider-models?provider=...` | none | Missing | Add provider model list. |
| `runMcpPresetAction` | `/api/settings/mcp-presets/{enable,remove,test}` | none | Missing | Add MCP preset actions and setup values header. |
| `saveCustomMcpServer` | `/api/settings/mcp-presets/custom` | none | Missing | Add custom MCP save. |
| `importMcpConfig` | `/api/settings/mcp-presets/import` | none | Missing | Add import flow. |
| `updateMcpServerTools` | `/api/settings/mcp-presets/tools` | none | Missing | Add tools enablement update. |
| `listSlashCommands` | `GET /api/commands` | none | Missing | Add command API and lifecycle filter. |
| `fetchSidebarState` | `GET /api/webui/sidebar-state` | none | Missing | Add sidebar state endpoint. |
| `updateSidebarState` | `/api/webui/sidebar-state/update?state=...` | none | Missing | Add sidebar state persistence. |
| `updateSettings` | `/api/settings/update` | none | Missing | Add core settings save. |
| `createModelConfiguration` | `/api/settings/model-configurations/create` | none | Missing | Add model preset creation. |
| `updateModelConfiguration` | `/api/settings/model-configurations/update` | none | Missing | Add model preset update. |
| `updateProviderSettings` | `/api/settings/provider/update` | none | Missing | Add provider settings update. |
| `loginProviderOAuth` | `/api/settings/provider/oauth-login` | none | Missing | Add OAuth trigger state. |
| `logoutProviderOAuth` | `/api/settings/provider/oauth-logout` | none | Missing | Add OAuth logout state. |
| `updateWebSearchSettings` | `/api/settings/web-search/update` | none | Missing | Add browser section save. |
| `updateNetworkSafetySettings` | `/api/settings/network-safety/update` | none | Missing | Add advanced safety save. |
| `updateImageGenerationSettings` | `/api/settings/image-generation/update` | none | Missing | Add image settings save. |
| `updateTranscriptionSettings` | `/api/settings/transcription/update` | none | Missing | Add voice settings save. |

## WebSocket Coverage

| WebSocket item | WebUI source | Flutter source | Status | Gap / next action |
| --- | --- | --- | --- | --- |
| Outbound `new_chat` | `types.ts`, `NanobotClient.createChat` | `NanobotWsClient.newChat` | Partial | Add workspace scope and robust error parity. |
| Outbound `attach` | `types.ts`, `NanobotClient.attach` | `NanobotWsClient.attach` | Partial | Add pending inbound replay and reconnect reattach parity. |
| Outbound `message` | `types.ts`, `NanobotClient.sendMessage` | `NanobotWsClient.sendMessage` | Partial | Add media, image generation, cli apps, MCP presets, workspace scope, turn ID. |
| Outbound `fork_chat` | `types.ts`, `NanobotClient.forkChat` | none | Missing | Add fork API and UI action. |
| Outbound `set_workspace_scope` | `types.ts`, `NanobotClient.setWorkspaceScope` | none | Missing | Add workspace controls and frame. |
| Outbound `transcribe_audio` | `types.ts`, `NanobotClient.transcribeAudio` | none | Missing | Add voice recorder and pending transcription handling. |
| Inbound `ready` | `types.ts` | parsed and selected chat update | Partial | Preserve `client_id` and socket ready chat semantics. |
| Inbound `attached` | `types.ts` | parsed and pending new chat completion | Partial | Same basic behavior; missing pending inbound flush. |
| Inbound `message` | `types.ts` | text only | Partial | Preserve kind, media, tool events, latency, source, agent UI, turn metadata. |
| Inbound `file_edit` | `types.ts` | event kind only | Partial | Preserve edits payload. |
| Inbound `delta` | `types.ts` | parsed text | Partial | Preserve stream ID and turn metadata. |
| Inbound `stream_end` | `types.ts` | event kind and optional text ignored | Partial | Preserve text/stream ID and flush pending events. |
| Inbound `reasoning_delta` | `types.ts` | parsed text | Partial | Preserve stream ID and turn metadata. |
| Inbound `reasoning_end` | `types.ts` | event kind only | Partial | Preserve stream ID and finalize reasoning row. |
| Inbound `runtime_model_updated` | `types.ts` | model name only | Partial | Preserve model preset and provider badge state. |
| Inbound `turn_end` | `types.ts` | event kind only | Partial | Preserve latency, goal state, turn metadata. |
| Inbound `goal_status` | `types.ts` | status/startedAt | Partial | Add per-chat run status storage and fanout. |
| Inbound `goal_state` | `types.ts` | event kind only | Missing | Parse and store goal state payload. |
| Inbound `session_updated` | `types.ts` | refresh all sessions | Partial | Respect metadata/thread scope and workspace scope. |
| Inbound `transcription_result` | `types.ts` | none | Missing | Add event kind and pending request resolution. |
| Inbound `transcription_error` | `types.ts` | none | Missing | Add event kind and pending request rejection. |
| Inbound `error` | `types.ts` | generic detail/reason | Partial | Add structured workspace rejection and pending new chat rejection. |
| Reconnect/backoff/reauth | `NanobotClient` | none | Missing | Add reconnect loop and token refresh before expiry. |
| Message too big close code | `NanobotClient.onclose` | none | Missing | Map close code `1009` to user-visible error. |

## Responsive and Interaction Coverage

| WebUI item | WebUI source | Flutter source | Status | Gap / next action |
| --- | --- | --- | --- | --- |
| Mobile sidebar sheet | `App.tsx`, `Sheet` | `Drawer` | Partial | Match WebUI sheet width, open behavior, and contained action menus. |
| Wide sidebar | `App.tsx`, `Sidebar.tsx` | fixed side panel when wide | Partial | Add collapsed rail, persisted width/open state, grouped sessions. |
| Thread viewport keyboard handling | `ThreadViewport.tsx`, `ThreadComposer.tsx` | basic `Scaffold` layout | Unverified | Requires Android soft-keyboard UI dump and likely layout fixes. |
| Bottom-anchored list | `ThreadMessages.tsx` | reversed `ListView.builder` | Partial | Basic anchor exists; missing older-page load and scroll preservation after canonical refresh. |
| Desktop entry fallback | adaptive strategy docs | `adaptive_layout_policy.dart` only | Partial | Policy exists; presentation has no separate shell entries. |
| Text overflow controls | WebUI Tailwind layout constraints | Flutter widgets | Unverified | Must verify on phone portrait/landscape with screenshots/UI dump. |

## Current Test Coverage

| Test file | Coverage | Status | Gap / next action |
| --- | --- | --- | --- |
| `test/adaptive_layout_policy_test.dart` | width classification | Partial | Does not cover shell fallback behavior. |
| `test/android_manifest_test.dart` | Android HTTP cleartext config | Implemented | Keep as regression protection for real gateway. |
| `test/app_config_test.dart` | app config store/controller | Partial | Does not cover full WebUI settings. |
| `test/nanobot_domain_test.dart` | bootstrap/session/message/event parsing basics | Partial | Needs protocol DTO tests for all HTTP/WS payloads. |

There are no Flutter widget tests for WebUI parity surfaces, no controller
tests for session/sidebar/settings state, and no integration test harness for
real gateway flows.

## True-Device Verification Matrix

| Flow | Required evidence | Current evidence | Status |
| --- | --- | --- | --- |
| Fresh install or cleared app launch | `adb shell pm clear`, `flutter run`, screenshot/UI dump | Previous minimal-client run existed before this audit | Unverified for parity |
| Bootstrap/auth | Log showing `/webui/bootstrap` success against `192.168.200.149:8765` | Previous minimal-client run existed before this audit | Unverified for parity |
| Session list | Screenshot/UI dump showing sessions and metadata | Previous minimal-client screenshot existed before this audit | Partial |
| New chat | Device run showing `new_chat` and attached session | Previous minimal-client run existed before this audit | Partial |
| Existing chat attach | Device run selecting existing session and loading thread | Previous minimal-client run existed before this audit | Partial |
| Streaming reply | Logs/screenshot showing delta through turn end | Previous minimal-client run existed before this audit | Partial |
| Reasoning/activity reply | Prompt producing reasoning/tool activity and screenshot | none in current audit | Missing |
| File edit/tool trace | Prompt producing file edit/tool events and screenshot | none | Missing |
| Sidebar search/pin/archive/title override | Device UI interactions and persisted state refresh | none | Missing |
| File/media preview | Device UI interaction with file/media attachment | none | Missing |
| Settings overview | Device screenshot and `GET /api/settings` log | none | Missing |
| Models/provider section | Device screenshot, provider model list log | none | Missing |
| Apps section | Device screenshot, CLI app catalog log | none | Missing |
| Automations section | Device screenshot, non-destructive action log | none | Missing |
| Skills section | Device screenshot, skill detail log | none | Missing |
| MCP section | Device screenshot, preset list log | none | Missing |
| Workspace scope rejection | Device action causing rejection and visible error | none | Missing |
| Reconnect/token refresh | Device log showing reconnect and reattach | none | Missing |
| Phone portrait | Screenshot/UI dump | previous minimal-client screenshot existed before this audit | Partial |
| Phone landscape | Screenshot/UI dump after rotation | none | Missing |

## Phase 2 Recommendations

1. Split `features/nanobot` into protocol/data/domain/application/presentation
   subdirectories before adding more surfaces.
2. Add typed HTTP DTOs for every `webui/src/lib/api.ts` function, starting with
   settings/sidebar/workspaces/slash commands because they unblock shell and
   composer parity.
3. Replace `NanobotEvent` with a typed WebSocket envelope model that preserves
   all WebUI fields, including media, tool events, file edits, latency, source,
   turn metadata, goal state, transcription events, and structured errors.
4. Refactor `NanobotWsClient` to match WebUI client behavior: multiplexed
   chat subscriptions, pending inbound buffers, reconnect/backoff, token
   refresh, pending new chat/fork/transcription request handling, run status
   fanout, and message-too-big close mapping.
5. Introduce separate controllers for connection, sessions/sidebar, thread,
   settings, workspace, apps, automations, and skills. Keep UI widgets consuming
   typed state only.
6. Implement core chat parity before settings actions: shell/sidebar,
   thread reducer, composer slash commands, activity rendering, file/media
   previews, and true-device verification.
7. Implement settings and management surfaces after core chat state is stable.
   Destructive live-gateway actions must be guarded by explicit user approval.
