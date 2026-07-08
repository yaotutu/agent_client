import 'package:agent_client/app/theme/app_theme.dart';
import 'package:agent_client/features/nanobot/presentation/nanobot_workspace_page.dart';
import 'package:flutter/material.dart';

class NanobotClientApp extends StatelessWidget {
  const NanobotClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nanobot',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const NanobotWorkspacePage(),
    );
  }
}
