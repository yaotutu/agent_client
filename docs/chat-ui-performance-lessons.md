# Chat UI Performance Lessons

本文件记录 2026-06-01 这次 IM 风格聊天页重构后的性能经验。后续改聊天 UI、消息同步、会话列表时优先遵守这些规则。

## 结论

聊天这种简单界面不应该卡。出现首次进入卡顿、滚动卡顿、键盘卡顿时，通常不是 Flutter 不行，而是我们把数据加载、状态订阅、消息渲染、布局重排写重了。

## 首屏加载

- 不要在用户点进聊天页后才做所有初始化。会话列表拿到 agents 后，应预热 chat controller 的本地缓存。
- 预加载应该预热数据和 provider state，不要离屏预渲染所有聊天页面 widget。预渲染全部窗口会把卡顿转移到列表页，并增加内存压力。
- 本地缓存可以并发预热；远端 session/history 同步应该后台串行或限流，避免打开 workspace 时同时打爆 backend。
- 如果本地没有缓存，远端还没返回，页面只能显示轻量占位。不要用复杂骨架或整页重排掩盖网络等待。

## 消息列表

- 聊天列表必须天然锚定底部。用 `ListView.builder(reverse: true)`，让最新消息位于 `offset == 0`。
- 不要正序渲染后再 post-frame `jumpTo(maxScrollExtent)`。这会先构建顶部历史，再跳到底部，浪费首帧。
- 首屏只应该构建最近一屏消息。更早历史以后做向上滚动分页加载，不要参与首次渲染。
- 后端一次返回很多历史时，进入 UI state 前要截断到最近窗口，例如最近 50 条。不要把几百条消息一次性塞给聊天页。
- 普通消息 item 不需要 keep-alive。`ListView.builder` 可以关闭 `addAutomaticKeepAlives` 和 `addSemanticIndexes`，除非 item 内部确实有要保留的状态。
- item 应使用稳定 key，例如 message id，减少流式更新和列表变化时的元素错配。

## 消息气泡

- 普通文本必须走轻量 `Text`。不要让所有消息都走 `MarkdownBody`。
- 不要默认给每条消息套 `SelectionArea`。可选中文本和 Markdown 都会显著增加布局成本。
- 只有检测到 Markdown 语法、附件、代码块、链接等富文本内容时，才使用 Markdown 渲染器。
- `RepaintBoundary` 应放在消息 item 边界，隔离气泡重绘。不要把大范围列表或整个聊天页都包成一个重绘区。

## 数据同步

- 推荐语义是 cache-first + remote reconcile：
  - 先读 Drift 本地缓存，快速显示。
  - 后台拉 backend 最新历史。
  - 远端返回后替换当前 session 的本地缓存和 UI state。
  - 远端失败时保留本地缓存，不要清空聊天页。
- cache 必须以 `agentId + sessionId` 为作用域。清理当前 session 时不能误删其它 session。
- 会话列表预览只读缓存 preview provider，不要直接订阅 `chatControllerProvider(agentId).messages`。列表和聊天详情必须解耦。
- 发送消息、远端同步、缓存替换后，需要 invalidate 会话预览 provider，让左侧列表自然刷新。

## 并发和竞态

- 任何异步加载都可能晚回来。切 session、新建 session、发送消息时，应让旧加载失效，避免旧请求覆盖当前聊天页。
- 可使用 generation/token 模式：每次用户主动改变上下文时递增 token，异步返回后只允许当前 token 写 state。
- 预加载失败不能影响可见 workspace。后台 preload 应吞掉错误，真正打开聊天页时再显示必要错误。

## 键盘和布局

- 移动端聊天详情页不应让 `Scaffold` 默认 resize 整个页面。键盘弹出时只移动输入区或 chat panel 内部 padding。
- 键盘 inset 应在聊天面板内部平滑处理，避免消息列表、header、外层 shell 全量 relayout。
- 外层 shell 应有清晰的 `Scaffold` 边界，移动端详情页作为单独 route 可以有自己的 `Scaffold`。

## 测试要求

新增或修改聊天性能相关逻辑时，应补以下类型测试：

- 初始消息列表直接锚定最新消息，不能依赖 post-frame 跳滚动。
- 普通消息不构建 Markdown widget，富文本消息仍保留 Markdown 渲染。
- backend 返回大量历史时，只进入最近窗口。
- 本地缓存先显示，远端返回后替换。
- 远端失败时本地缓存保留。
- 切 session 后，旧的慢请求不能覆盖新 session。
- 键盘弹出时，聊天详情页高度不被整体压缩。

## 判断标准

如果用户描述“第一次点进去卡，第二次不卡”，优先检查 provider/data 是否在首次进入前预热。

如果用户描述“滚动卡”，优先检查消息 item 是否过重，尤其是 Markdown、SelectionArea、图片、附件、过大的 cache extent。

如果用户描述“键盘弹出卡”，优先检查是否触发整页 resize 和全树 relayout。
