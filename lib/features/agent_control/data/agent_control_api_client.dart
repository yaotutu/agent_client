import 'dart:convert';

import 'package:agent_client/core/network/dio_provider.dart';
import 'package:agent_client/features/agent_control/data/agent_control_sse_parser.dart';
import 'package:agent_client/features/agent_control/domain/agent_control_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final agentControlApiClientProvider = Provider<AgentControlApi>((ref) {
  return AgentControlApiClient(dio: ref.watch(dioProvider));
});

abstract interface class AgentControlApi {
  Future<AgentListResponse> listAgents();

  Future<HealthStatus> getHealth();

  Future<CreateAgentResponse> createAgent({
    required String name,
    String? description,
  });

  Future<AgentCard> getAgentCard(String agentName);

  Future<DeleteAgentResponse> deleteAgent(String agentName);

  Future<AgentLifecycleResponse> startAgent(String agentName);

  Future<AgentLifecycleResponse> stopAgentProcess(String agentName);

  Future<SoulUpdateResponse> updateSoul({
    required String agentName,
    required String content,
    String mode = 'append',
  });

  Future<CreateSessionResponse> createSession(String agentName);

  Future<SessionListResponse> listSessions(String agentName);

  Future<AttachSessionResponse> attachSession({
    required String agentName,
    required String sessionId,
  });

  Future<SessionMessages> getSessionMessages({
    required String agentName,
    required String sessionId,
  });

  Stream<AgentControlStreamEvent> sendMessageStream({
    required String agentName,
    required String sessionId,
    required String content,
    required CancelToken cancelToken,
  });

  Future<NonStreamMessageResponse> sendMessage({
    required String agentName,
    required String sessionId,
    required String content,
  });

  Future<void> deleteSession({
    required String agentName,
    required String sessionId,
  });

  Future<void> stopAgentTask({required String agentName, String? sessionId});

  Future<AgentCommandListResponse> listCommands(String agentName);

  Future<AgentSettings> getSettings(String agentName);

  Future<AgentSettings> updateSettings({
    required String agentName,
    String? model,
    String? provider,
  });

  Future<ResourceTree> getResourceTree({
    required String agentName,
    String path = '.',
  });

  Future<ResourceSearchResponse> searchResources({
    required String agentName,
    required String query,
    String path = '.',
    int limit = 100,
  });

  Future<ResourceFile> getResourceFile({
    required String agentName,
    required String path,
  });

  Future<ResourceFileWriteResult> putResourceFile({
    required String agentName,
    required String path,
    required String content,
  });

  Future<GitStatus> getGitStatus(String agentName);

  Future<GitDiff> getGitDiff({required String agentName, String path = '.'});
}

class AgentControlApiClient implements AgentControlApi {
  AgentControlApiClient({required this.dio, bool? isWeb})
    : isWeb = isWeb ?? kIsWeb;

  final Dio dio;
  final bool isWeb;

  @override
  Future<AgentListResponse> listAgents() {
    return _request(() async {
      final response = await dio.get<Object?>('/');
      return AgentListResponse.fromJson(_responseMap(response));
    });
  }

  @override
  Future<HealthStatus> getHealth() {
    return _request(() async {
      final response = await dio.get<Object?>('/health');
      return HealthStatus.fromJson(_responseMap(response));
    });
  }

  @override
  Future<CreateAgentResponse> createAgent({
    required String name,
    String? description,
  }) {
    return _request(() async {
      final data = {'name': name};
      if (description != null) {
        data['description'] = description;
      }
      final response = await dio.post<Object?>('/agents', data: data);
      return CreateAgentResponse.fromJson(_responseMap(response));
    });
  }

  @override
  Future<AgentCard> getAgentCard(String agentName) {
    return _request(() async {
      final response = await dio.get<Object?>('/agents/$agentName');
      return AgentCard.fromJson(_responseMap(response));
    });
  }

  @override
  Future<DeleteAgentResponse> deleteAgent(String agentName) {
    return _request(() async {
      final response = await dio.delete<Object?>('/agents/$agentName');
      return DeleteAgentResponse.fromJson(_responseMap(response));
    });
  }

