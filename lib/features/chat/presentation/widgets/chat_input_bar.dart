import 'package:agent_client/features/agent_control/domain/agent_control_models.dart';
import 'package:flutter/material.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.isStreaming,
    this.commands = const [],
    required this.onSend,
    required this.onStop,
    required this.onSwitchSession,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final bool isStreaming;
  final List<AgentCommand> commands;
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
        : const <AgentCommand>[];

    return SafeArea(
      top: false,
      child: Container(
        key: const Key('chat-input-bar'),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE4E7EC))),
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
                  onPressed: isStreaming ? null : onSwitchSession,
                  icon: const Icon(Icons.forum_outlined),
                ),
                const SizedBox(width: 4),
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
          ],
        ),
      ),
    );
  }
}

class _CommandSuggestions extends StatelessWidget {
  const _CommandSuggestions({required this.commands, required this.onSelected});

  final List<AgentCommand> commands;
  final ValueChanged<AgentCommand> onSelected;

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
