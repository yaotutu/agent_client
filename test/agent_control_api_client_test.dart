import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/domain/agent_control_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses api3 named-agent paths for agent-scoped endpoints', () async {
    final adapter = _RecordingAdapter({
      'GET /': {
        'object': 'list',
        'data': [
          {
            'name': 'coder',
            'wsPort': 8760,
            'gatewayPort': 18760,
            'workspaceDir': '/workspace',
            'model': 'MiniMax-M2.7-highspeed',
            'provider': 'minimax',
            'status': 'running',
            'health': 'healthy',
          },
        ],
      },
      'POST /agents': {
        'name': 'reviewer',
        'wsPort': 8762,
        'gatewayPort': 18762,
        'configPath': '/agents/reviewer/config.json',
        'workspaceDir': '/agents/reviewer/workspace',
        'model': 'MiniMax-M2.7-highspeed',
        'provider': 'minimax',
        'status': 'stopped',
      },
      'GET /agents/coder': {
        'name': 'coder',
        'protocol': 'agent-control/v1',
        'capabilities': ['sessions'],
        'wsPort': 8760,
        'gatewayPort': 18760,
        'workspaceDir': '/workspace',
        'state': {
          'status': 'idle',
          'defaultSessionId': null,
          'health': 'healthy',
        },
        'model': 'MiniMax-M2.7-highspeed',
        'provider': 'minimax',
      },
      'POST /agents/coder/sessions': {
        'sessionId': 'session-1',
        'title': 'New chat',
        'preview': '',
        'createdAt': '2026-05-29T11:02:30.246Z',
        'updatedAt': '2026-05-29T11:02:30.246Z',
        'messageCount': 0,
      },
      'GET /agents/coder/sessions': {
        'object': 'list',
        'data': [
          {
            'sessionId': 'session-1',
            'title': '你好，帮我看看代码',
            'preview': '你好，帮我看看代码',
            'createdAt': '2026-05-29T10:50:22.246Z',
            'updatedAt': '2026-05-29T10:50:41.644Z',
            'messageCount': 4,
            'status': 'idle',
          },
        ],
      },
      'POST /agents/coder/sessions/session-1/attach': {
        'sessionId': 'session-1',
        'attached': true,
      },
      'GET /agents/coder/sessions/session-1/messages': {
        'key': 'websocket:session-1',
        'messages': [],
      },
      'POST /agents/coder/agent/stop': {'accepted': true},
      'GET /agents/coder/agent/commands': {'object': 'list', 'data': []},
      'GET /agents/coder/agent/settings': {
        'agent': {
          'model': 'MiniMax-M2.7-highspeed',
          'provider': 'minimax',
          'has_api_key': true,
        },
        'providers': [
          {
            'name': 'minimax',
            'models': ['MiniMax-M2.7-highspeed'],
          },
        ],
        'requires_restart': false,
      },
      'GET /agents/coder/resources/tree': {
        'object': 'resources.tree',
        'path': '.',
        'children': [],
      },
      'GET /agents/coder/git/status': {
        'object': 'git.status',
        'isRepo': true,
        'branch': 'main',
        'upstream': null,
        'ahead': 0,
        'behind': 0,
        'clean': true,
        'data': [],
      },
      'DELETE /agents/coder': {'deleted': true, 'name': 'coder'},
    });
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test'))
      ..httpClientAdapter = adapter;
    final api = AgentControlApiClient(dio: dio);

    final agents = await api.listAgents();
    final createdAgent = await api.createAgent(
      name: 'reviewer',
      description: '代码审查助手',
    );
    final card = await api.getAgentCard('coder');
    final session = await api.createSession('coder');
    final sessions = await api.listSessions('coder');
    final attached = await api.attachSession(
      agentName: 'coder',
      sessionId: 'session-1',
    );
    await api.getSessionMessages(agentName: 'coder', sessionId: 'session-1');
    await api.stopAgentTask(agentName: 'coder', sessionId: 'session-1');
    await api.listCommands('coder');
    final settings = await api.getSettings('coder');
    await api.getResourceTree(agentName: 'coder');
    await api.getGitStatus('coder');
    final deletedAgent = await api.deleteAgent('coder');

    expect(agents.data.single.name, 'coder');
    expect(createdAgent.name, 'reviewer');
    expect(createdAgent.status, 'stopped');
    expect(card.workspace, '/workspace');
    expect(session.sessionId, 'session-1');
    expect(session.title, 'New chat');
    expect(session.messageCount, 0);
    expect(sessions.data.single.sessionId, 'session-1');
    expect(sessions.data.single.title, '你好，帮我看看代码');
    expect(sessions.data.single.messageCount, 4);
    expect(sessions.data.single.status, 'idle');
    expect(attached.attached, isTrue);
    expect(settings.agent.hasApiKey, isTrue);
    expect(settings.providers.single.models, ['MiniMax-M2.7-highspeed']);
    expect(deletedAgent.deleted, isTrue);
    expect(deletedAgent.name, 'coder');
    expect(adapter.seen, [
      'GET /',
      'POST /agents',
      'GET /agents/coder',
      'POST /agents/coder/sessions',
      'GET /agents/coder/sessions',
      'POST /agents/coder/sessions/session-1/attach',
      'GET /agents/coder/sessions/session-1/messages',
      'POST /agents/coder/agent/stop',
      'GET /agents/coder/agent/commands',
      'GET /agents/coder/agent/settings',
      'GET /agents/coder/resources/tree',
      'GET /agents/coder/git/status',
      'DELETE /agents/coder',
    ]);
  });

  test('explains browser network failures as likely CORS/config issues', () {
    final dio = Dio(BaseOptions(baseUrl: 'http://192.168.123.116:9800'))
      ..httpClientAdapter = _ThrowingAdapter(DioExceptionType.connectionError);
    final api = AgentControlApiClient(dio: dio, isWeb: true);

    expect(
      api.listAgents,
      throwsA(
        isA<AgentControlApiException>()
            .having(
              (error) => error.message,
              'message',
              contains('http://192.168.123.116:9800 must enable CORS'),
            )
            .having(
              (error) => error.message,
              'message',
              contains('Original error: fetch failed'),
            ),
      ),
    );
  });

  test('explains native network failures as unreachable backend', () {
    final dio = Dio(BaseOptions(baseUrl: 'http://192.168.123.116:9800'))
      ..httpClientAdapter = _ThrowingAdapter(DioExceptionType.connectionError);
    final api = AgentControlApiClient(dio: dio, isWeb: false);

    expect(
      api.listAgents,
      throwsA(
        isA<AgentControlApiException>()
            .having(
              (error) => error.message,
              'message',
              contains('reachable from this device'),
            )
            .having(
              (error) => error.message,
              'message',
              isNot(contains('CORS')),
            ),
      ),
    );
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.responses);

  final Map<String, Object?> responses;
  final seen = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method} ${options.path}';
    seen.add(key);
    final response = responses[key];
    if (response == null) {
      return ResponseBody.fromString(
        jsonEncode({
          'error': {'message': 'missing $key'},
        }),
        404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ThrowingAdapter implements HttpClientAdapter {
  const _ThrowingAdapter(this.type);

  final DioExceptionType type;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: type,
      message: 'fetch failed',
    );
  }

  @override
  void close({bool force = false}) {}
}
