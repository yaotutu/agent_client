import 'package:agent_client/app/agent_client_app.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: AgentClientApp()));
}
