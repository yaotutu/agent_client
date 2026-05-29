import 'package:agent_client/features/chat/data/agent_chat_repository.dart';
import 'package:agent_client/features/chat/domain/chat_session.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final chatSessionsProvider =
    NotifierProvider.family<ChatSessionsController, ChatSessionsState, String>(
      ChatSessionsController.new,
    );

class ChatSessionsState {
  const ChatSessionsState({
    required this.sessions,
    required this.selectedSessionId,
  });

  final List<ChatSessionSummary> sessions;
  final String? selectedSessionId;

  ChatSessionsState copyWith({
    List<ChatSessionSummary>? sessions,
    String? selectedSessionId,
  }) {
    return ChatSessionsState(
      sessions: sessions ?? this.sessions,
      selectedSessionId: selectedSessionId ?? this.selectedSessionId,
    );
  }
}

class ChatSessionsController extends Notifier<ChatSessionsState> {
  ChatSessionsController(this.agentId);

  final String agentId;

  @override
  ChatSessionsState build() {
    return const ChatSessionsState(selectedSessionId: null, sessions: []);
  }

  void selectSession(String sessionId) {
    state = state.copyWith(selectedSessionId: sessionId);
  }

  Future<void> refreshFromRepository() async {
    try {
      final sessions = await ref
          .read(agentChatRepositoryProvider)
          .listSessions(agentId);
      state = ChatSessionsState(
        sessions: sessions,
        selectedSessionId: _selectedSessionIdFor(sessions),
      );
    } catch (_) {
      // Keep the local mock sessions available while the backend is catching up.
    }
  }

  void insertSession(ChatSessionSummary session) {
    state = ChatSessionsState(
      selectedSessionId: session.id,
      sessions: [
        session,
        for (final existing in state.sessions)
          if (existing.id != session.id) existing,
      ],
    );
  }

  void insertNewSession(String sessionId) {
    insertSession(
      ChatSessionSummary(
        id: sessionId,
        title: 'New chat',
        preview: '',
        updatedLabel: 'Now',
        messageCount: 0,
      ),
    );
  }

  ChatSessionSummary? findSession(String sessionId) {
    for (final session in state.sessions) {
      if (session.id == sessionId) {
        return session;
      }
    }
    return null;
  }

  String? _selectedSessionIdFor(List<ChatSessionSummary> sessions) {
    if (sessions.isEmpty) {
      return null;
    }
    final current = state.selectedSessionId;
    if (current != null && sessions.any((session) => session.id == current)) {
      return current;
    }
    return sessions.first.id;
  }
}
