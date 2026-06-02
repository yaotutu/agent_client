import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:agent_client/features/agents/domain/agent_avatar.dart';
import 'package:agent_client/features/agents/presentation/agent_avatar_view.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:agent_client/features/chat/presentation/widgets/chat_attachment_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.assistantAgent,
  });

  final ChatMessage message;
  final Agent? assistantAgent;

  @override
  Widget build(BuildContext context) {
    final user = message.role == ChatRole.user;
    final color = user ? AppThemeTokens.brand : AppThemeTokens.panel;
    final textColor = user ? Colors.white : AppThemeTokens.text;
    final hasContent = message.content.trim().isNotEmpty;
    final hasAttachments = message.attachments.isNotEmpty;
    final placeholder = _placeholder();
    final textStyle = TextStyle(color: textColor, height: 1.45, fontSize: 14);

    final bubble = Container(
      width: hasAttachments ? double.infinity : null,
      constraints: const BoxConstraints(maxWidth: 760),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: user ? null : Border.all(color: AppThemeTokens.border),
        boxShadow: user
            ? null
            : const [
                BoxShadow(
                  color: AppThemeTokens.shadow,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasContent && !hasAttachments && placeholder != null)
            _MessagePlaceholder(text: placeholder.$1, busy: placeholder.$2),
          if (hasContent)
            _looksLikeMarkdown(message.content)
                ? MarkdownBody(
                    key: Key('chat-markdown-${message.id}'),
                    data: message.content,
                    shrinkWrap: true,
                    styleSheet: _markdownStyleSheet(textColor, user),
                  )
                : Text(message.content, style: textStyle),
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
    );

    final showAssistantAvatar =
        assistantAgent != null &&
        AgentAvatarOptions.isDefaultAssetPath(assistantAgent!.avatarUrl);

    if (user || !showAssistantAvatar) {
      return Align(
        alignment: user ? Alignment.centerRight : Alignment.centerLeft,
        child: bubble,
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 12),
            child: AgentAvatarView(
              agent: assistantAgent!,
              radius: 16,
              showStatus: false,
            ),
          ),
          Flexible(child: bubble),
        ],
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
        ? Colors.white24
        : AppThemeTokens.codeBackground;

    return MarkdownStyleSheet(
      p: TextStyle(color: textColor, height: 1.45, fontSize: 14),
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
        color: user ? Colors.white12 : AppThemeTokens.codeBackground,
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

  bool _looksLikeMarkdown(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    if (trimmed.contains('```') ||
        trimmed.contains('`') ||
        trimmed.contains('**') ||
        trimmed.contains('__') ||
        trimmed.contains('![') ||
        RegExp(r'\[[^\]]+\]\([^)]+\)').hasMatch(trimmed)) {
      return true;
    }
    return RegExp(
      r'(^|\n)\s{0,3}(#{1,6}\s|>\s|[-*+]\s|\d+\.\s)',
    ).hasMatch(trimmed);
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
