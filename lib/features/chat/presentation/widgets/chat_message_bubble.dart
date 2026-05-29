import 'package:agent_client/app/theme/app_theme_tokens.dart';
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
    final color = user ? AppThemeTokens.brand : AppThemeTokens.panel;
    final textColor = user ? Colors.white : AppThemeTokens.text;
    final hasContent = message.content.trim().isNotEmpty;
    final hasAttachments = message.attachments.isNotEmpty;
    final placeholder = _placeholder();

    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: hasAttachments ? double.infinity : null,
        constraints: const BoxConstraints(maxWidth: 760),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: user ? null : Border.all(color: AppThemeTokens.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!hasContent && !hasAttachments && placeholder != null)
              _MessagePlaceholder(text: placeholder.$1, busy: placeholder.$2),
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

  (String, bool)? _placeholder() {
    if (message.role != ChatRole.assistant || message.content.isNotEmpty) {
      return null;
    }
    return switch (message.status) {
      ChatMessageStatus.streaming => ('Waiting for response', true),
      ChatMessageStatus.failed => ('Response failed', false),
      ChatMessageStatus.stopped => ('Response stopped', false),
      _ => null,
    };
  }

  MarkdownStyleSheet _markdownStyleSheet(Color textColor, bool user) {
    final mutedText = user ? Colors.white70 : AppThemeTokens.mutedText;
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
        color: user ? Colors.white : AppThemeTokens.brand,
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

class _MessagePlaceholder extends StatelessWidget {
  const _MessagePlaceholder({required this.text, required this.busy});

  final String text;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppThemeTokens.brand,
            ),
          )
        else
          const Icon(
            Icons.info_outline,
            size: 16,
            color: AppThemeTokens.mutedText,
          ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(color: AppThemeTokens.mutedText, fontSize: 13),
        ),
      ],
    );
  }
}
