import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:agent_client/features/chat/presentation/widgets/chat_attachment_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final user = message.role == ChatRole.user;
    final color = user ? const Color(0xFF256D85) : Colors.white;
    final textColor = user ? Colors.white : const Color(0xFF101828);
    final hasContent = message.content.trim().isNotEmpty;
    final hasAttachments = message.attachments.isNotEmpty;

    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: hasAttachments ? double.infinity : null,
        constraints: const BoxConstraints(maxWidth: 680),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: user ? null : Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasContent)
              SelectionArea(
                child: MarkdownBody(
                  key: Key('chat-markdown-${message.id}'),
                  data: message.content,
                  shrinkWrap: true,
                  styleSheet: _markdownStyleSheet(textColor, user),
                ),
              ),
            for (var index = 0; index < message.attachments.length; index++)
              Padding(
                padding: EdgeInsets.only(top: hasContent || index > 0 ? 10 : 0),
                child: ChatAttachmentBlock(
                  attachment: message.attachments[index],
                  user: user,
                ),
              ),
          ],
        ),
      ),
    );
  }

  MarkdownStyleSheet _markdownStyleSheet(Color textColor, bool user) {
    final mutedText = user ? Colors.white70 : const Color(0xFF667085);
    final codeBackground = user
        ? const Color(0x33256D85)
        : const Color(0xFFF2F4F7);

    return MarkdownStyleSheet(
      p: TextStyle(color: textColor, height: 1.35, fontSize: 14),
      h1: TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      h2: TextStyle(
        color: textColor,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      h3: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      strong: TextStyle(color: textColor, fontWeight: FontWeight.w700),
      em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
      a: TextStyle(
        color: user ? Colors.white : const Color(0xFF256D85),
        decoration: TextDecoration.underline,
      ),
      blockquote: TextStyle(color: mutedText, height: 1.35),
      blockquotePadding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      blockquoteDecoration: BoxDecoration(
        color: user ? Colors.white12 : const Color(0xFFF2F4F7),
        border: Border(left: BorderSide(color: mutedText, width: 3)),
      ),
      code: TextStyle(
        color: textColor,
        fontFamily: 'monospace',
        fontSize: 13,
        backgroundColor: codeBackground,
      ),
      codeblockPadding: const EdgeInsets.all(10),
      codeblockDecoration: BoxDecoration(
        color: codeBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      blockSpacing: 8,
      listIndent: 20,
    );
  }
}
