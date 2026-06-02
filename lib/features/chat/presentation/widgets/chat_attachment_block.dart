import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:agent_client/features/chat/domain/chat_attachment.dart';
import 'package:flutter/material.dart';

class ChatAttachmentBlock extends StatelessWidget {
  const ChatAttachmentBlock({
    super.key,
    required this.attachment,
    required this.user,
  });

  final ChatAttachment attachment;
  final bool user;

  @override
  Widget build(BuildContext context) {
    return switch (attachment.kind) {
      ChatAttachmentKind.file => _FileAttachmentTile(
        attachment: attachment,
        user: user,
      ),
      ChatAttachmentKind.image => _ImageAttachmentTile(
        attachment: attachment,
        user: user,
      ),
    };
  }
}

class _FileAttachmentTile extends StatelessWidget {
  const _FileAttachmentTile({required this.attachment, required this.user});

  final ChatAttachment attachment;
  final bool user;

  @override
  Widget build(BuildContext context) {
    final borderColor = user ? Colors.white24 : AppThemeTokens.border;
    final backgroundColor = user ? Colors.white12 : AppThemeTokens.panelMuted;
    final primaryText = user ? Colors.white : AppThemeTokens.headingText;
    final secondaryText = user ? Colors.white70 : AppThemeTokens.mutedText;

    return Container(
      key: Key('chat-file-${attachment.id}'),
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: user ? Colors.white12 : AppThemeTokens.brandSofter,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.description_outlined,
              color: user ? Colors.white : AppThemeTokens.brandPressed,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (attachment.metadataLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      attachment.metadataLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: secondaryText, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Open file',
            onPressed: () {},
            icon: Icon(
              Icons.open_in_new,
              color: user ? Colors.white : AppThemeTokens.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageAttachmentTile extends StatelessWidget {
  const _ImageAttachmentTile({required this.attachment, required this.user});

  final ChatAttachment attachment;
  final bool user;

  @override
  Widget build(BuildContext context) {
    final borderColor = user ? Colors.white24 : AppThemeTokens.border;
    final backgroundColor = user ? Colors.white12 : AppThemeTokens.panel;
    final primaryText = user ? Colors.white : AppThemeTokens.headingText;
    final secondaryText = user ? Colors.white70 : AppThemeTokens.mutedText;
    final imageUrl = attachment.thumbnailUrl ?? attachment.url;

    return Container(
      key: Key('chat-image-${attachment.id}'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: imageUrl == null
                ? _ImageFallback(user: user)
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    semanticLabel: attachment.name,
                    errorBuilder: (context, error, stackTrace) {
                      return _ImageFallback(user: user);
                    },
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) {
                        return child;
                      }
                      return _ImageFallback(user: user, loading: true);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (attachment.metadataLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      attachment.metadataLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: secondaryText, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.user, this.loading = false});

  final bool user;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: user ? Colors.white12 : AppThemeTokens.codeBackground,
      child: Center(
        child: Icon(
          loading ? Icons.hourglass_empty : Icons.image_outlined,
          color: user ? Colors.white70 : AppThemeTokens.mutedText,
          size: 32,
        ),
      ),
    );
  }
}