  @override
  Future<AgentLifecycleResponse> startAgent(String agentName) {
    return _request(() async {
      final response = await dio.post<Object?>('/agents/$agentName/start');
      return AgentLifecycleResponse.fromJson(_responseMap(response));
    });
  }

  @override
  Future<AgentLifecycleResponse> stopAgentProcess(String agentName) {
    return _request(() async {
      final response = await dio.post<Object?>('/agents/$agentName/stop');
      return AgentLifecycleResponse.fromJson(_responseMap(response));
    });
  }

  @override
  Future<SoulUpdateResponse> updateSoul({
    required String agentName,
    required String content,
    String mode = 'append',
  }) {
    return _request(() async {
      final response = await dio.put<Object?>(
        '/agents/$agentName/soul',
        data: {'content': content, 'mode': mode},
      );
      return SoulUpdateResponse.fromJson(_responseMap(response));
    });
  }

  @override
  Future<CreateSessionResponse> createSession(String agentName) {
    return _request(() async {
      final response = await dio.post<Object?>('/agents/$agentName/sessions');
      return CreateSessionResponse.fromJson(_responseMap(response));
    });
  }

  @override
  Future<SessionListResponse> listSessions(String agentName) {
    return _request(() async {
      final response = await dio.get<Object?>('/agents/$agentName/sessions');
      return SessionListResponse.fromJson(_responseMap(response));
    });
  }

  @override
  Future<AttachSessionResponse> attachSession({
    required String agentName,
    required String sessionId,
  }) {
    return _request(() async {
      final response = await dio.post<Object?>(
        '/agents/$agentName/sessions/$sessionId/attach',
      );
      return AttachSessionResponse.fromJson(_responseMap(response));
    });
  }

  @override
  Future<SessionMessages> getSessionMessages({
    required String agentName,
    required String sessionId,
  }) {
    return _request(() async {
      final response = await dio.get<Object?>(
        '/agents/$agentName/sessions/$sessionId/messages',
      );
      return SessionMessages.fromJson(_responseMap(response));
    });
  }

  @override
  Stream<AgentControlStreamEvent> sendMessageStream({
    required String agentName,
    required String sessionId,
    required String content,
    required CancelToken cancelToken,
  }) async* {
    final response = await _request(() {
      return dio.post<ResponseBody>(
        '/agents/$agentName/sessions/$sessionId/messages',
        data: {'content': content, 'stream': true},
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: const {'Accept': 'text/event-stream'},
        ),
      );
    });

    final body = response.data;
    if (body == null) {
      throw const AgentControlApiException(message: 'Empty response stream');
    }

