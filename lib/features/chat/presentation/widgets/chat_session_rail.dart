import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:agent_client/features/chat/application/chat_controller.dart';
import 'package:agent_client/features/chat/application/chat_sessions_controller.dart';
import 'package:agent_client/features/chat/domain/chat_session.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChatSessionRail extends ConsumerWidget {
  const ChatSessionRail({super.key, required this.agentId});

  final String agentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(chatSessionsProvider(agentId));
    final chatState = ref.watch(chatControllerProvider(agentId));
    final selectedSessionId = chatState.sessionId ?? sessions.selectedSessionId;

    return Container(
      key: const Key('chat-session-rail'),
      width: 248,
      decoration: const BoxDecoration(
        color: AppThemeTokens.panel,
        border: Border(right: BorderSide(color: AppThemeTokens.border)),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Conversations',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF344054),
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('chat-session-new-button'),
                    tooltip: 'New session',
                    visualDensity: VisualDensity.compact,
                    onPressed: chatState.isStreaming
                        ? null
                        : () => ref
                              .read(chatControllerProvider(agentId).notifier)
                              .startNewSession(),
                    icon: const Icon(Icons.add, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: sessions.sessions.isEmpty
                  ? const _EmptySessionRail()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                      itemCount: sessions.sessions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final session = sessions.sessions[index];
                        return ChatSessionTile(
                          session: session,
                          selected: session.id == selectedSessionId,
                          onTap: () => ref
                              .read(chatControllerProvider(agentId).notifier)
                              .openSessionPreview(session),
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

class _EmptySessionRail extends StatelessWidget {
  const _EmptySessionRail();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text(
          'No sessions yet',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
        ),
      ),
    );
  }
}

class ChatSessionTile extends StatelessWidget {
  const ChatSessionTile({
    super.key,
    required this.session,
    required this.selected,
    required this.onTap,
  });

  final ChatSessionSummary session;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.10)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppThemeTokens.radius),
      child: InkWell(
        key: Key('chat-session-${session.id}'),
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: ChatSessionStatusDot(status: session.status),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppThemeTokens.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          session.updatedLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppThemeTokens.mutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.preview.isEmpty
                          ? 'No messages yet'
                          : session.preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: AppThemeTokens.mutedText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${session.messageCount} messages',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppThemeTokens.subtleText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatSessionStatusDot extends StatelessWidget {
  const ChatSessionStatusDot({super.key, required this.status});

  final ChatSessionStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ChatSessionStatus.running => const Color(0xFF1570EF),
      ChatSessionStatus.stopping => const Color(0xFFF79009),
      ChatSessionStatus.error => const Color(0xFFD92D20),
      ChatSessionStatus.idle => const Color(0xFF12B76A),
    };

    return Tooltip(
      message: status.name,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
