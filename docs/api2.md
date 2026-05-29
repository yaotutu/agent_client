# Agent Control Protocol v1 — API Reference

Base URL: `http://{host}:9800`

## 通用约定

- 所有 JSON 字段使用 **camelCase**
- 所有请求/响应 `Content-Type: application/json`（SSE 除外）
- 请求体上限 2MB
- Session ID 为 UUID 字符串（由服务端生成）
- Agent 名称只允许字母、数字、连字符（`-`）、下划线（`_`）

---

## 错误格式

所有错误返回统一结构：

```json
{
  "error": {
    "message": "描述信息",
    "type": "invalid_request_error",
    "code": "validation_error"
  }
}
```

| HTTP 状态码 | error.type              |
| ----------- | ----------------------- |
| 400         | `invalid_request_error` |
| 404         | `not_found_error`       |
| 405         | `invalid_request_error` |
| 413         | `invalid_request_error` |
| 500         | `server_error`          |

---

## 端点总览

```
# ── 系统 ────────────────────────────────────
GET  /health                            # 服务健康检查
GET  /                                  # 列出所有 Agent

# ── Agent 生命周期 ──────────────────────────
POST /agents                            # 创建 Agent
GET  /agents                            # 列出所有 Agent（含健康状态）
GET  /agents/:name                      # 获取 Agent 详情 + AgentCard
DELETE /agents/:name                    # 销毁 Agent
POST /agents/:name/start               # 启动 Agent（tmux）
POST /agents/:name/stop                # 停止 Agent（tmux）
PUT  /agents/:name/soul                # 更新 SOUL.md

# ── 会话 ────────────────────────────────────
GET  /agents/:name/sessions            # 列出会话
POST /agents/:name/sessions            # 创建会话
GET  /agents/:name/sessions/:id/messages    # 获取消息历史
POST /agents/:name/sessions/:id/messages    # 发送消息（SSE 流式）
DELETE /agents/:name/sessions/:id           # 删除会话

# ── Agent 控制 ─────────────────────────────
POST /agents/:name/agent/stop          # 停止当前任务
GET  /agents/:name/agent/commands      # 斜杠命令列表
GET  /agents/:name/agent/settings      # 获取运行时设置
PATCH /agents/:name/agent/settings     # 更新设置

# ── 资源 ────────────────────────────────────
GET  /agents/:name/resources/tree      # 文件树
GET  /agents/:name/resources/search    # 搜索文件
GET  /agents/:name/resources/file      # 读取文件
PUT  /agents/:name/resources/file      # 写入文件

# ── Git ────────────────────────────────────
GET  /agents/:name/git/status          # Git 状态
GET  /agents/:name/git/diff            # Git diff
```

---

## 1. GET /health

服务健康检查，不依赖后端 agent。

**响应** `200`：

```json
{ "status": "ok" }
```

---

## 2. GET /

列出所有已注册的 Agent 及其运行状态和健康信息。

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

| 字段     | 说明                                                           |
| -------- | -------------------------------------------------------------- |
| `status` | `"running"` 或 `"stopped"`（是否在 tmux 中运行）               |
| `health` | `"healthy"` / `"unhealthy"` / `"unknown"`（仅 running 时检查） |

---

## 3. POST /agents

创建新 Agent。基于模板配置自动分配端口，生成 workspace 和 SOUL.md。

**请求体**：

```json
{
  "name": "code-reviewer",
  "description": "代码审查助手"
}
```

| 字段          | 类型   | 必填 | 说明                                     |
| ------------- | ------ | ---- | ---------------------------------------- |
| `name`        | string | 是   | Agent 名称，只能包含字母、数字、`-`、`_` |
| `description` | string | 否   | Agent 描述，写入 SOUL.md                 |

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

**说明**：创建后 Agent 处于 `stopped` 状态，需调用 `POST /agents/:name/start` 启动。

---

## 4. GET /agents/:name

获取 Agent 详细信息，包含 AgentCard（协议版本、能力列表、状态、模型等）。

