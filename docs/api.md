# Agent Control Protocol v1 — API Reference

Base URL: `http://{host}:9800`

## 通用约定

- 所有 JSON 字段使用 **camelCase**
- 所有请求/响应 `Content-Type: application/json`（SSE 除外）
- 请求体上限 2MB
- Session ID 为 UUID 字符串（由服务端生成）

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

## 1. GET /

获取 AgentCard — agent 的完整描述信息。

**请求**：无参数

**响应** `200`：

```json
{
  "name": "nanobot",
  "protocol": "agent-control/v1",
  "capabilities": ["sessions", "streaming", "reasoning", "goals", "commands", "settings", "workspace", "git"],
  "state": {
    "status": "idle",
    "defaultSessionId": "4ea15ddd-0fae-4b9a-8c5d-74594e0b1020",
    "health": "ok"
  },
  "model": "MiniMax-M2.7-highspeed",
  "provider": "minimax",
  "workspace": "/path/to/workspace"
}
```

| 字段                     | 类型         | 说明                                           |
| ------------------------ | ------------ | ---------------------------------------------- |
| `name`                   | string       | Agent 名称                                     |
| `protocol`               | string       | 固定 `"agent-control/v1"`                      |
| `capabilities`           | string[]     | 支持的能力列表                                 |
| `state.status`           | string       | Agent 状态：`"idle"` / `"running"` / `"error"` |
| `state.defaultSessionId` | string\|null | 默认会话 ID（首次创建会话后才有值）            |
| `state.health`           | string       | 后端健康状态：`"ok"` / `"stopped"`             |
| `model`                  | string\|null | 当前模型名                                     |
| `provider`               | string\|null | 当前提供商                                     |
| `workspace`              | string       | 工作区绝对路径                                 |

**对接流程**：客户端启动后首先调用此接口，获取 `defaultSessionId`。若为 null，调用 `POST /sessions` 创建。

---

## 2. GET /health

简单健康检查，不依赖后端 agent。

**响应** `200`：

```json
{ "status": "ok" }
```

---

## 3. POST /sessions

创建新会话。

**请求**：无 body

**响应** `201`：

```json
{
  "sessionId": "15038c43-5c12-43d4-9e78-f7c2a45562ba"
}
```

**说明**：首次调用时会建立与 nanobot 的 WebSocket 连接，同时产生 `defaultSessionId`。

---

## 4. GET /sessions

列出所有会话。

**请求**：无参数

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
      "preview": "对话预览文本..."
    }
  ]
}
```

---

## 5. GET /sessions/:id/messages

获取指定会话的消息历史。

**路径参数**：

| 参数 | 说明               |
| ---- | ------------------ |
| `id` | Session ID（UUID） |

**响应** `200`：

```json
{
  "key": "websocket:15038c43-5c12-43d4-9e78-f7c2a45562ba",
  "created_at": "2026-05-29T10:50:22.246119",
  "updated_at": "2026-05-29T10:50:41.644596",
  "metadata": { "webui": true, "title": "..." },
  "messages": [
    {
      "role": "user",
      "content": "你好",
      "timestamp": "2026-05-29T10:50:22.322759"
    },
    {
      "role": "assistant",
      "content": "你好！有什么可以帮你的？",
      "timestamp": "2026-05-29T10:50:24.898771",
      "latency_ms": 2653
    }
  ]
}
```

---

## 6. POST /sessions/:id/messages

发送消息。支持 SSE 流式和非流式两种模式。

**路径参数**：

| 参数 | 说明               |
| ---- | ------------------ |
| `id` | Session ID（UUID） |

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

data: {"type":"goal_state","goalState":{"active":false}}

data: {"type":"done","latencyMs":2653}

data: [DONE]
```

**SSE 事件类型**：