    final parser = AgentControlSseParser();
    await for (final chunk in body.stream.cast<List<int>>().transform(
      utf8.decoder,
    )) {
      for (final event in parser.parseChunk(chunk)) {
        yield event;
      }
    }
  }

  @override
  Future<NonStreamMessageResponse> sendMessage({
    required String agentName,
    required String sessionId,
    required String content,
  }) {
    return _request(() async {
      final response = await dio.post<Object?>(
        '/agents/$agentName/sessions/$sessionId/messages',
        data: {'content': content, 'stream': false},
      );
      return NonStreamMessageResponse.fromJson(_responseMap(response));
    });
  }

  @override
  Future<void> deleteSession({
    required String agentName,
    required String sessionId,
  }) {
    return _request(() async {
      await dio.delete<Object?>('/agents/$agentName/sessions/$sessionId');
    });
  }

  @override
  Future<void> stopAgentTask({required String agentName, String? sessionId}) {
    return _request(() async {
      await dio.post<Object?>(
        '/agents/$agentName/agent/stop',
        data: sessionId == null ? null : {'sessionId': sessionId},
      );
    });
  }

  @override
  Future<AgentCommandListResponse> listCommands(String agentName) {
    return _request(() async {
      final response = await dio.get<Object?>(
        '/agents/$agentName/agent/commands',
      );
      return AgentCommandListResponse.fromJson(_responseMap(response));
    });
  }

  @override
  Future<AgentSettings> getSettings(String agentName) {
    return _request(() async {
      final response = await dio.get<Object?>(
        '/agents/$agentName/agent/settings',
      );
      return AgentSettings.fromJson(_responseMap(response));
    });
  }

  @override
  Future<AgentSettings> updateSettings({
    required String agentName,
    String? model,
    String? provider,
  }) {
    return _request(() async {
      final data = <String, String>{};
      if (model != null) {
        data['model'] = model;
      }
      if (provider != null) {
        data['provider'] = provider;
      }
      final response = await dio.patch<Object?>(
        '/agents/$agentName/agent/settings',
        data: data,
      );
      return AgentSettings.fromJson(_responseMap(response));
    });
  }

  @override
  Future<ResourceTree> getResourceTree({
    required String agentName,
    String path = '.',
  }) {
    return _request(() async {
      final response = await dio.get<Object?>(
        '/agents/$agentName/resources/tree',
        queryParameters: {'path': path},
      );
      return ResourceTree.fromJson(_responseMap(response));
    });
  }

  @override
  Future<ResourceSearchResponse> searchResources({
    required String agentName,
    required String query,
    String path = '.',
    int limit = 100,
  }) {
    return _request(() async {
      final response = await dio.get<Object?>(
        '/agents/$agentName/resources/search',
        queryParameters: {'q': query, 'path': path, 'limit': limit},
      );
      return ResourceSearchResponse.fromJson(_responseMap(response));
    });
  }

  @override
  Future<ResourceFile> getResourceFile({
    required String agentName,
    required String path,
  }) {
    return _request(() async {
      final response = await dio.get<Object?>(
        '/agents/$agentName/resources/file',
        queryParameters: {'path': path},
      );
      return ResourceFile.fromJson(_responseMap(response));
    });
  }

  @override
  Future<ResourceFileWriteResult> putResourceFile({
    required String agentName,
    required String path,
    required String content,
  }) {
    return _request(() async {
      final response = await dio.put<Object?>(
        '/agents/$agentName/resources/file',
        data: {'path': path, 'content': content},
      );
      return ResourceFileWriteResult.fromJson(_responseMap(response));
    });
  }

  @override
  Future<GitStatus> getGitStatus(String agentName) {
    return _request(() async {
      final response = await dio.get<Object?>('/agents/$agentName/git/status');
      return GitStatus.fromJson(_responseMap(response));
    });
  }

  @override
  Future<GitDiff> getGitDiff({required String agentName, String path = '.'}) {
    return _request(() async {
      final response = await dio.get<Object?>(
        '/agents/$agentName/git/diff',
        queryParameters: {'path': path},
      );
      return GitDiff.fromJson(_responseMap(response));
    });
  }

  Future<T> _request<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      throw _apiException(error);
    }
  }

  AgentControlApiException _apiException(DioException error) {
    final data = error.response?.data;
    final statusCode = error.response?.statusCode;
    if (statusCode == null &&
        (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.unknown)) {
      final originalError = error.message ?? error.error;
      if (isWeb) {
        return AgentControlApiException(
          message:
              'Network request failed. Flutter Web sends requests through '
              'the browser, so ${dio.options.baseUrl} must enable CORS for '
              'this page. Original error: $originalError',
        );
      }
      return AgentControlApiException(
        message:
            'Network request failed. Check that ${dio.options.baseUrl} is '
            'reachable from this device and the backend process is running. '
            'Original error: $originalError',
      );
    }
    if (data is Map<String, Object?>) {
      return AgentControlApiException.fromJson(data, statusCode: statusCode);
    }
    if (data is Map) {
      return AgentControlApiException.fromJson(
        data.map((key, value) => MapEntry(key.toString(), value)),
        statusCode: statusCode,
      );
    }
    return AgentControlApiException(
      message: error.message ?? 'Network request failed',
      statusCode: statusCode,
    );
  }

  Map<String, Object?> _responseMap(Response<Object?> response) {
    final data = response.data;
    if (data is Map<String, Object?>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    throw const AgentControlApiException(message: 'Expected JSON object');
  }
}
