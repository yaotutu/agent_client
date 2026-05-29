# Agent Control Protocol v1 — API Reference

Base URL: `http://{host}:9800`

---

## 目录

- [通用约定](#通用约定)
- [错误格式](#错误格式)
- [端点总览](#端点总览)
- [系统](#1-get-health)
- [Agent 生命周期](#agent-生命周期)
- [会话管理](#会话管理)
- [Agent 控制](#agent-控制)
- [资源管理](#资源管理)
- [Git 操作](#git-操作)
- [环境变量](#环境变量)
- [典型对接流程](#典型对接流程)
- [SSE 事件参考](#sse-事件参考)

---

## 通用约定

| 约定         | 说明                                                                       |
| ------------ | -------------------------------------------------------------------------- |
| JSON 字段    | 全部使用 **camelCase**                                                     |
| Content-Type | `application/json`（SSE 端点除外）                                         |
| 请求体上限   | **2 MB**（`2,097,152 bytes`）                                              |
| Session ID   | UUID v4 字符串，由服务端生成（例：`a15470e7-c342-410a-9961-a4bdf91cd492`） |
| Agent 名称   | 仅允许字母、数字、连字符（`-`）、下划线（`_`），长度 1-64                  |
| 字符编码     | UTF-8                                                                      |
| 时间格式     | ISO 8601（例：`2026-05-29T10:50:22.246119`）                               |

---

## 错误格式

所有错误返回统一 JSON 结构：

```json
{
  "error": {
    "message": "描述信息",
    "type": "invalid_request_error",
    "code": "validation_error"
  }
}
```

**HTTP 状态码与 error.type 映射**：

| HTTP 状态码 | error.type              | 触发场景                             |
| ----------- | ----------------------- | ------------------------------------ |
| `400`       | `invalid_request_error` | 参数缺失、格式错误、JSON 解析失败    |
| `403`       | `server_error`          | 路径穿越（文件操作）                 |
| `404`       | `not_found_error`       | Agent 或 Session 不存在              |
| `405`       | `invalid_request_error` | HTTP 方法不允许                      |
| `413`       | `invalid_request_error` | 请求体/文件内容超过大小限制          |
| `500`       | `server_error`          | 服务端内部错误（nanobot 连接失败等） |

---

## 端点总览

```
# ── 系统 ────────────────────────────────────────────────
GET    /health                              # 1. 服务健康检查
GET    /                                    # 2. 列出所有 Agent（含运行状态）

# ── Agent 生命周期 ──────────────────────────────────────
POST   /agents                              # 3. 创建 Agent
GET    /agents                              # 4. 列出所有 Agent（含运行状态）
GET    /agents/:name                        # 5. 获取 Agent 详情
DELETE /agents/:name                        # 6. 销毁 Agent
POST   /agents/:name/start                  # 7. 启动 Agent
POST   /agents/:name/stop                   # 8. 停止 Agent
PUT    /agents/:name/soul                   # 9. 更新 SOUL.md

# ── 会话管理 ────────────────────────────────────────────
GET    /agents/:name/sessions               # 10. 列出会话
POST   /agents/:name/sessions               # 11. 创建新会话
POST   /agents/:name/sessions/:id/attach    # 12. 恢复旧会话
GET    /agents/:name/sessions/:id/messages  # 13. 获取消息历史
POST   /agents/:name/sessions/:id/messages  # 14. 发送消息（SSE 流式）
DELETE /agents/:name/sessions/:id           # 15. 删除会话

# ── Agent 控制 ──────────────────────────────────────────
POST   /agents/:name/agent/stop             # 16. 停止当前任务
GET    /agents/:name/agent/commands         # 17. 获取斜杠命令列表
GET    /agents/:name/agent/settings         # 18. 获取运行时设置
PATCH  /agents/:name/agent/settings         # 19. 更新运行时设置

# ── 资源管理 ────────────────────────────────────────────
GET    /agents/:name/resources/tree         # 20. 获取文件树
GET    /agents/:name/resources/search       # 21. 搜索文件
GET    /agents/:name/resources/file         # 22. 读取文件
PUT    /agents/:name/resources/file         # 23. 写入文件

# ── Git 操作 ────────────────────────────────────────────
GET    /agents/:name/git/status             # 24. Git 状态
GET    /agents/:name/git/diff               # 25. Git diff
```

---

## 系统端点

### 1. GET /health

服务健康检查。不依赖任何 Agent 后端，可用于负载均衡器或监控探针。

**请求**：无参数。

**响应** `200`：

```json
{ "status": "ok" }
```

---

### 2. GET /

列出所有已注册的 Agent 及其运行状态。包含每个 Agent 的健康检查结果。

**请求**：无参数。

**响应** `200`：

```json
{
  "object": "list",
  "data": [
    {
      "name": "coder",
      "wsPort": 8760,
      "gatewayPort": 18760,
      "workspaceDir": "/path/to/agents/coder/workspace",
      "model": "MiniMax-M2.7-highspeed",
      "provider": "minimax",
      "status": "running",
      "health": "healthy"
    },
    {
      "name": "reviewer",
      "wsPort": 8761,
      "gatewayPort": 18761,
      "workspaceDir": "/path/to/agents/reviewer/workspace",
      "model": "MiniMax-M2.7-highspeed",
      "provider": "minimax",
      "status": "stopped",
      "health": "unknown"
    }
  ]
}
```

**字段说明**：

| 字段           | 类型   | 说明                                                             |
| -------------- | ------ | ---------------------------------------------------------------- |
| `name`         | string | Agent 唯一标识名                                                 |
| `wsPort`       | number | WebSocket 端口（Agent 内部通信）                                 |
| `gatewayPort`  | number | HTTP Gateway 端口（Agent REST API）                              |
| `workspaceDir` | string | Agent 工作区绝对路径                                             |
| `model`        | string | 当前使用的模型名称                                               |
| `provider`     | string | 模型提供商                                                       |
| `status`       | string | `"running"` 或 `"stopped"`（tmux 进程是否存在）                  |
| `health`       | string | `"healthy"` / `"unhealthy"` / `"unknown"`（仅 `running` 时检查） |

---

## Agent 生命周期

### 3. POST /agents

创建新的 Agent。基于模板配置自动分配端口，生成 workspace 目录和 SOUL.md。

**请求体**：

```json
{
  "name": "code-reviewer",
  "description": "代码审查助手"
}
```

| 字段          | 类型   | 必填   | 说明                                          |
| ------------- | ------ | ------ | --------------------------------------------- |
| `name`        | string | **是** | Agent 名称，仅允许 `[a-zA-Z0-9_-]`，长度 1-64 |
| `description` | string | 否     | Agent 描述，写入 SOUL.md 的用户规则区         |

**响应** `201`：

```json
{
  "name": "code-reviewer",
  "wsPort": 8762,
  "gatewayPort": 18762,
  "configPath": "/path/to/agents/code-reviewer/config.json",
  "workspaceDir": "/path/to/agents/code-reviewer/workspace",
  "model": "MiniMax-M2.7-highspeed",
  "provider": "minimax",
  "status": "stopped"
}
```

**注意事项**：
- 创建后 Agent 处于 **stopped** 状态，需要调用 `POST /agents/:name/start` 启动
- 端口从 8760 开始自动分配，范围 8760-8799（最多 40 个 Agent）
- 名称重复会返回 `400` 错误
- 端口耗尽时会返回 `500` 错误

---

### 4. GET /agents

列出所有 Agent。功能与 `GET /` 相同，返回格式一致。

**响应** `200`：同 [GET /](#2-get-)

---

### 5. GET /agents/:name

获取单个 Agent 的详细信息，包含 AgentCard（协议版本、能力列表、运行状态、模型等）。

**路径参数**：

| 参数   | 说明       |
| ------ | ---------- |
| `name` | Agent 名称 |

**响应** `200`：

```json
{
  "name": "coder",
  "protocol": "agent-control/v1",
  "capabilities": [
    "sessions",
    "streaming",
    "reasoning",
    "goals",
    "commands",
    "settings",
    "workspace",
    "git"
  ],
  "wsPort": 8760,
  "gatewayPort": 18760,
  "workspaceDir": "/path/to/workspace",
  "state": {
    "status": "idle",
    "defaultSessionId": "4ea15ddd-0fae-4b9a-8c5d-74594e0b1020",
    "health": "healthy"
  },
  "model": "MiniMax-M2.7-highspeed",
  "provider": "minimax"
}
```

**字段说明**：

| 字段                     | 类型         | 说明                                                    |
| ------------------------ | ------------ | ------------------------------------------------------- |
| `protocol`               | string       | 协议版本，固定 `"agent-control/v1"`                     |
| `capabilities`           | string[]     | Agent 支持的能力列表                                    |
| `state.status`           | string       | Agent 运行状态：`"idle"` / `"running"` / `"error"`      |
| `state.defaultSessionId` | string\|null | 默认会话 ID，首次创建会话后才有值                       |
| `state.health`           | string       | 后端健康状态：`"healthy"` / `"unhealthy"` / `"unknown"` |

**错误**：

| 状态码 | 说明         |
| ------ | ------------ |
| `404`  | Agent 不存在 |

---

### 6. DELETE /agents/:name

销毁 Agent。会依次执行：停止进程（若在运行）→ 断开连接 → 删除配置文件 → 删除工作区目录。

**路径参数**：

| 参数   | 说明       |
| ------ | ---------- |
| `name` | Agent 名称 |

**响应** `200`：

```json
{ "deleted": true, "name": "coder" }
```

**注意事项**：
- 此操作**不可逆**，Agent 的所有数据（工作区文件、SOUL.md、会话历史）将被永久删除
- 若 Agent 正在运行，会先自动停止

---

### 7. POST /agents/:name/start

在 tmux 会话中启动 Agent 进程。命令为 `NANOBOT_MAX_CONCURRENT_REQUESTS=10 nanobot gateway --config <configPath>`。

**路径参数**：

| 参数   | 说明       |
| ------ | ---------- |
| `name` | Agent 名称 |

**响应** `202`：

```json
{ "accepted": true, "name": "coder" }
```

**注意事项**：
- 返回 `202` 表示启动请求已接受，进程正在启动中
- Agent 完全就绪通常需要 **5-15 秒**，建议通过轮询 `GET /agents/:name` 检查 `state.health === "healthy"` 确认就绪
- 若 Agent 已在运行，会返回 `500`（tmux session 已存在）

---

### 8. POST /agents/:name/stop

停止 Agent 进程（关闭 tmux 会话）。进程停止后 WebSocket 连接断开，但 Agent 注册信息保留。

**路径参数**：

| 参数   | 说明       |
| ------ | ---------- |
| `name` | Agent 名称 |

**响应** `202`：

```json
{ "accepted": true, "name": "coder" }
```

**注意事项**：
- 停止后 Agent 可以通过 `POST /agents/:name/start` 重新启动
- 进程中的会话上下文会丢失，但有历史记录的会话可通过 `attach` 恢复
- 若 Agent 未在运行，操作仍然成功（幂等）

---

### 9. PUT /agents/:name/soul

更新 Agent 的 SOUL.md（人格/规则配置文档）。SOUL.md 分为系统上下文区和用户规则区两部分。

**路径参数**：

| 参数   | 说明       |
| ------ | ---------- |
| `name` | Agent 名称 |

**请求体**：

```json
{
  "content": "你是一个代码审查助手，需要关注以下方面：\n1. 代码风格\n2. 性能问题\n3. 安全漏洞",
  "mode": "append"
}
```

| 字段      | 类型   | 必填   | 默认值     | 说明                                                                  |
| --------- | ------ | ------ | ---------- | --------------------------------------------------------------------- |
| `content` | string | **是** | —          | 要写入的内容                                                          |
| `mode`    | string | 否     | `"append"` | `"append"` = 追加到用户规则区末尾；`"replace"` = 完整替换整个 SOUL.md |

**响应** `200`：

```json
{ "path": "SOUL.md" }
```

**注意事项**：
- `append` 模式：在 SOUL.md 的用户规则区末尾追加内容，不影响系统上下文
- `replace` 模式：完整替换 SOUL.md 文件，需自行保证内容格式正确
- SOUL.md 更新后不需要重启 Agent，下次对话自动生效

---

## 会话管理

### 10. GET /agents/:name/sessions

列出指定 Agent 的所有会话（仅包含有历史消息记录的会话）。

**路径参数**：

| 参数   | 说明       |
| ------ | ---------- |
| `name` | Agent 名称 |

**响应** `200`：

```json
{
  "object": "list",
  "data": [
    {
      "key": "websocket:15038c43-5c12-43d4-9e78-f7c2a45562ba",
      "created_at": "2026-05-29T10:50:22.246119",
      "updated_at": "2026-05-29T10:50:41.644596",
      "title": "",
      "preview": "你好 → 你好！有什么可以帮你的吗？"
    }
  ]
}
```

**字段说明**：

| 字段         | 类型   | 说明                                     |
| ------------ | ------ | ---------------------------------------- |
| `key`        | string | 会话内部键，格式 `websocket:{sessionId}` |
| `created_at` | string | 创建时间（ISO 8601）                     |
| `updated_at` | string | 最后更新时间（ISO 8601）                 |
| `title`      | string | 会话标题（可能为空）                     |
| `preview`    | string | 最近消息的预览摘要                       |

**重要说明**：
- 仅返回**有历史记录的会话**（即至少发送过一条消息的会话）
- 通过 `POST /agents/:name/sessions` 创建的新会话在发送第一条消息前不会出现在此列表中
- 这是因为 nanobot 采用懒持久化策略：`new_chat` 仅在内存中创建订阅，首次消息交互后才写入磁盘

---

### 11. POST /agents/:name/sessions

为 Agent 创建一个新的对话会话。

**路径参数**：

| 参数   | 说明       |
| ------ | ---------- |
| `name` | Agent 名称 |

**请求体**：无（空请求体或不发送请求体均可）。

**响应** `201`：

```json
{
  "sessionId": "15038c43-5c12-43d4-9e78-f7c2a45562ba"
}
```

**注意事项**：
- 单个 Agent 支持同时创建多个会话，最多 **10 个**并发 LLM 请求
- 新创建的会话在发送第一条消息前不会出现在 `GET /sessions` 列表中
- 如果 Agent 的 WebSocket 未连接，此接口会自动建立连接（可能耗时几秒）

---

### 12. POST /agents/:name/sessions/:id/attach

恢复一个已有的会话。nanobot 从磁盘加载该会话的历史消息，使 Agent 拥有完整的对话上下文。

**路径参数**：

| 参数   | 说明               |
| ------ | ------------------ |
| `name` | Agent 名称         |
| `id`   | Session ID（UUID） |

**请求体**：无。

**响应** `200`：

```json
{
  "sessionId": "15038c43-5c12-43d4-9e78-f7c2a45562ba",
  "attached": true
}
```

**使用场景**：
- **服务重启后恢复**：Agent 进程重启后，原会话的内存状态丢失，通过 `attach` 可以从磁盘恢复历史
- **切换会话**：在多个已有会话之间切换，恢复上下文后继续对话
- **跨设备恢复**：在不同客户端上恢复同一会话

**对接要点**：
1. 先调用 `GET /agents/:name/sessions` 获取可用的会话列表
2. 从返回的 `key` 字段中提取 Session ID（去掉 `websocket:` 前缀）
3. 调用此接口 attach 后，即可通过 `POST .../messages` 继续对话，Agent 将拥有完整历史上下文
4. 同一 Agent 可以同时 attach 多个会话并发工作

**错误**：

| 状态码 | 说明                              |
| ------ | --------------------------------- |
| `404`  | Agent 不存在                      |
| `500`  | 会话不存在或 attach 超时（10 秒） |

---

### 13. GET /agents/:name/sessions/:id/messages

获取指定会话的消息历史。返回该会话中所有已持久化的消息。

**路径参数**：

| 参数   | 说明               |
| ------ | ------------------ |
| `name` | Agent 名称         |
| `id`   | Session ID（UUID） |

**响应** `200`：

```json
{
  "key": "websocket:15038c43-5c12-43d4-9e78-f7c2a45562ba",
  "messages": [
    {
      "role": "user",
      "content": "你好",
      "timestamp": "2026-05-29T10:50:22.322759"
    },
    {
      "role": "assistant",
      "content": "你好！有什么可以帮你的吗？",
      "timestamp": "2026-05-29T10:50:24.898771",
      "latency_ms": 2653
    }
  ]
}
```

**字段说明**：

| 字段                    | 类型              | 说明                                            |
| ----------------------- | ----------------- | ----------------------------------------------- |
| `key`                   | string            | 会话内部键                                      |
| `messages[].role`       | string            | 消息角色：`"user"` 或 `"assistant"`             |
| `messages[].content`    | string            | 消息文本内容                                    |
| `messages[].timestamp`  | string            | 消息时间（ISO 8601）                            |
| `messages[].latency_ms` | number\|undefined | 仅 assistant 消息有此字段，表示响应耗时（毫秒） |

---

### 14. POST /agents/:name/sessions/:id/messages

向指定会话发送消息。支持 **SSE 流式**和**非流式**两种模式。

**路径参数**：

| 参数   | 说明               |
| ------ | ------------------ |
| `name` | Agent 名称         |
| `id`   | Session ID（UUID） |

**请求体**：

```json
{
  "content": "帮我分析一下这段代码的性能问题",
  "stream": true
}
```

| 字段      | 类型    | 必填   | 默认值 | 说明                     |
| --------- | ------- | ------ | ------ | ------------------------ |
| `content` | string  | **是** | —      | 消息内容，不能为空字符串 |
| `stream`  | boolean | 否     | `true` | 是否使用 SSE 流式返回    |

#### 流式响应（`stream: true`）

`Content-Type: text/event-stream; charset=utf-8`

```
data: {"type":"goal_status","state":"running","startedAt":1780023022.32}

data: {"type":"reasoning","text":"让我分析一下..."}

data: {"type":"reasoning_done"}

data: {"type":"text","text":"我来帮你分析这段代码"}

data: {"type":"progress","text":"正在搜索相关文件..."}

data: {"type":"tool_hint","text":"执行命令: grep -r","toolEvents":[{"name":"grep","status":"running"}]}

data: {"type":"text","text":"性能瓶颈在第三行的循环..."}

data: {"type":"goal_status","state":"idle"}

data: {"type":"done","latencyMs":2653}

data: [DONE]
```

**SSE 事件类型详细说明**（完整参考见 [SSE 事件参考](#sse-事件参考)）：

| type             | 说明                                 | 终止事件 |
| ---------------- | ------------------------------------ | -------- |
| `text`           | Agent 回复的文本片段，需拼接         | 否       |
| `reasoning`      | Agent 推理/思考过程文本              | 否       |
| `reasoning_done` | 推理阶段结束                         | 否       |
| `progress`       | 执行进度提示（如"正在搜索文件"）     | 否       |
| `tool_hint`      | 工具调用提示（如命令执行）           | 否       |
| `goal_status`    | 目标状态变化                         | 否       |
| `goal_state`     | 目标详细信息                         | 否       |
| `stream_end`     | 一个流片段结束（Agent 可能产生多段） | 否       |
| `done`           | **整个回复完成**                     | **是**   |
| `error`          | 发生错误                             | **是**   |

**关键对接要点**：
1. **终止信号**：收到 `done` 或 `error` 后，紧接着一定会有 `data: [DONE]\n\n`，此时关闭 SSE 连接
2. **回复拼接**：将所有 `type: "text"` 事件的 `text` 字段按顺序拼接即为完整回复
3. **超时机制**：Agent 最长响应时间为 **10 分钟**（600 秒），超时后返回 `error` 事件
4. **并发限制**：同一 Session 同一时间只能处理一个请求（发送消息时 Session 处于 busy 状态）

#### 非流式响应（`stream: false`）

`Content-Type: application/json`

```json
{
  "sessionId": "15038c43-5c12-43d4-9e78-f7c2a45562ba",
  "content": "我来帮你分析这段代码的性能问题。性能瓶颈在第三行的循环...",
  "latencyMs": 2653
}
```

| 字段        | 类型         | 说明                          |
| ----------- | ------------ | ----------------------------- |
| `sessionId` | string       | 会话 ID                       |
| `content`   | string       | 完整回复文本                  |
| `latencyMs` | number\|null | 响应耗时（毫秒），可能为 null |

---

### 15. DELETE /agents/:name/sessions/:id

删除指定会话。删除后会话的历史消息从磁盘永久移除。

**路径参数**：

| 参数   | 说明               |
| ------ | ------------------ |
| `name` | Agent 名称         |
| `id`   | Session ID（UUID） |

**响应** `200`：

```json
{ "deleted": true }
```

---

## Agent 控制

### 16. POST /agents/:name/agent/stop

停止当前正在执行的任务。Agent 会中断正在进行的 LLM 调用或工具执行。

**路径参数**：

| 参数   | 说明       |
| ------ | ---------- |
| `name` | Agent 名称 |

**请求体**（可选）：

```json
{ "sessionId": "15038c43-..." }
```

| 字段        | 类型   | 必填 | 说明                                 |
| ----------- | ------ | ---- | ------------------------------------ |
| `sessionId` | string | 否   | 指定要停止的会话，不传则使用默认会话 |

**响应** `202`：

```json
{ "accepted": true }
```

---

### 17. GET /agents/:name/agent/commands

获取 Agent 支持的所有斜杠命令列表。

**路径参数**：

| 参数   | 说明       |
| ------ | ---------- |
| `name` | Agent 名称 |

**响应** `200`：

```json
{
  "object": "list",
  "data": [
    {
      "command": "/stop",
      "title": "Stop current task",
      "description": "Cancel the active agent turn.",
      "icon": "square",
      "argHint": ""
    }
  ]
}
```

**对接要点**：
- 斜杠命令可以作为普通消息发送（将 `content` 设为命令字符串如 `/stop`）
- 客户端可在 UI 中渲染命令列表供用户快速选择

---

### 18. GET /agents/:name/agent/settings

获取 Agent 的运行时设置。

**路径参数**：

| 参数   | 说明       |
| ------ | ---------- |
| `name` | Agent 名称 |

**响应** `200`：

```json
{
  "agent": {
    "model": "MiniMax-M2.7-highspeed",
    "provider": "minimax",
    "has_api_key": true
  },
  "providers": [
    {
      "name": "minimax",
      "models": ["MiniMax-M2.7-highspeed"]
    },
    {
      "name": "zhipu",
      "models": ["glm-4-flash"]
    }
  ],
  "web_search": {
    "enabled": false
  },
  "runtime": {
    "config_path": "/path/to/config.json"
  },
  "requires_restart": false
}
```

---

### 19. PATCH /agents/:name/agent/settings

更新 Agent 运行时设置。支持热更新模型和提供商，无需重启 Agent。

**路径参数**：

| 参数   | 说明       |
| ------ | ---------- |
| `name` | Agent 名称 |

**请求体**：

```json
{
  "model": "glm-4-flash",
  "provider": "zhipu"
}
```

| 字段       | 类型   | 必填 | 说明               |
| ---------- | ------ | ---- | ------------------ |
| `model`    | string | 否   | 要切换的模型名称   |
| `provider` | string | 否   | 要切换的提供商名称 |

**响应** `200`：返回更新后的完整 settings（格式同 `GET /agents/:name/agent/settings`）。

---

## 资源管理

### 20. GET /agents/:name/resources/tree

获取 Agent 工作区的文件树结构。

**路径参数**：

| 参数   | 说明       |
| ------ | ---------- |
| `name` | Agent 名称 |

**查询参数**：

| 参数   | 类型   | 必填 | 默认值 | 说明                   |
| ------ | ------ | ---- | ------ | ---------------------- |
| `path` | string | 否   | `"."`  | 相对于工作区的目录路径 |

**响应** `200`：

```json
{
  "object": "resources.tree",
  "path": "memory",
  "children": [
    {
      "name": "MEMORY.md",
      "path": "memory/MEMORY.md",
      "type": "file"
    },
    {
      "name": "subdir",
      "path": "memory/subdir",
      "type": "directory"
    }
  ]
}
```

**注意事项**：
- `.git` 和 `node_modules` 目录会被自动过滤，不显示
- 排序规则：目录在前，文件在后；同类型按名称字母排序
- 路径穿越（如 `path=../etc`）会返回 `403`

---

### 21. GET /agents/:name/resources/search

搜索 Agent 工作区中的文件。支持文件名匹配和文件内容匹配。

**路径参数**：

| 参数   | 说明       |
| ------ | ---------- |
| `name` | Agent 名称 |

**查询参数**：

| 参数           | 类型   | 必填   | 默认值 | 说明                       |
| -------------- | ------ | ------ | ------ | -------------------------- |
| `query` 或 `q` | string | **是** | —      | 搜索关键词（不区分大小写） |
| `path`         | string | 否     | `"."`  | 搜索的根目录               |
| `limit`        | number | 否     | `100`  | 最大返回结果数（上限 500） |

**响应** `200`：

```json
{
  "object": "list",
  "query": "SOUL",
  "data": [
    {
      "path": "SOUL.md",
      "type": "file",
      "match": "name"
    },
    {
      "path": "AGENTS.md",
      "type": "file",
      "match": "content",
      "line": 5,
      "preview": "...包含 SOUL 关键字的文本片段..."
    }
  ]
}
```

**字段说明**：

| 字段      | 类型   | 说明                                                     |
| --------- | ------ | -------------------------------------------------------- |
| `match`   | string | `"name"` = 文件名匹配；`"content"` = 文件内容匹配        |
| `line`    | number | 仅 `content` 匹配有此字段，匹配所在行号                  |
| `preview` | string | 仅 `content` 匹配有此字段，匹配位置前后约 240 字符的预览 |

---

### 22. GET /agents/:name/resources/file

读取 Agent 工作区中的文件内容。

**路径参数**：

| 参数   | 说明       |
| ------ | ---------- |
| `name` | Agent 名称 |

**查询参数**：

| 参数   | 类型   | 必填   | 说明                   |
| ------ | ------ | ------ | ---------------------- |
| `path` | string | **是** | 相对于工作区的文件路径 |

**响应** `200`：

```json
{
  "object": "resources.file",
  "path": "SOUL.md",
  "size": 1024,
  "mtimeMs": 1779247644726.62,
  "content": "# Agent Personality\n\n你是一个代码助手..."
}
```

**字段说明**：

| 字段      | 类型   | 说明                       |
| --------- | ------ | -------------------------- |
| `size`    | number | 文件大小（字节）           |
| `mtimeMs` | number | 最后修改时间（毫秒时间戳） |
| `content` | string | 文件完整内容（UTF-8 文本） |

**错误**：

| 状态码 | 说明                                   |
| ------ | -------------------------------------- |
| `400`  | `path` 参数缺失或不是文件              |
| `403`  | 路径穿越（如 `path=../../etc/passwd`） |
| `413`  | 文件超过 1 MB 大小限制                 |

---

### 23. PUT /agents/:name/resources/file

向 Agent 工作区写入文件。如果父目录不存在会自动创建。

**路径参数**：

| 参数   | 说明       |
| ------ | ---------- |
| `name` | Agent 名称 |

**请求体**：

```json
{
  "path": "notes/todo.md",
  "content": "# Todo\n- item1\n- item2\n"
}
```

| 字段      | 类型   | 必填   | 说明                     |
| --------- | ------ | ------ | ------------------------ |
| `path`    | string | **是** | 相对于工作区的文件路径   |
| `content` | string | **是** | 文件内容（UTF-8 字符串） |

**响应** `200`：

```json
{
  "object": "resources.file",
  "path": "notes/todo.md",
  "size": 24,
  "mtimeMs": 1780022748577.84
}
```

**错误**：

| 状态码 | 说明                                  |
| ------ | ------------------------------------- |
| `400`  | `path` 或 `content` 参数缺失/类型错误 |
| `403`  | 路径穿越                              |
| `413`  | 内容超过 1 MB 大小限制                |

---

## Git 操作

### 24. GET /agents/:name/git/status

获取 Agent 工作区的 Git 仓库状态。

**路径参数**：

| 参数   | 说明       |
| ------ | ---------- |
| `name` | Agent 名称 |

**响应** `200`：

```json
{
  "object": "git.status",
  "isRepo": true,
  "branch": "master",
  "upstream": "origin/master",
  "ahead": 2,
  "behind": 0,
  "clean": false,
  "data": [
    {
      "path": "src/index.js",
      "from": null,
      "index": "M",
      "worktree": " ",
      "status": "M "
    },
    {
      "path": "src/new-file.js",
      "from": null,
      "index": "A",
      "worktree": " ",
      "status": "A "
    },
    {
      "path": "src/old-file.js",
      "from": "src/renamed.js",
      "index": "R",
      "worktree": " ",
      "status": "R "
    }
  ]
}
```

**字段说明**：

| 字段              | 类型         | 说明                                  |
| ----------------- | ------------ | ------------------------------------- |
| `isRepo`          | boolean      | 是否是 Git 仓库                       |
| `branch`          | string\|null | 当前分支名（detached HEAD 时为 null） |
| `upstream`        | string\|null | 上游跟踪分支                          |
| `ahead`           | number       | 领先上游的提交数                      |
| `behind`          | number       | 落后上游的提交数                      |
| `clean`           | boolean      | 工作区是否有未提交的变更              |
| `data[].index`    | string       | 暂存区状态标记                        |
| `data[].worktree` | string       | 工作区状态标记                        |
| `data[].status`   | string       | 完整的两字符状态码                    |

**Git 状态码参考**：

| 状态码 | 说明                                    |
| ------ | --------------------------------------- |
| `M `   | 暂存区已修改                            |
| ` M`   | 工作区已修改（未暂存）                  |
| `A `   | 新增文件（已暂存）                      |
| `D `   | 已删除（已暂存）                        |
| `R `   | 已重命名（已暂存），`from` 字段有原路径 |
| `??`   | 未跟踪文件                              |

---

### 25. GET /agents/:name/git/diff

获取 Agent 工作区的 Git diff 输出。

**路径参数**：

| 参数   | 说明       |
| ------ | ---------- |
| `name` | Agent 名称 |

**查询参数**：

| 参数   | 类型   | 必填 | 默认值 | 说明                     |
| ------ | ------ | ---- | ------ | ------------------------ |
| `path` | string | 否   | `"."`  | 要 diff 的文件或目录路径 |

**响应** `200`：

```json
{
  "object": "git.diff",
  "isRepo": true,
  "path": ".",
  "diff": "diff --git a/src/index.js b/src/index.js\nindex abc1234..def5678 100644\n--- a/src/index.js\n+++ b/src/index.js\n@@ -1,5 +1,6 @@\n import http from 'node:http';\n+import fs from 'node:fs';\n ..."
}
```

---

## SSE 事件参考

发送消息（`stream: true`）时，服务端通过 SSE 协议推送以下事件。所有事件格式为：

```
data: {JSON对象}\n\n
```

流结束时发送：

```
data: [DONE]\n\n
```

### 事件类型一览

| type             | 触发时机            | 字段                                                  | 客户端处理建议                        |
| ---------------- | ------------------- | ----------------------------------------------------- | ------------------------------------- |
| `text`           | Agent 输出文本片段  | `text: string`                                        | 拼接到回复缓冲区，实时渲染            |
| `reasoning`      | Agent 思考/推理过程 | `text: string`                                        | 可折叠显示，用于展示 Agent 的思考过程 |
| `reasoning_done` | 推理阶段结束        | 无                                                    | 隐藏推理区                            |
| `progress`       | 执行进度提示        | `text: string`                                        | 显示为状态栏/进度提示                 |
| `tool_hint`      | 工具调用提示        | `text: string`, `toolEvents: array\|null`             | 显示工具调用信息（如正在执行的命令）  |
| `goal_status`    | 目标状态变化        | `state: "running"\|"idle"`, `startedAt: number\|null` | 显示/隐藏"正在工作"状态指示器         |
| `goal_state`     | 目标详情            | `goalState: object`                                   | 可用于展示任务详情                    |
| `stream_end`     | 一个流片段结束      | 无                                                    | 中间事件，Agent 可能产生多段输出      |
| `done`           | **整个回复完成**    | `latencyMs: number\|null`, `goalState: object\|null`  | 标记回复结束，隐藏 loading 状态       |
| `error`          | 发生错误            | `message: string`                                     | 显示错误信息给用户                    |

### 典型 SSE 事件序列

```
1. goal_status (running)     → 显示 "正在思考..."
2. reasoning                 → 显示推理过程（可选）
3. reasoning_done            → 推理结束
4. text (多次)               → 逐字渲染回复内容
5. progress (可选)           → 显示进度提示
6. tool_hint (可选)          → 显示工具调用信息
7. text (继续)               → 继续输出
8. goal_status (idle)        → 隐藏 "正在思考"
9. done                      → 回复完成，显示耗时
10. [DONE]                   → 关闭 SSE 连接
```

### 客户端 SSE 对接示例

```javascript
const response = await fetch(
  'http://localhost:9800/agents/coder/sessions/SESSION_ID/messages',
  {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ content: '你好', stream: true }),
  }
);

const reader = response.body
  .pipeThrough(new TextDecoderStream())
  .getReader();

let reply = '';
let buffer = '';

while (true) {
  const { done, value } = await reader.read();
  if (done) break;

  buffer += value;
  const lines = buffer.split('\n');
  buffer = lines.pop(); // 保留未完成的行

  for (const line of lines) {
    if (!line.startsWith('data: ')) continue;
    const payload = line.slice(6).trim();

    if (payload === '[DONE]') {
      console.log('回复完成:', reply);
      return;
    }

    const event = JSON.parse(payload);

    switch (event.type) {
      case 'text':
        reply += event.text;
        // 更新 UI 显示
        break;
      case 'done':
        console.log('耗时:', event.latencyMs, 'ms');
        break;
      case 'error':
        console.error('错误:', event.message);
        break;
      case 'reasoning':
        // 显示思考过程
        break;
      case 'progress':
        // 显示进度提示
        break;
    }
  }
}
```

---

## 环境变量

| 变量                  | 默认值                           | 说明                                     |
| --------------------- | -------------------------------- | ---------------------------------------- |
| `HOST`                | `0.0.0.0`                        | 服务监听地址                             |
| `PORT`                | `9800`                           | 服务监听端口                             |
| `MAX_FILE_BYTES`      | `1048576`                        | 文件读写大小上限（1 MB）                 |
| `AGENT_BASE_DIR`      | 项目根目录                       | Agent 实例存储根目录（含 agents 子目录） |
| `AGENT_REGISTRY_PATH` | `${BASE}/registry.json`          | Agent 注册表文件路径                     |
| `AGENT_TEMPLATE_PATH` | `<project>/template/config.json` | Agent 创建模板配置路径                   |
| `NANOBOT_CLIENT_ID`   | `agent-wrap`                     | WebSocket 客户端标识                     |

---

## 典型对接流程

### 场景一：首次使用 — 创建并对话

```bash
# 1. 创建 Agent
curl -X POST http://localhost:9800/agents \
  -H 'Content-Type: application/json' \
  -d '{"name":"my-agent","description":"我的助手"}'
# → { "name": "my-agent", "wsPort": 8760, ..., "status": "stopped" }

# 2. 启动 Agent
curl -X POST http://localhost:9800/agents/my-agent/start
# → { "accepted": true, "name": "my-agent" }

# 3. 等待就绪（建议轮询，间隔 2 秒）
curl http://localhost:9800/agents/my-agent
# → { "state": { "health": "healthy", ... } }

# 4. 创建会话
curl -X POST http://localhost:9800/agents/my-agent/sessions
# → { "sessionId": "abc123-..." }

# 5. 发送消息（流式）
curl -N http://localhost:9800/agents/my-agent/sessions/abc123-.../messages \
  -H 'Content-Type: application/json' \
  -d '{"content":"你好","stream":true}'
# → SSE 事件流

# 6. 发送消息（非流式）
curl -X POST http://localhost:9800/agents/my-agent/sessions/abc123-.../messages \
  -H 'Content-Type: application/json' \
  -d '{"content":"你好","stream":false}'
# → { "sessionId": "abc123-...", "content": "你好！有什么可以帮你的吗？", "latencyMs": 2653 }
```

### 场景二：恢复历史会话

```bash
# 1. 列出已有会话
curl http://localhost:9800/agents/my-agent/sessions
# → { "data": [{ "key": "websocket:abc123-...", "preview": "..." }] }

# 2. 从 key 提取 Session ID（去掉 websocket: 前缀）
# Session ID = "abc123-..."

# 3. Attach 到旧会话
curl -X POST http://localhost:9800/agents/my-agent/sessions/abc123-.../attach
# → { "sessionId": "abc123-...", "attached": true }

# 4. 继续对话（Agent 拥有完整历史上下文）
curl -N http://localhost:9800/agents/my-agent/sessions/abc123-.../messages \
  -H 'Content-Type: application/json' \
  -d '{"content":"我刚才说了什么？","stream":true}'
# → Agent 会回忆之前的对话内容
```

### 场景三：多会话并发

```bash
# 创建多个会话
curl -X POST http://localhost:9800/agents/my-agent/sessions  # → S1
curl -X POST http://localhost:9800/agents/my-agent/sessions  # → S2
curl -X POST http://localhost:9800/agents/my-agent/sessions  # → S3

# 同时向多个会话发消息（最多 10 个并发 LLM 请求）
curl -N .../sessions/S1/messages -d '{"content":"问题1"}' &
curl -N .../sessions/S2/messages -d '{"content":"问题2"}' &
curl -N .../sessions/S3/messages -d '{"content":"问题3"}' &
wait
```

### 场景四：完整生命周期

```bash
# 创建 → 启动 → 使用 → 停止 → 销毁
curl -X POST http://localhost:9800/agents -d '{"name":"temp"}'
curl -X POST http://localhost:9800/agents/temp/start
# ... 使用 Agent ...
curl -X POST http://localhost:9800/agents/temp/stop
curl -X DELETE http://localhost:9800/agents/temp
```

---

## 常见问题

### Q: 创建 Agent 后立即可用吗？

不可以。创建后 Agent 处于 `stopped` 状态，需要调用 `POST /agents/:name/start` 启动，并等待 5-15 秒直到健康检查通过。

### Q: Session 列表为空？

新创建的会话在发送第一条消息前不会持久化到磁盘，因此不会出现在 `GET /sessions` 列表中。这是正常的懒持久化行为。

### Q: Agent 重启后会话还在吗？

有历史记录的会话（发送过消息的）会保留在磁盘上，可以通过 `attach` 恢复。仅在内存中创建但未发送过消息的会话会丢失。

### Q: 同一个 Agent 可以开几个并发会话？

最多支持 **10 个**并发的 LLM 请求。可以创建更多会话，但同时进行的请求不超过 10 个。

### Q: 文件大小限制是多少？

读写文件均限制为 **1 MB**（`MAX_FILE_BYTES` 环境变量，默认 1,048,576 字节）。请求体限制为 2 MB。

### Q: Agent 的 SOUL.md 是什么？

SOUL.md 是 Agent 的人格配置文档，定义了 Agent 的行为规则和角色设定。创建 Agent 时会生成默认版本，可通过 `PUT /agents/:name/soul` 更新。
