import 'dart:async';
import 'dart:math' as math;

import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:agent_client/features/agents/application/agent_controller.dart';
import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:agent_client/features/chat/application/chat_conversation_preview_provider.dart';
import 'package:agent_client/features/chat/application/chat_preload_controller.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:agent_client/features/chat/presentation/chat_panel.dart';
import 'package:agent_client/features/files/presentation/files_panel.dart';
import 'package:agent_client/features/settings/presentation/app_settings_page.dart';
import 'package:agent_client/features/tasks/presentation/tasks_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'agent_workspace_chrome.dart';
part 'agent_workspace_conversation_list.dart';
part 'agent_workspace_detail.dart';

const _phoneMaxWidth = 600.0;
const _appRailWidth = 76.0;
const _conversationListWidth = 352.0;
const _tabletConversationListWidth = 312.0;
const _chatSurfaceMaxWidth = 1120.0;
const _conversationListColor = Color(0xFFF8FBFE);
const _chatHeaderColor = Color(0xFFFBFDFF);
const _conversationListStatusBarStyle = SystemUiOverlayStyle(
  statusBarColor: _conversationListColor,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
);
const _lightStatusBarStyle = SystemUiOverlayStyle(
  statusBarColor: _chatHeaderColor,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
);

class AgentWorkspacePage extends ConsumerStatefulWidget {
  const AgentWorkspacePage({super.key});

  @override
  ConsumerState<AgentWorkspacePage> createState() => _AgentWorkspacePageState();
}

class _AgentWorkspacePageState extends ConsumerState<AgentWorkspacePage> {
  var _showEveryone = false;
  var _preloadSignature = '';

  @override
  Widget build(BuildContext context) {
    final agents = ref.watch(agentsProvider);
    final currentAgentId = ref.watch(currentAgentIdProvider);
    if (agents case AsyncData(:final value)) {
      _scheduleChatPreload(value);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _conversationListStatusBarStyle,
      child: Scaffold(
        backgroundColor: _conversationListColor,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < _phoneMaxWidth) {
                return _MobileConversationPage(
                  agents: agents,
                  currentAgentId: currentAgentId,
                );
              }

              final availableAgents = _agentsFrom(agents);
              final selectedAgent =
                  _selectedAgent(availableAgents, currentAgentId) ??
                  fallbackAgent(currentAgentId);
              final effectiveAgentId = selectedAgent.id;
              final conversationWidth = constraints.maxWidth < 920
                  ? _tabletConversationListWidth
                  : _conversationListWidth;

              return Row(
                key: const Key('agent-im-shell'),
                children: [
                  const _AppRail(),
                  SizedBox(
                    width: conversationWidth,
                    child: _ConversationListPane(
                      agents: agents,
                      currentAgentId: effectiveAgentId,
                      everyoneSelected: _showEveryone,
                      showSettingsButton: false,
                      onSelectEveryone: () {
                        setState(() => _showEveryone = true);
                      },
                      onSelectAgent: (agent) {
                        setState(() => _showEveryone = false);
                        ref
                            .read(currentAgentIdProvider.notifier)
                            .selectAgent(agent.id);
                      },
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(
                    child: _showEveryone
                        ? const _EveryoneDetail()
                        : _AgentChatDetail(agent: selectedAgent),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _scheduleChatPreload(List<Agent> agents) {
    final agentIds = [
      for (final agent in agents)
        if (agent.id.trim().isNotEmpty) agent.id.trim(),
    ];
    final signature = agentIds.join('\u0001');
    if (signature.isEmpty || signature == _preloadSignature) {
      return;
    }
    _preloadSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        ref.read(chatPreloadControllerProvider).preloadAgents(agentIds),
      );
    });
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
    final availableAgents = _agentsFrom(agents);
    final selectedAgent =
        _selectedAgent(availableAgents, currentAgentId) ??
        fallbackAgent(currentAgentId);

    return KeyedSubtree(
      key: const Key('agent-mobile-conversation-list'),
      child: _ConversationListPane(
        agents: agents,
        currentAgentId: selectedAgent.id,
        everyoneSelected: false,
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
          child: _AgentChatDetail(
            agent: agent,
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
          child: _EveryoneDetail(
            showBackButton: true,
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}

Agent? _selectedAgent(List<Agent> agents, String currentAgentId) {
  if (agents.isEmpty) {
    return null;
  }
  if (currentAgentId.isEmpty) {
    return agents.first;
  }
  for (final agent in agents) {
    if (agent.id == currentAgentId) {
      return agent;
    }
  }
  return agents.first;
}

List<Agent> _agentsFrom(AsyncValue<List<Agent>> agents) {
  return switch (agents) {
    AsyncData(:final value) => value,
    _ => const <Agent>[],
  };
}
