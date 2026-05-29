import 'package:agent_client/features/chat/application/chat_controller.dart';
import 'package:agent_client/features/chat/domain/chat_attachment.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _staticChatPreviewVersion = 2;

class ChatPanel extends HookConsumerWidget {
  const ChatPanel({super.key, required this.agentId});

  final String agentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatControllerProvider(agentId));
    final textController = useTextEditingController();
    final focusNode = useFocusNode();
    useListenable(textController);
    useEffect(() {
      Future.microtask(
        () => ref
            .read(chatControllerProvider(agentId).notifier)
            .refreshRecentMessages(),
      );
      return null;
    }, [agentId, _staticChatPreviewVersion]);

    final canSend = textController.text.trim().isNotEmpty && !state.isStreaming;

    Future<void> send() async {
      final text = textController.text;
      textController.clear();
      focusNode.requestFocus();
      await ref
          .read(chatControllerProvider(agentId).notifier)
          .sendMessage(text);
    }

    return ColoredBox(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          Expanded(
            child: _MessageList(
              key: const Key('chat-message-list'),
              messages: state.messages,
            ),
          ),
          if (state.errorMessage case final error?)
            _InlineError(message: error),
          _ChatInputBar(
            controller: textController,
            focusNode: focusNode,
            canSend: canSend,
            isStreaming: state.isStreaming,
            onSend: send,
            onStop: () => ref
                .read(chatControllerProvider(agentId).notifier)
                .cancelActiveResponse(),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({super.key, required this.messages});

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
        return _MessageBubble(message: messages[index]);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

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
                child: _AttachmentBlock(
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

class _AttachmentBlock extends StatelessWidget {
  const _AttachmentBlock({required this.attachment, required this.user});

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
    final borderColor = user ? Colors.white24 : const Color(0xFFE4E7EC);
    final backgroundColor = user ? Colors.white12 : const Color(0xFFFCFCFD);
    final primaryText = user ? Colors.white : const Color(0xFF101828);
    final secondaryText = user ? Colors.white70 : const Color(0xFF667085);

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
              color: user ? Colors.white12 : const Color(0xFFEFF8FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.description_outlined,
              color: user ? Colors.white : const Color(0xFF256D85),
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
              color: user ? Colors.white : const Color(0xFF475467),
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
    final borderColor = user ? Colors.white24 : const Color(0xFFE4E7EC);
    final backgroundColor = user ? Colors.white12 : Colors.white;
    final primaryText = user ? Colors.white : const Color(0xFF101828);
    final secondaryText = user ? Colors.white70 : const Color(0xFF667085);
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
      color: user ? Colors.white12 : const Color(0xFFF2F4F7),
      child: Center(
        child: Icon(
          loading ? Icons.hourglass_empty : Icons.image_outlined,
          color: user ? Colors.white70 : const Color(0xFF667085),
          size: 32,
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.isStreaming,
    required this.onSend,
    required this.onStop,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final bool isStreaming;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        key: const Key('chat-input-bar'),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE4E7EC))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Message',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: isStreaming ? 'Stop' : 'Send',
              onPressed: isStreaming
                  ? onStop
                  : canSend
                  ? onSend
                  : null,
              icon: Icon(isStreaming ? Icons.stop : Icons.arrow_upward),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

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
