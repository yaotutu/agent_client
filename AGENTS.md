# AGENTS.md

本文件给后续在本仓库工作的 coding agent 使用。目标是保持架构边界清晰，方便后续接入多种 agent backend。

## 项目定位

这是一个 Flutter 客户端。当前第一个 backend adapter 是 Agent Control v1，但业务层不应绑定 Agent Control。后续接入其他 agent 时，应新增 adapter/provider 分发，而不是把新协议逻辑写进 UI 或 controller。

## 架构原则

- `presentation/` 和 `application/` 只能依赖 feature domain model 与 repository port。
- 不要在 UI、controller、domain 层直接 import `features/agent_control/*`。
- `features/agent_control` 只作为 Agent Control backend adapter，负责 Dio、SSE、协议 DTO、错误解析。
- 新 backend 需要实现已有 port，而不是改现有 UI 状态模型：
  - `AgentRegistryRepository`
  - `AgentChatRepository`
  - `AgentResourcesRepository`
  - `AgentSettingsRepository`
  - `AgentGitRepository`
- `Agent` 有 `backendId` 和 `backendAgentId`。需要跨 backend 路由时使用这两个字段，不要假设 `agent.id` 就是某个协议内部 ID。
- Chat cache 必须按 `agentId + sessionId` 作用域处理；创建新 session 不应清掉其他 session 的历史。

## 关键目录

```text
lib/
  app/                         # App shell, theme
  core/                        # Config, network providers
  data/local/                  # Drift database
  features/
    agent_control/             # Agent Control adapter only
    agents/                    # Agent registry/domain/navigation
    chat/                      # Chat state, session state, stream events
    files/                     # Workspace file browsing/editing
    git/                       # Git status/diff port
    settings/                  # Commands/settings port
    tasks/                     # Derived live task/activity panel
```

## 重要边界

- `agent_control_models.dart` 是协议 DTO 集中区。不要把里面的 DTO 暴露给 UI。
- `agent_control_chat_services.dart` 是 Agent Control chat adapter 的内部拆分：
  - readiness
  - sessions
  - history
  - streaming turns
- `chat_event.dart` 使用 typed `ChatActivity`，不要重新引入 loosely typed `Map payload` 作为业务事件。
- `chat_cache_provider.dart` 的生产默认实现是 Drift；`InMemoryChatCacheStore` 只用于测试和 provider override。

## 新增 Backend 的做法

1. 新建 backend 专属 data adapter，例如 `features/<backend_name>/data/...`。
2. 实现需要的 repository port。
3. 在 provider 层按 `backendId` 路由到对应实现。
4. 把新协议 DTO 映射成现有 domain model。
5. 给 adapter 行为补单元测试；不要只测 UI。

## 开发命令

```sh
flutter analyze
flutter test
```

如果 Flutter 平台缓存导致普通测试受阻，可先使用：

```sh
flutter test --no-pub
```

## 提交前检查

- `flutter analyze` 必须通过。
- `flutter test` 或 `flutter test --no-pub` 必须通过，并说明使用了哪一个。
- `git diff --check` 不应有 whitespace error。
- 不要提交无关平台生成文件、缓存文件或格式化噪音。

## 常见陷阱

- 不要为了快速展示命令补全而让 `ChatInputBar` 依赖 Agent Control 的 `AgentCommand` DTO；使用 `AgentCommandItem`。
- 不要让 files/git/settings feature 返回 Agent Control DTO；使用各自 domain model。
- 不要在 `startNewSession` 时清空整个 agent 的缓存。
- 不要把 malformed SSE 当作崩溃处理；协议边界应容错并让上层忽略 unknown event。
