part of 'agent_workspace_page.dart';

class _AgentChatDetail extends StatelessWidget {
  const _AgentChatDetail({
    required this.agent,
    this.showBackButton = false,
    this.onBack,
  });

  final Agent agent;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('agent-chat-detail'),
      color: AppThemeTokens.workspace,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(constraints.maxWidth, _chatSurfaceMaxWidth);
          return Center(
            child: SizedBox(
              key: const Key('agent-chat-detail-frame'),
              width: width,
              height: constraints.maxHeight,
              child: Column(
                children: [
                  _ChatDetailHeader(
                    agent: agent,
                    showBackButton: showBackButton,
                    onBack: onBack,
                  ),
                  Expanded(child: ChatPanel(agent: agent)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChatDetailHeader extends ConsumerWidget {
  const _ChatDetailHeader({
    required this.agent,
    required this.showBackButton,
    this.onBack,
  });

  final Agent agent;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTyping = ref.watch(
      chatControllerProvider(agent.id).select((state) => state.isStreaming),
    );

    return Container(
      key: const Key('agent-chat-header'),
      height: 56,
      decoration: const BoxDecoration(
        color: _chatHeaderColor,
        border: Border(bottom: BorderSide(color: AppThemeTokens.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              key: const Key('agent-chat-back-button'),
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
          AgentAvatarView(agent: agent, selected: true, radius: 19),
          const SizedBox(width: 12),
          Expanded(
            child: KeyedSubtree(
              key: const Key('current-agent-title'),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      agent.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppThemeTokens.headingText,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  if (isTyping)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: SizedBox(
                        key: Key('chat-header-typing-indicator'),
                        width: 24,
                        height: 18,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: _HeaderTypingIndicator(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            key: const Key('agent-detail-button'),
            tooltip: 'Agent details',
            onPressed: () => openAgentDetailPage(context, agent),
            icon: const Icon(Icons.tune_outlined),
          ),
        ],
      ),
    );
  }
}

class _HeaderTypingIndicator extends StatelessWidget {
  const _HeaderTypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Assistant is typing',
      child: const Row(
        key: Key('chat-header-typing-dots'),
        mainAxisSize: MainAxisSize.min,
        children: [
          _HeaderTypingDot(),
          SizedBox(width: 4),
          _HeaderTypingDot(),
          SizedBox(width: 4),
          _HeaderTypingDot(),
        ],
      ),
    );
  }
}

class _HeaderTypingDot extends StatelessWidget {
  const _HeaderTypingDot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppThemeTokens.mutedText,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _EveryoneDetail extends StatelessWidget {
  const _EveryoneDetail({this.showBackButton = false, this.onBack});

  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('agent-everyone-detail'),
      color: AppThemeTokens.workspace,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(constraints.maxWidth, _chatSurfaceMaxWidth);
          return Center(
            child: SizedBox(
              key: const Key('agent-everyone-detail-frame'),
              width: width,
              height: constraints.maxHeight,
              child: Column(
                children: [
                  Container(
                    key: const Key('agent-everyone-header'),
                    height: 72,
                    decoration: const BoxDecoration(
                      color: _chatHeaderColor,
                      border: Border(
                        bottom: BorderSide(color: AppThemeTokens.border),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        if (showBackButton)
                          IconButton(
                            key: const Key('agent-chat-back-button'),
                            tooltip: 'Back',
                            onPressed: onBack,
                            icon: const Icon(Icons.arrow_back),
                          ),
                        const Icon(Icons.star, color: AppThemeTokens.accent),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Everyone',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppThemeTokens.headingText,
                                  letterSpacing: 0,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Team conversation',
                                style: TextStyle(
                                  color: AppThemeTokens.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: const Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.forum_outlined,
                                size: 44,
                                color: AppThemeTokens.brand,
                              ),
                              SizedBox(height: 14),
                              Text(
                                'Team chat is not connected yet',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppThemeTokens.headingText,
                                  letterSpacing: 0,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Everyone is reserved for future multi-agent conversations. Open an agent conversation to send messages today.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppThemeTokens.mutedText,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                      child: TextField(
                        key: const Key('everyone-readonly-input'),
                        enabled: false,
                        decoration: const InputDecoration(
                          hintText: 'Team chat is read-only for now',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
