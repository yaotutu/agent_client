import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:agent_client/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:flutter/material.dart';

class ChatMessageList extends StatelessWidget {
  const ChatMessageList({super.key, required this.messages});

  final List<ChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Text('Start a chat', style: TextStyle(color: Color(0xFF667085))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return ChatMessageBubble(message: messages[index]);
      },
    );
  }
}
