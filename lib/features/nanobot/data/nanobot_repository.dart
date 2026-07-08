import 'package:agent_client/features/nanobot/data/nanobot_api_client.dart';
import 'package:agent_client/features/nanobot/data/protocol/nanobot_http_dto.dart';
import 'package:agent_client/features/nanobot/data/protocol/nanobot_ws_envelope.dart';
import 'package:agent_client/features/nanobot/data/nanobot_ws_client.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_bootstrap.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_event.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_message.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';

abstract class NanobotRepositoryPort {
  Stream<NanobotEvent> get events;

  Stream<NanobotSocketStatus> get status;

  NanobotSocketStatus get currentStatus;

  Future<NanobotBootstrap> bootstrap({bool forceRefresh = false});

  Future<void> connect();

  Future<List<NanobotSessionSummary>> listSessions();

  Future<List<NanobotMessage>> fetchThread(NanobotSessionSummary session);

  Future<String> newChat();

  Future<void> attach(String chatId);

  Future<void> sendMessage({required String chatId, required String content});

  Future<void> dispose();
}

class NanobotRepository implements NanobotRepositoryPort {
  const NanobotRepository({required this.api, required this.ws});

  final NanobotApiClient api;
  final NanobotWsClient ws;

  @override
  Stream<NanobotEvent> get events => ws.events;

  @override
  Stream<NanobotSocketStatus> get status => ws.status;

  @override
  NanobotSocketStatus get currentStatus => ws.currentStatus;

  @override
  Future<NanobotBootstrap> bootstrap({bool forceRefresh = false}) {
    return api.bootstrap(forceRefresh: forceRefresh);
  }

  @override
  Future<void> connect() => ws.connect();

  @override
  Future<List<NanobotSessionSummary>> listSessions() => api.listSessions();

  @override
  Future<List<NanobotMessage>> fetchThread(NanobotSessionSummary session) {
    return api.fetchWebuiThread(
      sessionKey: session.key,
      chatId: session.chatId,
    );
  }

  Future<NanobotWebuiThreadDto> fetchThreadPage({
    required String sessionKey,
    int limit = 120,
    String? before,
  }) {
    return api.fetchWebuiThreadPage(
      sessionKey: sessionKey,
      limit: limit,
      before: before,
    );
  }

  Future<NanobotFilePreviewDto> fetchFilePreview({
    required String sessionKey,
    required String path,
  }) {
    return api.fetchFilePreview(sessionKey: sessionKey, path: path);
  }

  Future<NanobotWorkspacesDto> fetchWorkspaces() => api.fetchWorkspaces();

  Future<List<NanobotSlashCommandDto>> listSlashCommands() {
    return api.listSlashCommands();
  }

  Future<NanobotSidebarStateDto> fetchSidebarState() {
    return api.fetchSidebarState();
  }

  Future<NanobotSidebarStateDto> updateSidebarState(
    NanobotSidebarStateDto state,
  ) {
    return api.updateSidebarState(state);
  }

  @override
  Future<String> newChat() => ws.newChat();

  @override
  Future<void> attach(String chatId) => ws.attach(chatId);

  @override
  Future<void> sendMessage({required String chatId, required String content}) {
    return ws.sendMessage(chatId: chatId, content: content);
  }

  Future<String> forkChat({
    required String sourceChatId,
    required int beforeUserIndex,
    String? title,
  }) {
    return ws.forkChat(
      sourceChatId: sourceChatId,
      beforeUserIndex: beforeUserIndex,
      title: title,
    );
  }

  Future<void> setWorkspaceScope({
    required String chatId,
    required Map<String, Object?> workspaceScope,
  }) {
    return ws.setWorkspaceScope(chatId: chatId, workspaceScope: workspaceScope);
  }

  Future<String> transcribeAudio({
    required String requestId,
    required String dataUrl,
    int? durationMs,
  }) {
    return ws.transcribeAudio(
      requestId: requestId,
      dataUrl: dataUrl,
      durationMs: durationMs,
    );
  }

  Future<void> sendRichMessage({
    required String chatId,
    required String content,
    List<NanobotOutboundMedia> media = const [],
    NanobotOutboundImageGeneration? imageGeneration,
    List<NanobotOutboundMention> cliApps = const [],
    List<NanobotOutboundMention> mcpPresets = const [],
    Map<String, Object?>? workspaceScope,
    String? turnId,
  }) {
    return ws.sendMessage(
      chatId: chatId,
      content: content,
      media: media,
      imageGeneration: imageGeneration,
      cliApps: cliApps,
      mcpPresets: mcpPresets,
      workspaceScope: workspaceScope,
      turnId: turnId,
    );
  }

  @override
  Future<void> dispose() => ws.dispose();
}
