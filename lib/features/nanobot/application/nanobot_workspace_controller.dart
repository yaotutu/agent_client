import 'dart:async';

import 'package:agent_client/features/nanobot/application/nanobot_workspace_state.dart';
import 'package:agent_client/features/nanobot/data/nanobot_providers.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_event.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_message.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final nanobotWorkspaceControllerProvider =
    NotifierProvider<NanobotWorkspaceController, NanobotWorkspaceState>(
      NanobotWorkspaceController.new,
    );

class NanobotWorkspaceController extends Notifier<NanobotWorkspaceState> {
  StreamSubscription<NanobotEvent>? _eventSubscription;
  StreamSubscription<Object?>? _statusSubscription;
  var _loadGeneration = 0;

  @override
  NanobotWorkspaceState build() {
    final repository = ref.watch(nanobotRepositoryProvider);
    _eventSubscription?.cancel();
    _statusSubscription?.cancel();
    _eventSubscription = repository.events.listen(_handleEvent);
    _statusSubscription = repository.status.listen((status) {
      state = state.copyWith(socketStatus: status);
    });
    ref.onDispose(() {
      _eventSubscription?.cancel();
      _statusSubscription?.cancel();
    });
    Future.microtask(initialize);
    return const NanobotWorkspaceState(isBootstrapping: true);
  }

