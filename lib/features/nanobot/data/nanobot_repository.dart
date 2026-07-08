import 'package:agent_client/features/nanobot/data/nanobot_api_client.dart';
import 'package:agent_client/features/nanobot/data/nanobot_ws_client.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_bootstrap.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_event.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_message.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';

class NanobotRepository {
  const NanobotRepository({required this.api, required this.ws});

  final NanobotApiClient api;
  final NanobotWsClient ws;

  Stream<NanobotEvent> get events => ws.events;

  Stream<NanobotSocketStatus> get status => ws.status;

  NanobotSocketStatus get currentStatus => ws.currentStatus;

  Future<NanobotBootstrap> bootstrap({bool forceRefresh = false}) {
    return api.bootstrap(forceRefresh: forceRefresh);
  }

  Future<void> connect() => ws.connect();

  Future<List<NanobotSessionSummary>> listSessions() => api.listSessions();

  Future<List<NanobotMessage>> fetchThread(NanobotSessionSummary session) {
    return api.fetchWebuiThread(
      sessionKey: session.key,
      chatId: session.chatId,
    );
  }

  Future<String> newChat() => ws.newChat();

  Future<void> attach(String chatId) => ws.attach(chatId);

  Future<void> sendMessage({required String chatId, required String content}) {
    return ws.sendMessage(chatId: chatId, content: content);
  }

  Future<void> dispose() => ws.dispose();
}
