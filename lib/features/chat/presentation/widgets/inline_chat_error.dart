import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:flutter/material.dart';

class InlineChatError extends StatelessWidget {
  const InlineChatError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppThemeTokens.dangerSoft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppThemeTokens.dangerText),
      ),
    );
  }
}
