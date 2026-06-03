import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:agent_client/features/chat/presentation/tablet/tablet_chat_panel.dart';
import 'package:flutter/material.dart';

class DesktopChatPanel extends StatelessWidget {
  const DesktopChatPanel({super.key, required this.agent});

  final Agent agent;

  @override
  Widget build(BuildContext context) {
    return TabletChatPanel(agent: agent);
  }
}
