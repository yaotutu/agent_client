import 'package:agent_client/features/chat/application/chat_controller.dart';
import 'package:agent_client/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:agent_client/features/chat/presentation/widgets/chat_message_list.dart';
import 'package:agent_client/features/chat/presentation/widgets/inline_chat_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
            child: ChatMessageList(
              key: const Key('chat-message-list'),
              messages: state.messages,
            ),
          ),
          if (state.errorMessage case final error?)
            InlineChatError(message: error),
          ChatInputBar(
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
