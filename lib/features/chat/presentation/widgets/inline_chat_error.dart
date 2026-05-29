import 'package:flutter/material.dart';

class InlineChatError extends StatelessWidget {
  const InlineChatError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF1F3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFFB42318)),
      ),
    );
  }
}
