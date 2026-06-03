import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:agent_client/features/chat/presentation/shared/shared_chat_panel.dart';
import 'package:flutter/material.dart';

class TabletChatPanel extends StatelessWidget {
  const TabletChatPanel({super.key, required this.agent});

  final Agent agent;

  @override
  Widget build(BuildContext context) {
    return SharedChatPanel(agent: agent);
  }
}
