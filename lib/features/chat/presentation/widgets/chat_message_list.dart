import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:agent_client/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:flutter/material.dart';

class ChatMessageList extends StatefulWidget {
  const ChatMessageList({
    super.key,
    required this.messages,
    this.assistantAgent,
    this.isStreaming = false,
    this.reasoningText,
    this.progressText,
    this.toolHintText,
    this.fileEditText,
    this.goalStatus,
    this.scrollController,
  });

  final List<ChatMessage> messages;
  final Agent? assistantAgent;
  final bool isStreaming;
  final String? reasoningText;
  final String? progressText;
  final String? toolHintText;
  final String? fileEditText;
  final String? goalStatus;
  final ScrollController? scrollController;

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  late final ScrollController _fallbackController;
  var _scrollScheduled = false;

  @override
  void initState() {
    super.initState();
    _fallbackController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant ChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_shouldReactToUpdate(oldWidget)) {
      return;
    }
    if (_isNearLatest() || _shouldForceFollow(oldWidget)) {
      _scheduleScrollToLatest();
    }
  }

  @override
  void dispose() {
    _fallbackController.dispose();
    super.dispose();
  }

  ScrollController get _controller =>
      widget.scrollController ?? _fallbackController;

  @override
  Widget build(BuildContext context) {
    final showActivity = _hasActivity(widget);
    final visibleMessages = widget.messages
        .where((message) => !_isPendingAssistantResponse(message))
        .toList(growable: false);

    if (visibleMessages.isEmpty && !showActivity) {
      return const Center(
        child: Text(
          'Start a chat',
          style: TextStyle(color: AppThemeTokens.mutedText),
        ),
      );
    }

    return ListView.builder(
      controller: _controller,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      addAutomaticKeepAlives: false,
      addSemanticIndexes: false,
      itemCount: visibleMessages.length + (showActivity ? 1 : 0),
      itemBuilder: (context, index) {
        var offset = 0;
        if (showActivity && index == offset) {
          return ChatLiveActivity(
            reasoningText: widget.reasoningText,
            progressText: widget.progressText,
            toolHintText: widget.toolHintText,
            fileEditText: widget.fileEditText,
            goalStatus: widget.goalStatus,
          );
        }
        if (showActivity) {
          offset += 1;
        }

        final messageIndex = visibleMessages.length - 1 - (index - offset);
        final message = visibleMessages[messageIndex];
        return RepaintBoundary(
          key: ValueKey(message.id),
          child: ChatMessageBubble(
            message: message,
            assistantAgent: widget.assistantAgent,
          ),
        );
      },
    );
  }

  bool _shouldReactToUpdate(ChatMessageList oldWidget) {
    if (oldWidget.messages.length != widget.messages.length) {
      return true;
    }
    if (_activitySignature(oldWidget) != _activitySignature(widget)) {
      return true;
    }
    final oldLast = _lastMessage(oldWidget.messages);
    final newLast = _lastMessage(widget.messages);
    return oldLast?.id != newLast?.id ||
        oldLast?.content != newLast?.content ||
        oldLast?.status != newLast?.status;
  }

  bool _shouldForceFollow(ChatMessageList oldWidget) {
    if (oldWidget.messages.isEmpty && widget.messages.isNotEmpty) {
      return true;
    }
    final oldLast = _lastMessage(oldWidget.messages);
    final newLast = _lastMessage(widget.messages);
    return oldLast?.id != newLast?.id && newLast?.role == ChatRole.user;
  }

  bool _isNearLatest() {
    if (!_controller.hasClients) {
      return true;
    }
    return _controller.position.pixels < 96;
  }

  void _scheduleScrollToLatest() {
    if (_scrollScheduled) {
      return;
    }
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      _jumpToLatest();
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToLatest());
    });
  }

  void _jumpToLatest() {
    if (!mounted || !_controller.hasClients) {
      return;
    }
    _controller.jumpTo(_controller.position.minScrollExtent);
  }

  bool _hasActivity(ChatMessageList widget) {
    return widget.isStreaming &&
        (widget.reasoningText?.trim().isNotEmpty == true ||
            widget.progressText?.trim().isNotEmpty == true ||
            widget.toolHintText?.trim().isNotEmpty == true ||
            widget.fileEditText?.trim().isNotEmpty == true ||
            widget.goalStatus?.trim().isNotEmpty == true);
  }

  bool _isPendingAssistantResponse(ChatMessage message) {
    return message.role == ChatRole.assistant &&
        message.status == ChatMessageStatus.streaming &&
        message.content.trim().isEmpty &&
        message.attachments.isEmpty;
  }

  String _activitySignature(ChatMessageList widget) {
    return [
      widget.isStreaming,
      widget.reasoningText,
      widget.progressText,
      widget.toolHintText,
      widget.fileEditText,
      widget.goalStatus,
    ].join('\u0001');
  }

  ChatMessage? _lastMessage(List<ChatMessage> messages) {
    return messages.isEmpty ? null : messages.last;
  }
}

class ChatLiveActivity extends StatelessWidget {
  const ChatLiveActivity({
    super.key,
    this.reasoningText,
    this.progressText,
    this.toolHintText,
    this.fileEditText,
    this.goalStatus,
  });

  final String? reasoningText;
  final String? progressText;
  final String? toolHintText;
  final String? fileEditText;
  final String? goalStatus;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (goalStatus?.trim().isNotEmpty == true)
        _ActivityRow(
          icon: goalStatus == 'running'
              ? Icons.sync_outlined
              : Icons.check_circle_outline,
          label: goalStatus == 'running' ? 'Processing' : 'Status',
          text: goalStatus!,
        ),
      if (reasoningText?.trim().isNotEmpty == true)
        _ActivityRow(
          icon: Icons.psychology_alt_outlined,
          label: 'Thinking',
          text: reasoningText!,
        ),
      if (progressText?.trim().isNotEmpty == true)
        _ActivityRow(
          icon: Icons.trending_flat,
          label: 'Progress',
          text: progressText!,
        ),
      if (toolHintText?.trim().isNotEmpty == true)
        _ActivityRow(
          icon: Icons.terminal_outlined,
          label: 'Tool',
          text: toolHintText!,
        ),
      if (fileEditText?.trim().isNotEmpty == true)
        _ActivityRow(
          icon: Icons.edit_document,
          label: 'Files',
          text: fileEditText!,
        ),
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: const Key('chat-live-activity'),
        constraints: const BoxConstraints(maxWidth: 760),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppThemeTokens.panel,
          border: Border.all(color: AppThemeTokens.border),
          borderRadius: BorderRadius.circular(AppThemeTokens.radius),
          boxShadow: const [
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
            for (var index = 0; index < rows.length; index += 1)
              Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
                child: rows[index],
              ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.label,
    required this.text,
  });

  final IconData icon;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppThemeTokens.brand),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppThemeTokens.headingText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppThemeTokens.mutedText,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
