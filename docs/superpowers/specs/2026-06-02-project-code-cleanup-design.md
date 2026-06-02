# Project Code Cleanup Design

## Goal

整理 Flutter 客户端代码结构，在不改变现有功能和用户可见行为的前提下，让代码更符合仓库的 backend adapter 边界，降低大文件维护成本，并补上必要验证。

## Current Context

- `flutter analyze` 当前无问题。
- 工作区已有一处用户改动：`AGENTS.md`。本次整理不修改或提交该文件。
- Agent Control 相关依赖目前集中出现在多个 feature 的 `data/` repository 实现中，例如 agents、files、settings、git、chat。
- 聊天 UI 有明确性能约束，整理聊天相关代码时必须遵守 `docs/chat-ui-performance-lessons.md`。

## Scope

本次整理包含：

- 将 Agent Control 协议 DTO、API client、协议映射实现收拢到 `features/agent_control/data`。
- 让 `presentation/` 和 `application/` 继续只依赖 feature domain model 与 repository port。
- 将各 feature 的 repository port 与默认 provider 保留在 feature 边界内，具体 Agent Control 实现通过 provider wiring 注入。
- 拆分明显过大的 UI/controller 文件，只处理职责已清楚、低风险的部分。
- 补充或调整 focused tests，证明 provider wiring、协议映射和拆分后的行为没有变化。

本次不包含：

- 不新增第二个 backend。
- 不重写 UI 视觉设计。
- 不改 Drift schema，除非验证过程中发现必须修复的结构性问题。
- 不做 dependency upgrade。

## Architecture

Feature 层继续暴露稳定的 repository port，例如：

- `AgentRegistryRepository`
- `AgentChatRepository`
- `AgentResourcesRepository`
- `AgentSettingsRepository`
- `AgentGitRepository`

Agent Control backend adapter 负责：

- 调用 `AgentControlApi`
- 消费 `agent_control_models.dart` 中的 DTO
- 将协议 DTO 映射为 feature domain model
- 提供各 repository port 的 Agent Control 实现

Provider wiring 需要满足：

- UI/controller 通过 feature repository provider 读取 port。
- feature provider 默认返回 Agent Control adapter 实现。
- 新 backend 后续可通过 backend routing/provider override 接入，不需要让 UI import 新协议。

## Component Cleanup

优先整理以下类型文件：

- 直接违反 adapter 边界的 repository 实现。
- 超过 500 行且包含多个明显私有 widget 或职责片段的 presentation 文件。
- controller 中可抽出为小型私有 helper、且不改变 state transition 的重复逻辑。

拆分原则：

- 保持文件名和目录符合现有 feature 结构。
- 私有 widget 拆出时仍使用 `part of` 或局部文件组织，避免扩大 public API。
- 不为了“看起来整齐”创建抽象；只有职责边界清楚时才拆。

## Data Flow

整理后数据流保持不变：

1. UI/controller 调用 feature repository port。
2. 默认 provider 注入 Agent Control adapter。
3. adapter 调用 `AgentControlApi`。
4. adapter 将 Agent Control DTO 映射成 feature domain model。
5. UI/controller 继续消费现有 domain model 和 state。

聊天缓存规则保持不变：

- cache scope 仍为 `agentId + sessionId`。
- 新 session 不清除其他 session 历史。
- cache-first + remote reconcile 语义保持不变。

## Error Handling

- 保留当前异常传播和用户可见错误文案。
- 协议边界继续容错 unknown/malformed SSE event。
- 重构过程中不改变 backend readiness、session、history、streaming turn 的语义。

## Testing And Verification

实现阶段必须执行：

- Focused tests：覆盖被移动或拆分的 repository/provider/widget/controller。
- `flutter analyze`
- `flutter test --no-pub`
- `git diff --check`

成功标准：

- Analyzer 无问题。
- 测试通过。
- 无 whitespace error。
- `presentation/` 与 `application/` 不直接 import `features/agent_control/*`。
- Agent Control DTO 不暴露给 UI。
- 用户已有 `AGENTS.md` 改动未被覆盖。
