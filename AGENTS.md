# AGENTS.md

本文件给后续在本仓库工作的 coding agent 使用。目标是保持架构边界清晰，方便后续接入多种 agent backend。

## 文档查询约定

当用户询问库、框架、SDK、API、CLI 工具或云服务的用法时，使用 Context7 MCP 获取当前文档；即使是 React、Next.js、Prisma、Express、Tailwind、Django、Spring Boot 等常见项目，也不要只依赖已有记忆。适用范围包括 API 语法、配置、版本迁移、库相关调试、安装步骤和 CLI 用法。优先使用 Context7，而不是 web search。

不需要为重构、从零编写脚本、业务逻辑调试、代码审查或通用编程概念使用 Context7。

使用步骤：

1. 除非用户提供 `/org/project` 格式的精确 library ID，否则先用库名和用户问题调用 `resolve-library-id`。
2. 按精确名称、描述相关性、代码片段数量、来源声誉和 benchmark score 选择最佳匹配；如果结果不合适，换用别名或重述查询。
3. 用选定的 library ID 和用户完整问题调用 `query-docs`。
4. 基于获取到的文档回答。

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

## Chat UI 性能经验

聊天页性能约束记录在 `docs/chat-ui-performance-lessons.md`。改聊天页面前先读这份文档。核心原则：

- 首屏只渲染最近一屏消息，列表用底部锚定，不要正序渲染后再跳到底部。
- 普通文本消息走轻量 `Text`，不要默认走 Markdown 或 `SelectionArea`。
- 预加载数据和 provider state，不要预渲染所有聊天窗口 widget。
- 会话列表不要订阅 `chatControllerProvider(agentId).messages`，预览通过缓存 provider 解耦。
- 异步加载必须防止旧请求覆盖当前 session。

## Adaptive UI 策略

当前 UI 适配按 mobile first 规划，顺序是手机端、平板端、桌面端。桌面端在专门适配前必须复用平板布局和交互，不要提前引入桌面专属三栏、右键菜单、hover action 或快捷键入口。

- 统一策略记录在 `docs/superpowers/specs/2026-06-02-mobile-first-adaptive-ui-strategy.md`。
- 宽度阈值和 fallback 规则集中在 `lib/app/adaptive/adaptive_layout_policy.dart`。
- Adaptive UI 分三层：policy 层负责设备分类和 fallback，workspace shell 层选择页面结构，feature presentation 层只渲染自身内容。
- `AdaptiveDeviceClass` 表示设备分类；`WorkspaceLayoutMode` 表示当前实际布局；`WorkspaceInteractionMode` 表示当前实际交互。不要把这三个概念混成一个宽度判断。
- 当前映射规则是：`mobile -> mobile layout/interaction`，`tablet -> tablet layout/interaction`，`desktop -> tablet layout/interaction`。
- 桌面端虽然会被识别为 `desktop`，但 `usesDesktopEnhancements` 当前必须保持关闭；桌面专属三栏、右键菜单、hover action、快捷键入口都属于后续 desktop enhancement。
- presentation widget 应消费 adaptive policy，不要把新的 raw width breakpoint 散落在组件里；只有局部尺寸微调可以在已选 layout mode 内部处理。
- workspace shell 只根据 `WorkspaceLayoutMode` 选择 mobile 单列或 tablet shell；不要让 feature widget 自己决定整页结构。
- 交互差异只根据 `WorkspaceInteractionMode` 处理。后续把三个点菜单替换为桌面右键菜单时，应替换 action 的呈现方式，不要改业务 action 本身。
- 后续桌面增强应新增 desktop layout/interaction mode，而不是重写 mobile/tablet 行为。
- 改 adaptive policy 或 shell 结构时，必须补 widget/unit 测试，至少覆盖 phone、tablet、desktop-as-tablet fallback。

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
