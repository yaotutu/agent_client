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
                  Expanded(child: ChatPanel(agentId: agent.id)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChatDetailHeader extends StatelessWidget {
  const _ChatDetailHeader({
    required this.agent,
    required this.showBackButton,
    this.onBack,
  });

  final Agent agent;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
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
          _AgentAvatar(agent: agent, selected: true, radius: 19),
          const SizedBox(width: 12),
          Expanded(
            child: KeyedSubtree(
              key: const Key('current-agent-title'),
              child: Text(
                agent.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppThemeTokens.text,
                ),
              ),
            ),
          ),
          IconButton(
            key: const Key('agent-detail-files-button'),
            tooltip: 'Files',
            onPressed: () => _showAgentToolDialog(
              context,
              title: 'Files',
              child: FilesPanel(agentId: agent.id),
            ),
            icon: const Icon(Icons.folder_outlined),
          ),
          IconButton(
            key: const Key('agent-detail-tasks-button'),
            tooltip: 'Tasks',
            onPressed: () => _showAgentToolDialog(
              context,
              title: 'Tasks',
              child: TasksPanel(agentId: agent.id),
            ),
            icon: const Icon(Icons.fact_check_outlined),
          ),
        ],
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
                        const Icon(Icons.star, color: Color(0xFFF7B731)),
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
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppThemeTokens.text,
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
                                  fontWeight: FontWeight.w800,
                                  color: AppThemeTokens.text,
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

void _showAgentToolDialog(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  final size = MediaQuery.sizeOf(context);
  showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(18),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeTokens.radius),
        ),
        child: SizedBox(
          key: const Key('agent-tool-dialog'),
          width: math.min(size.width - 36, 760),
          height: math.min(size.height - 48, 680),
          child: Column(
            children: [
              Container(
                height: 54,
                padding: const EdgeInsets.only(left: 18, right: 6),
                decoration: const BoxDecoration(
                  color: AppThemeTokens.panel,
                  border: Border(
                    bottom: BorderSide(color: AppThemeTokens.border),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      );
    },
  );
}
