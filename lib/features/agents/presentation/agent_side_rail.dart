import 'package:agent_client/features/agents/presentation/agent_navigation_panel.dart';
import 'package:flutter/material.dart';

class AgentSideRail extends StatelessWidget {
  const AgentSideRail({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('agent-side-rail'),
      width: 280,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE4E7EC))),
      ),
      child: const Material(
        color: Colors.transparent,
        child: AgentNavigationPanel(),
      ),
    );
  }
}