**响应** `200`：

```json
{
  "name": "coder",
  "protocol": "agent-control/v1",
  "capabilities": ["sessions", "streaming", "reasoning", "goals", "commands", "settings", "workspace", "git"],
  "wsPort": 8760,
  "gatewayPort": 18760,
  "workspaceDir": "/path/to/workspace",
  "state": {
    "status": "idle",
    "defaultSessionId": "4ea15ddd-0fae-4b9a-8c5d-74594e0b1020",
    "health": "ok"
  },
  "model": "MiniMax-M2.7-highspeed",
  "provider": "minimax"
}
```

| 字段                     | 说明                                               |
| ------------------------ | -------------------------------------------------- |
| `state.status`           | Agent 状态：`"idle"` / `"running"` / `"error"`     |
| `state.defaultSessionId` | 默认会话 ID（首次创建会话后才有值）                |
| `state.health`           | 后端健康状态：`"ok"` / `"unhealthy"` / `"unknown"` |

---

## 5. DELETE /agents/:name

销毁 Agent：停止进程（若在运行）+ 删除配置文件和工作区。

**响应** `200`：

```json
{ "deleted": true, "name": "coder" }
```

---

## 6. POST /agents/:name/start

在 tmux 中启动 Agent 进程（`nanobot gateway --config <path>`）。

**响应** `202`：

```json
{ "accepted": true, "name": "coder" }
```

---

## 7. POST /agents/:name/stop

停止 Agent 进程（kill tmux session）。

**响应** `202`：

```json
{ "accepted": true, "name": "coder" }
```

---

## 8. PUT /agents/:name/soul

更新 Agent 的 SOUL.md（人格/规则文档）。

**请求体**：

```json
{
  "content": "新的规则内容",
  "mode": "append"
}
```

| 字段      | 类型   | 必填 | 说明                                                           |
| --------- | ------ | ---- | -------------------------------------------------------------- |
| `content` | string | 是   | 要写入的内容                                                   |
| `mode`    | string | 否   | `"append"`（默认，追加到用户规则区）或 `"replace"`（完整替换） |

**响应** `200`：

```json
{ "path": "/path/to/workspace/SOUL.md" }
```

---

## 9. GET /agents/:name/sessions

列出指定 Agent 的所有会话。

**响应** `200`：

```json
{
  "object": "list",
  "data": [
    {
      "key": "websocket:15038c43-...",
      "created_at": "2026-05-29T10:50:22.246119",
      "updated_at": "2026-05-29T10:50:41.644596",
      "title": "",
      "preview": "对话预览..."
    }
  ]
}
```

---

## 10. POST /agents/:name/sessions

创建新会话。

**响应** `201`：

```json
{ "sessionId": "15038c43-5c12-43d4-9e78-f7c2a45562ba" }
```

---

## 11. GET /agents/:name/sessions/:id/messages

获取指定会话的消息历史。

**响应** `200`：

```json
{
  "key": "websocket:15038c43-...",
  "messages": [
    {
      "role": "user",
      "content": "你好",
      "timestamp": "2026-05-29T10:50:22.322759"
    },
    {
      "role": "assistant",
      "content": "你好！",
      "timestamp": "2026-05-29T10:50:24.898771",
      "latency_ms": 2653
    }
  ]
}
```

---

## 12. POST /agents/:name/sessions/:id/messages

发送消息。支持 SSE 流式和非流式两种模式。

**请求体**：

```json
{
  "content": "帮我分析一下代码",
  "stream": true
}
```

| 字段      | 类型    | 必填 | 默认值 | 说明                  |
| --------- | ------- | ---- | ------ | --------------------- |
| `content` | string  | 是   | —      | 消息内容，不能为空    |
| `stream`  | boolean | 否   | `true` | 是否使用 SSE 流式返回 |

### 流式响应（`stream: true`）

`Content-Type: text/event-stream`

