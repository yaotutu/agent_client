import 'dart:math' as math;

import 'package:agent_client/app/theme/app_theme_tokens.dart';
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
      color: AppThemeTokens.panel,
      child: InkWell(
        key: const Key('chat-session-picker-button'),
        onTap: () => showChatSessionDialog(context, agentId),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppThemeTokens.border)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            children: [
              ChatSessionStatusDot(
                status: session?.status ?? ChatSessionStatus.idle,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      session?.title ?? 'Current chat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppThemeTokens.headingText,
                        letterSpacing: 0,
                      ),
                    ),
                    if (session case final selected?)
                      Text(
                        '${selected.messageCount} messages',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppThemeTokens.mutedText,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 22,
                color: AppThemeTokens.mutedText,
              ),
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

void showChatSessionDialog(BuildContext context, String agentId) {
  showDialog<void>(
    context: context,
    builder: (context) => _ChatSessionDialog(agentId: agentId),
  );
}

class _ChatSessionDialog extends ConsumerWidget {
  const _ChatSessionDialog({required this.agentId});

  final String agentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(chatSessionsProvider(agentId));
    final chatState = ref.watch(chatControllerProvider(agentId));
    final selectedSessionId = chatState.sessionId ?? sessions.selectedSessionId;
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(size.width - 32, 560.0);
    final dialogHeight = math.min(math.max(size.height - 96, 320.0), 560.0);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
      ),
      child: SizedBox(
        key: const Key('chat-session-dialog'),
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 8, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Conversations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppThemeTokens.headingText,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('chat-session-dialog-new-button'),
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
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
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
          style: TextStyle(fontSize: 13, color: AppThemeTokens.mutedText),
        ),
      ),
    );
  }
}
