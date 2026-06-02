import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:agent_client/features/settings/domain/agent_command.dart';
import 'package:flutter/material.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.isStreaming,
    required this.isStopping,
    this.commands = const [],
    required this.onSend,
    required this.onStop,
    required this.onSwitchSession,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final bool isStreaming;
  final bool isStopping;
  final List<AgentCommandItem> commands;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final VoidCallback onSwitchSession;

  @override
  Widget build(BuildContext context) {
    final input = controller.text.trimLeft();
    final matchingCommands = input.startsWith('/')
        ? commands
              .where((command) => command.command.startsWith(input))
              .take(6)
              .toList()
        : const <AgentCommandItem>[];

    return SafeArea(
      top: false,
      child: Container(
        key: const Key('chat-input-bar'),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: const BoxDecoration(
          color: AppThemeTokens.panel,
          border: Border(top: BorderSide(color: AppThemeTokens.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (matchingCommands.isNotEmpty)
              _CommandSuggestions(
                commands: matchingCommands,
                onSelected: (command) {
                  controller.text = command.command;
                  controller.selection = TextSelection.collapsed(
                    offset: controller.text.length,
                  );
                  focusNode.requestFocus();
                },
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  key: const Key('chat-session-switch-button'),
                  tooltip: 'Switch session',
                  onPressed: isStreaming || isStopping ? null : onSwitchSession,
                  icon: const Icon(Icons.forum_outlined),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Message',
                      fillColor: AppThemeTokens.panelMuted,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SendControlButton(
                  canSend: canSend,
                  isStreaming: isStreaming,
                  isStopping: isStopping,
                  onSend: onSend,
                  onStop: onStop,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SendControlButton extends StatelessWidget {
  const _SendControlButton({
    required this.canSend,
    required this.isStreaming,
    required this.isStopping,
    required this.onSend,
    required this.onStop,
  });

  final bool canSend;
  final bool isStreaming;
  final bool isStopping;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      key: const Key('chat-send-button'),
      tooltip: isStopping
          ? 'Stopping'
          : isStreaming
          ? 'Stop'
          : 'Send',
      onPressed: isStopping
          ? null
          : isStreaming
          ? onStop
          : canSend
          ? onSend
          : null,
      style: ButtonStyle(
        fixedSize: const WidgetStatePropertyAll(Size.square(44)),
        minimumSize: const WidgetStatePropertyAll(Size.square(44)),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppThemeTokens.workspace;
          }
          if (isStreaming) {
            return AppThemeTokens.dangerSoft;
          }
          if (states.contains(WidgetState.pressed)) {
            return AppThemeTokens.brandPressed;
          }
          return AppThemeTokens.brand;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppThemeTokens.subtleText;
          }
          if (isStreaming) {
            return AppThemeTokens.dangerText;
          }
          return Colors.white;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (isStreaming) {
            return const BorderSide(color: AppThemeTokens.dangerBorder);
          }
          if (states.contains(WidgetState.disabled)) {
            return const BorderSide(color: AppThemeTokens.strongBorder);
          }
          return const BorderSide(color: AppThemeTokens.brandPressed);
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeTokens.controlRadius),
          ),
        ),
      ),
      icon: isStopping
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: AppThemeTokens.mutedText,
                strokeWidth: 2,
              ),
            )
          : Icon(
              isStreaming ? Icons.stop : Icons.arrow_upward,
              size: isStreaming ? 18 : 20,
            ),
    );
  }
}

class _CommandSuggestions extends StatelessWidget {
  const _CommandSuggestions({required this.commands, required this.onSelected});

  final List<AgentCommandItem> commands;
  final ValueChanged<AgentCommandItem> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: commands.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final command = commands[index];
          return ActionChip(
            avatar: const Icon(Icons.terminal, size: 16),
            label: Text(command.command),
            tooltip: command.description.isEmpty
                ? command.title
                : command.description,
            onPressed: () => onSelected(command),
          );
        },
      ),
    );
  }
}