```
data: {"type":"goal_status","state":"running","startedAt":1780023022.32}

data: {"type":"reasoning","text":"思考中..."}

data: {"type":"reasoning_done"}

data: {"type":"text","text":"我来帮你分析"}

data: {"type":"progress","text":"正在执行命令..."}

data: {"type":"tool_hint","text":"搜索中","toolEvents":[...]}

data: {"type":"goal_status","state":"idle"}

data: {"type":"done","latencyMs":2653}

data: [DONE]
```

**SSE 事件类型**：

| type             | 说明                | 字段                                                  |
| ---------------- | ------------------- | ----------------------------------------------------- |
| `text`           | Agent 回复文本片段  | `text: string`                                        |
| `reasoning`      | Agent 推理/思考过程 | `text: string`                                        |
| `reasoning_done` | 推理结束            | 无额外字段                                            |
| `progress`       | 执行进度提示        | `text: string`                                        |
| `tool_hint`      | 工具调用提示        | `text: string`, `toolEvents: array\|null`             |
| `goal_status`    | 目标状态变化        | `state: "running"\|"idle"`, `startedAt: number\|null` |
| `goal_state`     | 目标详情            | `goalState: object`                                   |
| `stream_end`     | 流片段结束          | 无额外字段                                            |
| `done`           | **整个回复结束**    | `latencyMs: number\|null`, `goalState: object\|null`  |
| `error`          | 发生错误            | `message: string`                                     |

**对接要点**：
- `done` 或 `error` 是终止事件，之后一定跟 `data: [DONE]\n\n`
- 拼接所有 `text` 事件的 `text` 字段即为完整回复

### 非流式响应（`stream: false`）

```json
{
  "sessionId": "15038c43-...",
  "content": "完整回复文本",
  "latencyMs": 2653
}
```

---

## 13. DELETE /agents/:name/sessions/:id

删除指定会话。

**响应** `200`：

```json
{ "deleted": true }
```

---

## 14. POST /agents/:name/agent/stop

停止当前正在执行的任务。

**请求体**（可选）：

```json
{ "sessionId": "15038c43-..." }
```

**响应** `202`：

```json
{ "accepted": true }
```

---

## 15. GET /agents/:name/agent/commands

获取所有可用斜杠命令。

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

**对接要点**：客户端可将命令作为普通消息发送（`content` 设为 `/stop` 等）。

---

## 16. GET /agents/:name/agent/settings

获取 Agent 运行时设置。

**响应** `200`：

```json
{
  "agent": {
    "model": "MiniMax-M2.7-highspeed",
    "provider": "minimax",
    "has_api_key": true
  },
  "providers": [...],
  "web_search": {...},
  "runtime": { "config_path": "..." },
  "requires_restart": false
}
```

---

## 17. PATCH /agents/:name/agent/settings

更新 Agent 运行时设置（热更新）。

**请求体**：

```json
{
  "model": "glm-5-turbo",
  "provider": "zhipu"
}
```

| 字段       | 类型   | 必填 | 说明       |
| ---------- | ------ | ---- | ---------- |
| `model`    | string | 否   | 模型名称   |
| `provider` | string | 否   | 提供商名称 |

**响应** `200`：返回更新后的完整 settings（格式同 `GET`）。

---

## 18. GET /agents/:name/resources/tree

获取工作区文件树。

**查询参数**：

| 参数   | 默认值 | 说明                 |
| ------ | ------ | -------------------- |
| `path` | `"."`  | 相对工作区的目录路径 |

**响应** `200`：

```json
{
  "object": "resources.tree",
  "path": "memory",
  "children": [
    { "name": "MEMORY.md", "path": "memory/MEMORY.md", "type": "file" },
    { "name": "subdir", "path": "memory/subdir", "type": "directory" }
  ]
}
```

**说明**：`.git` 和 `node_modules` 被过滤。目录排前面，然后按名称排序。

---

## 19. GET /agents/:name/resources/search

搜索工作区文件。

**查询参数**：

