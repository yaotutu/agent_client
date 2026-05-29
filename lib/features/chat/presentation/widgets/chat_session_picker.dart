import 'package:agent_client/features/chat/application/chat_controller.dart';
import 'package:agent_client/features/chat/application/chat_sessions_controller.dart';
import 'package:agent_client/features/chat/domain/chat_session.dart';
import 'package:agent_client/features/chat/presentation/widgets/chat_session_rail.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChatSessionPickerBar extends ConsumerWidget {
  const ChatSessionPickerBar({super.key, required this.agentId});

  final String agentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = _selectedSession(ref, agentId);

    return Material(
      color: Colors.white,
      child: InkWell(
        key: const Key('chat-session-picker-button'),
        onTap: () => showChatSessionSheet(context, agentId),
        child: Container(
          height: 48,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE4E7EC))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              ChatSessionStatusDot(
                status: session?.status ?? ChatSessionStatus.idle,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  session?.title ?? 'Current chat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

ChatSessionSummary? _selectedSession(WidgetRef ref, String agentId) {
  final sessions = ref.watch(chatSessionsProvider(agentId));
  final chatState = ref.watch(chatControllerProvider(agentId));
  final selectedSessionId = chatState.sessionId ?? sessions.selectedSessionId;
  if (selectedSessionId == null) {
    return sessions.sessions.isEmpty ? null : sessions.sessions.first;
  }

  for (final session in sessions.sessions) {
    if (session.id == selectedSessionId) {
      return session;
    }
  }
  return null;
}

void showChatSessionSheet(BuildContext context, String agentId) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => _ChatSessionSheet(agentId: agentId),
  );
}

class _ChatSessionSheet extends ConsumerWidget {
  const _ChatSessionSheet({required this.agentId});

  final String agentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(chatSessionsProvider(agentId));
    final chatState = ref.watch(chatControllerProvider(agentId));
    final selectedSessionId = chatState.sessionId ?? sessions.selectedSessionId;

    return SafeArea(
      top: false,
      child: SizedBox(
        key: const Key('chat-session-sheet'),
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 10, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Conversations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('chat-session-sheet-new-button'),
                    tooltip: 'New session',
                    onPressed: chatState.isStreaming
                        ? null
                        : () async {
                            await ref
                                .read(chatControllerProvider(agentId).notifier)
                                .startNewSession();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    icon: const Icon(Icons.add_comment_outlined),
                  ),
                ],
              ),
            ),
            Expanded(
              child: sessions.sessions.isEmpty
                  ? const _EmptySessions()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
                      itemCount: sessions.sessions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final session = sessions.sessions[index];
                        return ChatSessionTile(
                          session: session,
                          selected: session.id == selectedSessionId,
                          onTap: () async {
                            await ref
                                .read(chatControllerProvider(agentId).notifier)
                                .openSessionPreview(session);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySessions extends StatelessWidget {
  const _EmptySessions();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No sessions yet',
          style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
        ),
      ),
    );
  }
}