  Future<void> initialize() async {
    final generation = ++_loadGeneration;
    state = state.copyWith(isBootstrapping: true, clearError: true);
    try {
      final repository = ref.read(nanobotRepositoryProvider);
      final bootstrap = await repository.bootstrap();
      await repository.connect();
      if (!_isActive(generation)) {
        return;
      }
      final sessions = await repository.listSessions();
      if (!_isActive(generation)) {
        return;
      }
      state = state.copyWith(
        sessions: sessions,
        modelName: bootstrap.modelName,
        isBootstrapping: false,
        socketStatus: repository.currentStatus,
        clearError: true,
      );
      if (sessions.isNotEmpty) {
        await selectSession(sessions.first);
      }
    } on Object catch (error) {
      if (!_isActive(generation)) {
        return;
      }
      state = state.copyWith(
        isBootstrapping: false,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> refreshSessions() async {
    try {
      final sessions = await ref.read(nanobotRepositoryProvider).listSessions();
      state = state.copyWith(sessions: sessions, clearError: true);
    } on Object catch (error) {
      state = state.copyWith(errorMessage: _friendlyError(error));
    }
  }

  Future<void> selectSession(NanobotSessionSummary session) async {
    final generation = ++_loadGeneration;
    state = state.copyWith(
      selectedSessionKey: session.key,
      selectedChatId: session.chatId,
      messages: const [],
      isLoadingThread: true,
      isStreaming: session.runStartedAt != null,
      clearReasoning: true,
      clearActivity: true,
      clearError: true,
    );
    try {
      final repository = ref.read(nanobotRepositoryProvider);
      await repository.attach(session.chatId);
      final messages = await repository.fetchThread(session);
      if (!_isActive(generation)) {
        return;
      }
      state = state.copyWith(
        messages: _recentMessages(messages),
        isLoadingThread: false,
        clearError: true,
      );
    } on Object catch (error) {
      if (!_isActive(generation)) {
        return;
      }
      state = state.copyWith(
        isLoadingThread: false,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> startNewSession() async {
    if (state.isBootstrapping || state.isLoadingThread) {
      return;
    }
    state = state.copyWith(
      isLoadingThread: true,
      clearSelectedSession: true,
      messages: const [],
      clearReasoning: true,
      clearActivity: true,
      clearError: true,
    );
    try {
      final chatId = await ref.read(nanobotRepositoryProvider).newChat();
      final session = NanobotSessionSummary(
        key: 'websocket:$chatId',
        channel: 'websocket',
        chatId: chatId,
        preview: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(
        sessions: [session, ...state.sessions],
        selectedSessionKey: session.key,
        selectedChatId: session.chatId,
        isLoadingThread: false,
        clearError: true,
      );
      unawaited(refreshSessions());
    } on Object catch (error) {
      state = state.copyWith(
        isLoadingThread: false,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> sendMessage(String input) async {
    final content = input.trim();
    if (content.isEmpty || !state.canSend) {
      return;
    }

    var chatId = state.selectedChatId;
    var sessionKey = state.selectedSessionKey;
    if (chatId == null || chatId.trim().isEmpty || sessionKey == null) {
      await startNewSession();
      chatId = state.selectedChatId;
      sessionKey = state.selectedSessionKey;
    }
    if (chatId == null || sessionKey == null) {
      return;
    }

    final userMessage = NanobotMessage(
      id: _newMessageId('user'),
      sessionKey: sessionKey,
      chatId: chatId,
      role: NanobotMessageRole.user,
      content: content,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isStreaming: true,
      clearReasoning: true,
      clearActivity: true,
      clearError: true,
    );

    try {
      await ref
          .read(nanobotRepositoryProvider)
          .sendMessage(chatId: chatId, content: content);
    } on Object catch (error) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          NanobotMessage(
            id: _newMessageId('error'),
            sessionKey: sessionKey,
            chatId: chatId,
            role: NanobotMessageRole.assistant,
            content: _friendlyError(error),
            createdAt: DateTime.now(),
            status: NanobotMessageStatus.failed,
          ),
        ],
        isStreaming: false,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> stopActiveTurn() async {
    final chatId = state.selectedChatId;
    if (chatId == null) {
      return;
    }
    await ref
        .read(nanobotRepositoryProvider)
        .sendMessage(chatId: chatId, content: '/stop');
    state = state.copyWith(isStreaming: false, clearReasoning: true);
  }

  void _handleEvent(NanobotEvent event) {
    switch (event.kind) {
      case NanobotEventKind.ready:
        state = state.copyWith(
          selectedChatId: state.selectedChatId ?? event.chatId,
          clearError: true,
        );
      case NanobotEventKind.attached:
        if (event.chatId == state.selectedChatId) {
          state = state.copyWith(clearError: true);
        }
      case NanobotEventKind.runtimeModelUpdated:
        state = state.copyWith(modelName: event.modelName);
      case NanobotEventKind.sessionUpdated:
        unawaited(refreshSessions());
      case NanobotEventKind.reasoningDelta:
        if (_isSelectedChat(event.chatId)) {
          state = state.copyWith(
            reasoningText: (state.reasoningText ?? '') + (event.text ?? ''),
            isStreaming: true,
          );
        }
      case NanobotEventKind.reasoningEnd:
        if (_isSelectedChat(event.chatId)) {
          state = state.copyWith(clearReasoning: true);
        }
      case NanobotEventKind.delta:
        if (_isSelectedChat(event.chatId)) {
          _appendAssistantDelta(event.text ?? '');
        }
      case NanobotEventKind.message:
        if (_isSelectedChat(event.chatId) &&
            (event.text ?? '').trim().isNotEmpty) {
          _appendCompleteAssistantMessage(event.text!);
        }
      case NanobotEventKind.streamEnd:
        if (_isSelectedChat(event.chatId)) {
          _completeStreamingAssistant();
        }
      case NanobotEventKind.goalStatus:
        if (_isSelectedChat(event.chatId)) {
          final isRunning = event.status == 'running';
          state = state.copyWith(
            activityText: isRunning ? event.status : null,
            isStreaming: isRunning || state.isStreaming,
            clearActivity: !isRunning,
          );
        }
      case NanobotEventKind.fileEdit:
        if (_isSelectedChat(event.chatId)) {
          state = state.copyWith(activityText: 'Editing files');
        }
      case NanobotEventKind.turnEnd:
        if (_isSelectedChat(event.chatId)) {
          _completeStreamingAssistant();
          state = state.copyWith(
            isStreaming: false,
            clearReasoning: true,
            clearActivity: true,
          );
          unawaited(refreshSessions());
        }
      case NanobotEventKind.error:
        state = state.copyWith(
          isStreaming: false,
          errorMessage: event.reason ?? event.detail ?? 'nanobot error',
        );
      case NanobotEventKind.transcriptionResult:
      case NanobotEventKind.transcriptionError:
      case NanobotEventKind.goalState:
      case NanobotEventKind.unknown:
        break;
    }
  }

  void _appendAssistantDelta(String delta) {
    if (delta.isEmpty) {
      return;
    }
    final sessionKey = state.selectedSessionKey;
    final chatId = state.selectedChatId;
    if (sessionKey == null || chatId == null) {
      return;
    }
    final messages = [...state.messages];
    final index = _lastStreamingAssistantIndex(messages);
    if (index >= 0) {
      final message = messages[index];
      messages[index] = message.copyWith(content: message.content + delta);
    } else {
      messages.add(
        NanobotMessage(
          id: _newMessageId('assistant'),
          sessionKey: sessionKey,
          chatId: chatId,
          role: NanobotMessageRole.assistant,
          content: delta,
          createdAt: DateTime.now(),
          status: NanobotMessageStatus.streaming,
        ),
      );
    }
    state = state.copyWith(messages: messages, isStreaming: true);
  }

  void _appendCompleteAssistantMessage(String text) {
    final sessionKey = state.selectedSessionKey;
    final chatId = state.selectedChatId;
    if (sessionKey == null || chatId == null) {
      return;
    }
    state = state.copyWith(
      messages: [
        ...state.messages,
        NanobotMessage(
          id: _newMessageId('assistant'),
          sessionKey: sessionKey,
          chatId: chatId,
          role: NanobotMessageRole.assistant,
          content: text,
          createdAt: DateTime.now(),
        ),
      ],
      isStreaming: false,
    );
  }

  void _completeStreamingAssistant() {
    final messages = [...state.messages];
    final index = _lastStreamingAssistantIndex(messages);
    if (index >= 0) {
      messages[index] = messages[index].copyWith(
        status: NanobotMessageStatus.completed,
      );
    }
    state = state.copyWith(messages: messages, isStreaming: false);
  }

  int _lastStreamingAssistantIndex(List<NanobotMessage> messages) {
    for (var i = messages.length - 1; i >= 0; i -= 1) {
      final message = messages[i];
      if (message.role == NanobotMessageRole.assistant &&
          message.status == NanobotMessageStatus.streaming) {
        return i;
      }
      if (message.role == NanobotMessageRole.user) {
        break;
      }
    }
    return -1;
  }

  bool _isSelectedChat(String? chatId) {
    return chatId == null || chatId == state.selectedChatId;
  }

  bool _isActive(int generation) {
    return generation == _loadGeneration;
  }

  List<NanobotMessage> _recentMessages(List<NanobotMessage> messages) {
    const maxInitialMessages = 80;
    if (messages.length <= maxInitialMessages) {
      return messages;
    }
    return messages.sublist(messages.length - maxInitialMessages);
  }

  String _newMessageId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }
}
