import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:agent_client/features/nanobot/data/nanobot_api_client.dart';
import 'package:agent_client/features/nanobot/data/nanobot_repository.dart';
import 'package:agent_client/features/nanobot/data/nanobot_ws_client.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'repository maps unavailable skill reasons for catalog display',
    () async {
      final adapter = _RouteAdapter({
        'GET /webui/bootstrap': {
          'token': 'token-1',
          'ws_path': '/',
          'expires_in': 300,
        },
        'GET /api/webui/skills': {
          'skills': [
            {
              'name': 'github',
              'description': 'Work with GitHub.',
              'source': 'builtin',
              'available': false,
              'unavailable_reason': 'CLI: gh',
            },
          ],
        },
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://nanobot.test'));
      dio.httpClientAdapter = adapter;
      final config = const NanobotConfig(
        baseUrl: 'https://nanobot.test',
        secret: 'redhat',
      );
      final api = NanobotApiClient(config: config, dio: dio);
      final repository = NanobotRepository(
        api: api,
        ws: NanobotWsClient(config: config, bootstrap: api.bootstrap),
      );

      final skills = await repository.fetchSkillItems();

      expect(skills.single.title, 'github');
      expect(skills.single.subtitle, 'Work with GitHub.');
      expect(skills.single.status, 'Missing: CLI: gh');
    },
  );

  test('repository maps skill detail requirements and raw markdown', () async {
    final adapter = _RouteAdapter({
      'GET /webui/bootstrap': {
        'token': 'token-1',
        'ws_path': '/',
        'expires_in': 300,
      },
      'GET /api/webui/skills/github': {
        'name': 'github',
        'description': 'Work with GitHub.',
        'source': 'builtin',
        'available': false,
        'unavailable_reason': 'CLI: gh',
        'requirements': {
          'bins': ['gh'],
          'missing_bins': ['gh'],
          'env': ['GITHUB_TOKEN'],
          'missing_env': ['GITHUB_TOKEN'],
        },
        'raw_markdown': '# GitHub',
      },
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://nanobot.test'));
    dio.httpClientAdapter = adapter;
    final config = const NanobotConfig(
      baseUrl: 'https://nanobot.test',
      secret: 'redhat',
    );
    final api = NanobotApiClient(config: config, dio: dio);
    final repository = NanobotRepository(
      api: api,
      ws: NanobotWsClient(config: config, bootstrap: api.bootstrap),
    );

    final detail = await repository.fetchSkillDetail('github');

    expect(detail.name, 'github');
    expect(detail.description, 'Work with GitHub.');
    expect(detail.source, 'builtin');
    expect(detail.available, isFalse);
    expect(detail.unavailableReason, 'CLI: gh');
    expect(detail.bins, ['gh']);
    expect(detail.missingBins, ['gh']);
    expect(detail.env, ['GITHUB_TOKEN']);
    expect(detail.missingEnv, ['GITHUB_TOKEN']);
    expect(detail.rawMarkdown, '# GitHub');
  });

  test('repository maps automation message and origin details', () async {
    final adapter = _RouteAdapter({
      'GET /webui/bootstrap': {
        'token': 'token-1',
        'ws_path': '/',
        'expires_in': 300,
      },
      'GET /api/webui/automations': {
        'jobs': [
          {
            'id': 'job-1',
            'name': 'Daily repo check',
            'enabled': true,
            'schedule': {'kind': 'every', 'every_ms': 86400000},
            'payload': {'message': 'Check the repo status'},
            'origin': {
              'channel': 'websocket',
              'title': 'Release prep',
              'preview': 'Check release blockers',
            },
          },
        ],
      },
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://nanobot.test'));
    dio.httpClientAdapter = adapter;
    final config = const NanobotConfig(
      baseUrl: 'https://nanobot.test',
      secret: 'redhat',
    );
    final api = NanobotApiClient(config: config, dio: dio);
    final repository = NanobotRepository(
      api: api,
      ws: NanobotWsClient(config: config, bootstrap: api.bootstrap),
    );

    final automations = await repository.fetchAutomationItems();

    expect(automations.single.title, 'Daily repo check');
    expect(automations.single.subtitle, 'Check the repo status');
    expect(automations.single.details, 'Release prep');
    expect(automations.single.status, 'enabled');
  });
}

class _RouteAdapter implements HttpClientAdapter {
  _RouteAdapter(this.routes);

  final Map<String, Object?> routes;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    final query = options.uri.query;
    final key = '${options.method} $path${query.isEmpty ? '' : '?$query'}';
    final payload = routes[key];
    if (!routes.containsKey(key)) {
      return ResponseBody.fromString(
        jsonEncode({'error': 'not found', 'key': key}),
        404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