| type             | 说明                               | 字段                                                  |
| ---------------- | ---------------------------------- | ----------------------------------------------------- |
| `text`           | Agent 回复文本片段                 | `text: string`                                        |
| `reasoning`      | Agent 推理/思考过程                | `text: string`                                        |
| `reasoning_done` | 推理结束                           | 无额外字段                                            |
| `progress`       | 执行进度提示                       | `text: string`                                        |
| `tool_hint`      | 工具调用提示                       | `text: string`, `toolEvents: array\|null`             |
| `goal_status`    | 目标状态变化                       | `state: "running"\|"idle"`, `startedAt: number\|null` |
| `goal_state`     | 目标详情                           | `goalState: object`                                   |
| `stream_end`     | 流片段结束（一次回复可能多个片段） | 无额外字段                                            |
| `done`           | **整个回复结束**                   | `latencyMs: number\|null`, `goalState: object\|null`  |
| `error`          | 发生错误                           | `message: string`                                     |

**对接要点**：
- `done` 或 `error` 是终止事件，之后一定跟 `data: [DONE]\n\n`，客户端应关闭连接
- 拼接所有 `text` 事件的 `text` 字段即为完整回复
- `reasoning` 可选展示为"思考过程"
- `progress` / `tool_hint` 可选展示为执行状态

### 非流式响应（`stream: false`）

`Content-Type: application/json`

```json
{
  "sessionId": "15038c43-5c12-43d4-9e78-f7c2a45562ba",
  "content": "完整回复文本",
  "latencyMs": 2653
}
```

---

## 7. DELETE /sessions/:id

删除指定会话。

**路径参数**：

| 参数 | 说明               |
| ---- | ------------------ |
| `id` | Session ID（UUID） |

**响应** `200`：

```json
{ "deleted": true }
```

---

## 8. POST /agent/stop

停止当前正在执行的任务。

**请求体**（可选）：

```json
{ "sessionId": "15038c43-..." }
```

| 字段        | 类型   | 必填 | 说明                       |
| ----------- | ------ | ---- | -------------------------- |
| `sessionId` | string | 否   | 指定会话，不传则用默认会话 |

**响应** `202`：

```json
{ "accepted": true }
```

---

## 9. GET /agent/commands

获取所有可用斜杠命令。

**响应** `200`：

```json
{
  "object": "list",
  "data": [
    {
      "command": "/stop",
      "title": "Stop current task",
      "description": "Cancel the active agent turn for this chat.",
      "icon": "square",
      "argHint": ""
    },
    {
      "command": "/model",
      "title": "Switch model preset",
      "description": "Show or switch the active model preset.",
      "icon": "brain",
      "argHint": "[preset]"
    }
  ]
}
```

| 字段          | 类型   | 说明                      |
| ------------- | ------ | ------------------------- |
| `command`     | string | 命令名（含 `/` 前缀）     |
| `title`       | string | 简短标题                  |
| `description` | string | 详细描述                  |
| `icon`        | string | 图标名（lucide icon）     |
| `argHint`     | string | 参数提示，如 `"[preset]"` |

**对接要点**：客户端可将命令作为普通消息发送（通过 `POST /sessions/:id/messages`，`content` 设为 `/stop` 等）。

---

## 10. GET /agent/settings

获取 agent 运行时设置。

**响应** `200`：

```json
{
  "agent": {
    "model": "MiniMax-M2.7-highspeed",
    "provider": "minimax",
    "resolved_provider": "minimax",
    "has_api_key": true
  },
  "providers": [
    {
      "name": "zhipu",
      "label": "Zhipu",
      "configured": true,
      "api_key_hint": "a51d••••xYY",
      "api_base": "https://open.bigmodel.cn/api/coding/paas/v4",
      "default_api_base": null
    }
  ],
  "web_search": {
    "provider": "duckduckgo",
    "api_key_hint": null,
    "base_url": null,
    "providers": [...]
  },
  "runtime": {
    "config_path": "/path/to/config.json"
  },
  "requires_restart": false
}
```

---

## 11. PATCH /agent/settings

更新 agent 运行时设置（热更新，无需重启）。

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

两个参数至少传一个。

**响应** `200`：返回更新后的完整 settings（格式同 `GET /agent/settings`）。

---

## 12. GET /resources/tree

获取工作区文件树。

**查询参数**：

| 参数   | 类型   | 默认值 | 说明                 |
| ------ | ------ | ------ | -------------------- |
| `path` | string | `"."`  | 相对工作区的目录路径 |

**响应** `200`：

