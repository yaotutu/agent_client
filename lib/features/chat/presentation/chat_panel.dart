import 'package:agent_client/features/chat/application/chat_controller.dart';
import 'package:agent_client/features/chat/application/chat_sessions_controller.dart';
import 'package:agent_client/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:agent_client/features/chat/presentation/widgets/chat_message_list.dart';
import 'package:agent_client/features/chat/presentation/widgets/chat_session_picker.dart';
import 'package:agent_client/features/chat/presentation/widgets/chat_session_rail.dart';
import 'package:agent_client/features/chat/presentation/widgets/inline_chat_error.dart';
import 'package:agent_client/features/settings/data/agent_settings_repository.dart';
import 'package:agent_client/features/settings/domain/agent_command.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChatPanel extends HookConsumerWidget {
  const ChatPanel({super.key, required this.agentId});

  final String agentId;
  static const _sessionRailMinWidth = 500.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatControllerProvider(agentId));
    final List<AgentCommandItem> commands = switch (ref.watch(
      agentCommandsProvider(agentId),
    )) {
      AsyncData(:final value) => value,
      _ => const <AgentCommandItem>[],
    };
    final textController = useTextEditingController();
    final focusNode = useFocusNode();
    useListenable(textController);
    useEffect(() {
      Future.microtask(() async {
        await ref
            .read(chatSessionsProvider(agentId).notifier)
            .refreshFromRepository();
        await ref
            .read(chatControllerProvider(agentId).notifier)
            .loadRecentMessages();
      });
      return null;
    }, [agentId]);

    final canSend = textController.text.trim().isNotEmpty && !state.isStreaming;

    Future<void> send() async {
      final text = textController.text;
      textController.clear();
      focusNode.requestFocus();
      await ref
          .read(chatControllerProvider(agentId).notifier)
          .sendMessage(text);
    }

    Widget chatColumn() {
      return ColoredBox(
        color: const Color(0xFFF7F8FA),
        child: Column(
          children: [
            Expanded(
              child: ChatMessageList(
                key: const Key('chat-message-list'),
                messages: state.messages,
                isStreaming: state.isStreaming,
                reasoningText: state.reasoningText,
                progressText: state.progressText,
                toolHintText: state.toolHintText,
                goalStatus: state.goalStatus,
              ),
            ),
            if (state.errorMessage case final error?)
              InlineChatError(message: error),
            ChatInputBar(
              controller: textController,
              focusNode: focusNode,
              canSend: canSend,
              isStreaming: state.isStreaming,
              commands: commands,
              onSend: send,
              onStop: () => ref
                  .read(chatControllerProvider(agentId).notifier)
                  .cancelActiveResponse(),
              onSwitchSession: () => showChatSessionSheet(context, agentId),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _sessionRailMinWidth) {
          return chatColumn();
        }

        return Row(
          children: [
            ChatSessionRail(agentId: agentId),
            Expanded(child: chatColumn()),
          ],
        );
      },
    );
  }
}
