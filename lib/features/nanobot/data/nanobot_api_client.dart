import 'package:agent_client/features/nanobot/domain/nanobot_bootstrap.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_config.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_message.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';
import 'package:dio/dio.dart';

class NanobotApiClient {
  NanobotApiClient({required NanobotConfig config, Dio? dio})
    : _config = config,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: config.baseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 20),
              headers: const {'Accept': 'application/json'},
            ),
          );

  final NanobotConfig _config;
  final Dio _dio;
  NanobotBootstrap? _bootstrap;

  NanobotConfig get config => _config;

  Future<NanobotBootstrap> bootstrap({bool forceRefresh = false}) async {
    final cached = _bootstrap;
    if (!forceRefresh && cached != null && !cached.shouldRefresh) {
      return cached;
    }

    final response = await _dio.get<Object?>(
      '/webui/bootstrap',
      options: Options(
        headers: _config.secret.trim().isEmpty
            ? null
            : {'X-Nanobot-Auth': _config.secret.trim()},
      ),
    );
    final data = _asMap(response.data);
    final next = NanobotBootstrap.fromJson(data);
    _bootstrap = next;
    return next;
  }

  Future<List<NanobotSessionSummary>> listSessions() async {
    final response = await _dio.get<Object?>(
      '/api/sessions',
      options: await _authOptions(),
    );
    final data = _asMap(response.data);
    final rows = data['sessions'];
    if (rows is! List) {
      return const [];
    }
    return [
      for (final row in rows)
        if (row is Map)
          NanobotSessionSummary.fromJson(Map<String, Object?>.from(row)),
    ];
  }

  Future<List<NanobotMessage>> fetchWebuiThread({
    required String sessionKey,
    required String chatId,
    int limit = 120,
  }) async {
    final response = await _dio.get<Object?>(
      '/api/sessions/${Uri.encodeComponent(sessionKey)}/webui-thread',
      queryParameters: {'limit': limit, 'direction': 'latest'},
      options: await _authOptions(),
    );
    final data = _asMap(response.data);
    final rows = data['messages'];
    if (rows is! List) {
      return const [];
    }
    return [
      for (final row in rows)
        if (row is Map)
          NanobotMessage.fromWebuiJson(
            json: Map<String, Object?>.from(row),
            sessionKey: sessionKey,
            chatId: chatId,
          ),
    ];
  }

  Future<Options> _authOptions() async {
    final token = (await bootstrap()).token;
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Map<String, Object?> _asMap(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      return Map<String, Object?>.from(value);
    }
    throw const FormatException('nanobot API returned non-object JSON');
  }
}
