import 'dart:async';
import 'package:agent_client/app/adaptive/adaptive_layout_policy.dart';
import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:agent_client/features/agents/application/agent_controller.dart';
import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:agent_client/features/agents/presentation/agent_avatar_editor_dialog.dart';
import 'package:agent_client/features/agents/presentation/agent_avatar_view.dart';
import 'package:agent_client/features/agents/presentation/agent_detail_page.dart';
import 'package:agent_client/features/agents/presentation/agent_navigation_panel.dart';
import 'package:agent_client/features/chat/application/chat_conversation_preview_provider.dart';
import 'package:agent_client/features/chat/application/chat_controller.dart';
import 'package:agent_client/features/chat/application/chat_preload_controller.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:agent_client/features/chat/presentation/mobile/mobile_chat_panel.dart';
import 'package:agent_client/features/chat/presentation/tablet/tablet_chat_panel.dart';
import 'package:agent_client/features/settings/presentation/app_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'desktop/desktop_agent_workspace.dart';
part 'mobile/mobile_agent_workspace.dart';
part 'shared/shared_agent_chat_detail.dart';
part 'shared/shared_conversation_helpers.dart';
part 'shared/shared_conversation_list.dart';
part 'shared/shared_workspace_rail.dart';
part 'tablet/tablet_agent_workspace.dart';

const _appRailWidth = 76.0;
const _conversationListColor = AppThemeTokens.workspaceAlt;
const _chatHeaderColor = AppThemeTokens.panel;
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
              final policy = AdaptiveLayoutPolicy.fromWidth(
                constraints.maxWidth,
              );

              return switch (policy.workspaceLayout) {
                WorkspaceLayoutMode.mobile => _MobileAgentWorkspace(
                  agents: agents,
                  currentAgentId: currentAgentId,
                ),
                WorkspaceLayoutMode.tablet => _TabletAgentWorkspace(
                  agents: agents,
                  currentAgentId: currentAgentId,
                ),
                WorkspaceLayoutMode.desktop => _DesktopAgentWorkspace(
                  agents: agents,
                  currentAgentId: currentAgentId,
                ),
              };
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
