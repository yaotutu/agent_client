import 'package:agent_client/app/theme/app_theme.dart';
import 'package:agent_client/features/agents/presentation/agent_workspace_page.dart';
import 'package:flutter/material.dart';

class AgentClientApp extends StatelessWidget {
  const AgentClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agent Client',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AgentWorkspacePage(),
    );
  }
}