```json
{
  "object": "resources.tree",
  "path": "memory",
  "children": [
    { "name": "MEMORY.md", "path": "memory/MEMORY.md", "type": "file" },
    { "name": "history.jsonl", "path": "memory/history.jsonl", "type": "file" },
    { "name": "subdir", "path": "memory/subdir", "type": "directory" }
  ]
}
```

| 字段              | 说明                                 |
| ----------------- | ------------------------------------ |
| `path`            | 当前目录路径（相对于工作区根）       |
| `children[].name` | 文件/目录名                          |
| `children[].path` | 相对路径                             |
| `children[].type` | `"file"` / `"directory"` / `"other"` |

**说明**：`.git` 和 `node_modules` 目录被过滤。目录排前面，然后按名称排序。

---

## 13. GET /resources/search

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
      "preview": "...匹配行前后文本..."
    }
  ]
}
```

| 字段      | 说明                                                 |
| --------- | ---------------------------------------------------- |
| `match`   | `"name"`（文件名匹配）或 `"content"`（文件内容匹配） |
| `line`    | 仅 content 匹配时返回，匹配所在行号                  |
| `preview` | 仅 content 匹配时返回，匹配位置前后约 240 字符       |

---

## 14. GET /resources/file

读取工作区文件。

**查询参数**：

| 参数   | 类型   | 必填 | 说明                 |
| ------ | ------ | ---- | -------------------- |
| `path` | string | 是   | 相对工作区的文件路径 |

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

**错误**：文件超过 `MAX_FILE_BYTES`（默认 1MB）返回 `413`。路径穿越返回 `403`。

---

## 15. PUT /resources/file

写入工作区文件。

**请求体**：

```json
{
  "path": "notes/todo.md",
  "content": "# Todo\n- item1\n"
}
```

| 字段      | 类型   | 必填 | 说明                 |
| --------- | ------ | ---- | -------------------- |
| `path`    | string | 是   | 相对工作区的文件路径 |
| `content` | string | 是   | 文件内容             |

**响应** `200`：

```json
{
  "object": "resources.file",
  "path": "notes/todo.md",
  "size": 18,
  "mtimeMs": 1780022748577.84
}
```

**说明**：父目录不存在时自动创建。content 超过 `MAX_FILE_BYTES` 返回 `413`。

---

## 16. GET /git/status

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
    {
      "path": "memory/history.jsonl",
      "from": null,
      "index": "?",
      "worktree": "?",
      "status": "??"
    },
    {
      "path": "src/index.js",
      "from": null,
      "index": "M",
      "worktree": " ",
      "status": "M "
    }
  ]
}
```

| 字段               | 说明                                                                              |
| ------------------ | --------------------------------------------------------------------------------- |
| `isRepo`           | 是否是 Git 仓库                                                                   |
| `branch`           | 当前分支名                                                                        |
| `upstream`         | 上游分支（可能为 null）                                                           |
| `ahead` / `behind` | 与上游的差异提交数                                                                |
| `clean`            | 工作区是否干净                                                                    |
| `data[].status`    | Git 状态码：`??`（新文件）、`M `（已暂存修改）、` M`（未暂存修改）、`D`（删除）等 |

---

## 17. GET /git/diff

获取 Git diff。

**查询参数**：

| 参数   | 类型   | 默认值 | 说明           |
| ------ | ------ | ------ | -------------- |
| `path` | string | `"."`  | 要 diff 的路径 |

**响应** `200`：

```json
{
  "object": "git.diff",
  "isRepo": true,
  "path": ".",
  "diff": "diff --git a/src/index.js b/src/index.js\n..."
}
```

| 字段   | 说明                             |
| ------ | -------------------------------- |
| `diff` | 原始 unified diff 输出（字符串） |

---

## 典型对接流程

```
1. GET /                           → 获取 AgentCard，得到 defaultSessionId
2. 若 defaultSessionId 为 null:
   POST /sessions                  → 创建会话，得到 sessionId
3. POST /sessions/:id/messages     → 发送消息（stream: true），接收 SSE 流式事件
   - 拼接所有 type:"text" 事件     → 显示回复内容
   - 收到 type:"done"              → 回复结束
4. 期间可随时调用:
   POST /agent/stop                → 中断当前任务
   GET /agent/commands             → 获取可用命令列表
   GET /resources/tree             → 浏览文件
   GET /resources/file             → 读取文件
```