| 参数          | 类型   | 必填 | 默认值 | 说明                       |
| ------------- | ------ | ---- | ------ | -------------------------- |
| `query` / `q` | string | 是   | —      | 搜索关键词（不区分大小写） |
| `path`        | string | 否   | `"."`  | 搜索的根目录               |
| `limit`       | number | 否   | `100`  | 最大结果数（上限 500）     |

**响应** `200`：

```json
{
  "object": "list",
  "query": "SOUL",
  "data": [
    { "path": "SOUL.md", "type": "file", "match": "name" },
    { "path": "AGENTS.md", "type": "file", "match": "content", "line": 5, "preview": "...匹配行前后文本..." }
  ]
}
```

---

## 20. GET /agents/:name/resources/file

读取工作区文件。

**查询参数**：

| 参数   | 必填 | 说明                 |
| ------ | ---- | -------------------- |
| `path` | 是   | 相对工作区的文件路径 |

**响应** `200`：

```json
{
  "object": "resources.file",
  "path": "SOUL.md",
  "size": 1024,
  "mtimeMs": 1779247644726.62,
  "content": "文件完整内容..."
}
```

**错误**：文件超过 1MB 返回 `413`。路径穿越返回 `403`。

---

## 21. PUT /agents/:name/resources/file

写入工作区文件。

**请求体**：

```json
{
  "path": "notes/todo.md",
  "content": "# Todo\n- item1\n"
}
```

**响应** `200`：

```json
{
  "object": "resources.file",
  "path": "notes/todo.md",
  "size": 18,
  "mtimeMs": 1780022748577.84
}
```

**说明**：父目录不存在时自动创建。content 超过 1MB 返回 `413`。

---

## 22. GET /agents/:name/git/status

获取 Git 仓库状态。

**响应** `200`：

```json
{
  "object": "git.status",
  "isRepo": true,
  "branch": "master",
  "upstream": null,
  "ahead": 0,
  "behind": 0,
  "clean": false,
  "data": [
    { "path": "src/index.js", "index": "M", "worktree": " ", "status": "M " }
  ]
}
```

---

## 23. GET /agents/:name/git/diff

获取 Git diff。

**查询参数**：

| 参数   | 默认值 | 说明           |
| ------ | ------ | -------------- |
| `path` | `"."`  | 要 diff 的路径 |

**响应** `200`：

```json
{
  "object": "git.diff",
  "isRepo": true,
  "path": ".",
  "diff": "diff --git a/src/index.js b/src/index.js\n..."
}
```

---

## 典型对接流程

```
1. GET /                                → 获取 Agent 列表
2. POST /agents                         → 创建新 Agent（如需要）
3. POST /agents/:name/start             → 启动 Agent
4. GET  /agents/:name                   → 获取 AgentCard，检查 defaultSessionId
5. 若 defaultSessionId 为 null:
   POST /agents/:name/sessions          → 创建会话
6. POST /agents/:name/sessions/:id/messages → 发送消息（stream: true），接收 SSE 事件
   - 拼接所有 type:"text" 事件          → 显示回复内容
   - 收到 type:"done"                    → 回复结束
7. 期间可随时调用:
   POST /agents/:name/agent/stop        → 中断任务
   GET  /agents/:name/agent/commands    → 可用命令
   GET  /agents/:name/resources/tree    → 浏览文件
   POST /agents/:name/stop              → 停止 Agent
   DELETE /agents/:name                 → 销毁 Agent
```

---

## 环境变量

| 变量                  | 默认值                           | 说明                 |
| --------------------- | -------------------------------- | -------------------- |
| `HOST`                | `0.0.0.0`                        | 监听地址             |
| `PORT`                | `9800`                           | 监听端口             |
| `AGENT_BASE_DIR`      | `<project>/agents`               | Agent 实例存储根目录 |
| `AGENT_REGISTRY_PATH` | `${BASE}/registry.json`          | 注册表文件路径       |
| `AGENT_TEMPLATE_PATH` | `<project>/template/config.json` | 模板配置路径         |
| `MAX_FILE_BYTES`      | `1048576`                        | 文件读写上限         |
,