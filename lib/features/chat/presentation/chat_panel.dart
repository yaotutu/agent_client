import 'dart:async';

import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:agent_client/features/chat/application/chat_controller.dart';
import 'package:agent_client/features/chat/application/chat_sessions_controller.dart';
import 'package:agent_client/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:agent_client/features/chat/presentation/widgets/chat_message_list.dart';
import 'package:agent_client/features/chat/presentation/widgets/chat_session_picker.dart';
import 'package:agent_client/features/chat/presentation/widgets/inline_chat_error.dart';
import 'package:agent_client/features/settings/data/agent_settings_repository.dart';
import 'package:agent_client/features/settings/domain/agent_command.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChatPanel extends HookConsumerWidget {
  const ChatPanel({super.key, required this.agent});

  final Agent agent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentId = agent.id;
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
      var disposed = false;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _waitForRouteTransition(context);
        if (disposed || !context.mounted) {
          return;
        }
        await ref
            .read(chatSessionsProvider(agentId).notifier)
            .refreshFromRepository();
        if (disposed || !context.mounted) {
          return;
        }
        await ref
            .read(chatControllerProvider(agentId).notifier)
            .loadRecentMessages();
      });
      return () {
        disposed = true;
      };
    }, [agentId]);

    final canSend =
        textController.text.trim().isNotEmpty &&
        !state.isStreaming &&
        !state.isStopping;

    Future<void> send() async {
      final text = textController.text;
      textController.clear();
      focusNode.requestFocus();
      await ref
          .read(chatControllerProvider(agentId).notifier)
          .sendMessage(text);
    }

    Widget chatColumn() {
      final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
      return AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: ColoredBox(
          color: AppThemeTokens.workspace,
          child: Column(
            children: [
              Expanded(
                child: ChatMessageList(
                  key: const Key('chat-message-list'),
                  assistantAgent: agent,
                  messages: state.messages,
                  isStreaming: state.isStreaming,
                  reasoningText: state.reasoningText,
                  progressText: state.progressText,
                  toolHintText: state.toolHintText,
                  fileEditText: state.fileEditText,
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
                isStopping: state.isStopping,
                commands: commands,
                onSend: send,
                onStop: () => ref
                    .read(chatControllerProvider(agentId).notifier)
                    .cancelActiveResponse(),
                onSwitchSession: () => showChatSessionDialog(context, agentId),
              ),
            ],
          ),
        ),
      );
    }

    return chatColumn();
  }
}

Future<void> _waitForRouteTransition(BuildContext context) async {
  final animation = ModalRoute.of(context)?.animation;
  if (animation == null || animation.status == AnimationStatus.completed) {
    return;
  }

  final completer = Completer<void>();
  late final AnimationStatusListener listener;
  listener = (status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      animation.removeStatusListener(listener);
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  };

  animation.addStatusListener(listener);
  if (animation.status == AnimationStatus.completed ||
      animation.status == AnimationStatus.dismissed) {
    animation.removeStatusListener(listener);
    return;
  }

  try {
    await completer.future.timeout(const Duration(milliseconds: 400));
  } on TimeoutException {
    animation.removeStatusListener(listener);
  }
}
