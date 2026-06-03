part of '../agent_workspace_page.dart';

class _MobileAgentWorkspace extends ConsumerWidget {
  const _MobileAgentWorkspace({
    required this.agents,
    required this.currentAgentId,
  });

  final AsyncValue<List<Agent>> agents;
  final String currentAgentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableAgents = _agentsFrom(agents);
    final selectedAgent =
        _selectedAgent(availableAgents, currentAgentId) ??
        fallbackAgent(currentAgentId);

    return KeyedSubtree(
      key: const Key('agent-mobile-workspace'),
      child: _MobileConversationPage(
        agents: agents,
        currentAgentId: selectedAgent.id,
      ),
    );
  }
}

class _MobileConversationPage extends ConsumerWidget {
  const _MobileConversationPage({
    required this.agents,
    required this.currentAgentId,
  });

  final AsyncValue<List<Agent>> agents;
  final String currentAgentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KeyedSubtree(
      key: const Key('agent-mobile-conversation-list'),
      child: _SharedConversationListPane(
        agents: agents,
        currentAgentId: currentAgentId,
        everyoneSelected: false,
        showSelection: false,
        showSettingsButton: true,
        onSelectEveryone: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const _MobileEveryoneDetailPage(),
            ),
          );
        },
        onSelectAgent: (agent) async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _MobileAgentChatPage(agent: agent),
            ),
          );
          if (!context.mounted) {
            return;
          }
          ref.read(currentAgentIdProvider.notifier).selectAgent(agent.id);
        },
      ),
    );
  }
}

class _MobileAgentChatPage extends StatelessWidget {
  const _MobileAgentChatPage({required this.agent});

  final Agent agent;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _lightStatusBarStyle,
      child: Scaffold(
        backgroundColor: _chatHeaderColor,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          bottom: false,
          child: _SharedAgentChatDetail(
            agent: agent,
            chatPanel: MobileChatPanel(agent: agent),
            showBackButton: true,
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}

class _MobileEveryoneDetailPage extends StatelessWidget {
  const _MobileEveryoneDetailPage();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _lightStatusBarStyle,
      child: Scaffold(
        backgroundColor: _chatHeaderColor,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          bottom: false,
          child: _SharedEveryoneDetail(
            showBackButton: true,
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}
