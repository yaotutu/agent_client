import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:agent_client/features/nanobot/data/nanobot_api_client.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('api client mirrors secondary webui endpoint paths', () async {
    final adapter = _RouteAdapter({
      'GET /webui/bootstrap': {
        'token': 'token-1',
        'ws_path': '/',
        'expires_in': 300,
      },
      'GET /api/settings': {
        'agent': {'model': 'm'},
        'requires_restart': false,
      },
      'GET /api/settings/usage': {'days': [], 'total_tokens': 10},
      'GET /api/settings/version-check': {
        'updateAvailable': {'latestVersion': '1.1.0'},
      },
      'GET /api/webui/skills': {
        'skills': [
          {'name': 'browser'},
        ],
      },
      'GET /api/webui/skills/current%20web': {
        'name': 'current web',
        'description': 'Browse',
        'source': 'builtin',
        'available': true,
      },
      'GET /api/settings/cli-apps': {
        'apps': [
          {'name': 'gimp'},
        ],
        'installed_count': 1,
      },
      'GET /api/settings/cli-apps?installed_only=1': {
        'apps': [
          {'name': 'gimp', 'installed': true},
        ],
        'installed_count': 1,
      },
      'GET /api/settings/nanobot-features': {
        'features': [
          {'name': 'matrix'},
        ],
        'enabled_count': 0,
      },
      'GET /api/settings/mcp-presets': {
        'presets': [
          {'name': 'github'},
        ],
        'installed_count': 1,
      },
      'GET /api/settings/provider-models?provider=openai': {
        'provider': 'openai',
        'label': 'OpenAI',
        'status': 'available',
        'catalog_kind': 'official',
        'models': [
          {'id': 'gpt-test'},
        ],
        'model_count': 1,
      },
      'GET /api/webui/automations': {
        'jobs': [
          {'id': 'job-1'},
        ],
      },
      'GET /api/sessions/websocket%3Achat-1/automations': {
        'jobs': [
          {'id': 'job-2'},
        ],
      },
      'GET /api/sessions/websocket%3Achat-1/delete?delete_automations=true': {
        'deleted': true,
      },
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://nanobot.test'));
    dio.httpClientAdapter = adapter;
    final client = NanobotApiClient(
      config: const NanobotConfig(
        baseUrl: 'https://nanobot.test',
        secret: 'redhat',
      ),
      dio: dio,
    );

    expect((await client.fetchSettings()).agent['model'], 'm');
    expect((await client.fetchSettingsUsage()).totalTokens, 10);
    expect(
      (await client.checkVersion()).updateAvailable?['latestVersion'],
      '1.1.0',
    );
    expect((await client.fetchSkills()).skills.single['name'], 'browser');
    expect((await client.fetchSkillDetail('current web')).name, 'current web');
    expect((await client.fetchCliApps()).installedCount, 1);
    expect(
      (await client.fetchInstalledCliApps()).apps.single['installed'],
      true,
    );
    expect(
      (await client.fetchNanobotFeatures()).features.single['name'],
      'matrix',
    );
    expect((await client.fetchMcpPresets()).presets.single['name'], 'github');
    expect(
      (await client.fetchProviderModels('openai')).models.single['id'],
      'gpt-test',
    );
    expect((await client.fetchAutomations()).jobs.single['id'], 'job-1');
    expect(
      (await client.fetchSessionAutomations(
        'websocket:chat-1',
      )).jobs.single['id'],
      'job-2',
    );
    expect(
      (await client.deleteSession(
        sessionKey: 'websocket:chat-1',
        deleteAutomations: true,
      )).deleted,
      isTrue,
    );

    expect(adapter.calls.first.headers['X-Nanobot-Auth'], 'redhat');
    expect(
      adapter.calls
          .skip(1)
          .every(
            (options) => options.headers['Authorization'] == 'Bearer token-1',
          ),
      isTrue,
    );
  });

  test('webui thread 404 maps to an empty thread snapshot', () async {
    final adapter = _RouteAdapter({
      'GET /webui/bootstrap': {
        'token': 'token-1',
        'ws_path': '/',
        'expires_in': 300,
      },
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://nanobot.test'));
    dio.httpClientAdapter = adapter;
    final client = NanobotApiClient(
      config: const NanobotConfig(
        baseUrl: 'https://nanobot.test',
        secret: 'redhat',
      ),
      dio: dio,
    );

    final page = await client.fetchWebuiThreadPage(
      sessionKey: 'websocket:missing',
    );
    final messages = await client.fetchWebuiThread(
      sessionKey: 'websocket:missing',
      chatId: 'missing',
    );

    expect(page.sessionKey, 'websocket:missing');
    expect(page.messages, isEmpty);
    expect(messages, isEmpty);
  });

  test(
    'api client sends apps action endpoints and mcp values header',
    () async {
      final adapter = _RouteAdapter({
        'GET /webui/bootstrap': {
          'token': 'token-1',
          'ws_path': '/',
          'expires_in': 300,
        },
        'GET /api/settings/cli-apps/test?name=gimp': {
          'apps': [
            {'name': 'gimp', 'installed': true},
          ],
        },
        'GET /api/settings/nanobot-features/enable?name=matrix': {
          'features': [
            {'name': 'matrix', 'enabled': true},
          ],
        },
        'GET /api/settings/mcp-presets/enable?name=browserbase': {
          'presets': [
            {'name': 'browserbase', 'configured': true},
          ],
        },
        'GET /api/settings/mcp-presets/custom': {
          'presets': [
            {'name': 'custom-server'},
          ],
        },
        'GET /api/settings/mcp-presets/import': {
          'presets': [
            {'name': 'imported-server'},
          ],
        },
        'GET /api/settings/mcp-presets/tools': {
          'presets': [
            {
              'name': 'browserbase',
              'enabled_tools': ['navigate'],
            },
          ],
        },
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://nanobot.test'));
      dio.httpClientAdapter = adapter;
      final client = NanobotApiClient(
        config: const NanobotConfig(
          baseUrl: 'https://nanobot.test',
          secret: 'redhat',
        ),
        dio: dio,
      );

      expect(
        (await client.runCliAppAction(
          action: 'test',
          name: 'gimp',
        )).apps.single['installed'],
        true,
      );
      expect(
        (await client.runNanobotFeatureAction(
          action: 'enable',
          name: 'matrix',
        )).features.single['enabled'],
        true,
      );
      expect(
        (await client.runMcpPresetAction(
          action: 'enable',
          name: 'browserbase',
          values: {'browserbase_api_key': ' bb_live_key ', 'empty': ''},
        )).presets.single['configured'],
        true,
      );
      expect(
        (await client.saveCustomMcpServer({
          'name': 'custom-server',
          'command': 'npx server',
        })).presets.single['name'],
        'custom-server',
      );
      expect(
        (await client.importMcpConfig(
          '{"mcpServers":{}}',
        )).presets.single['name'],
        'imported-server',
      );
      expect(
        (await client.updateMcpServerTools(
          name: 'browserbase',
          enabledTools: const ['navigate'],
        )).presets.single['enabled_tools'],
        ['navigate'],
      );

      final mcpEnableCall = adapter.calls.firstWhere(
        (options) => options.uri.path == '/api/settings/mcp-presets/enable',
      );
      expect(
        jsonDecode(mcpEnableCall.headers['X-Nanobot-MCP-Values'] as String),
        {'browserbase_api_key': 'bb_live_key'},
      );
      final customCall = adapter.calls.firstWhere(
        (options) => options.uri.path == '/api/settings/mcp-presets/custom',
      );
      expect(jsonDecode(customCall.headers['X-Nanobot-MCP-Values'] as String), {
        'name': 'custom-server',
        'command': 'npx server',
      });
      final importCall = adapter.calls.firstWhere(
        (options) => options.uri.path == '/api/settings/mcp-presets/import',
      );
      expect(jsonDecode(importCall.headers['X-Nanobot-MCP-Values'] as String), {
        'config': '{"mcpServers":{}}',
      });
      final toolsCall = adapter.calls.firstWhere(
        (options) => options.uri.path == '/api/settings/mcp-presets/tools',
      );
      expect(jsonDecode(toolsCall.headers['X-Nanobot-MCP-Values'] as String), {
        'name': 'browserbase',
        'enabled_tools': ['navigate'],
      });
    },
  );

  test('api client serializes automation actions and updates', () async {
    final adapter = _RouteAdapter({
      'GET /webui/bootstrap': {
        'token': 'token-1',
        'ws_path': '/',
        'expires_in': 300,
      },
      'GET /api/webui/automations/disable?id=job+1%2F2': {
        'jobs': [
          {'id': 'job-1', 'enabled': false},
        ],
      },
      'GET /api/webui/automations/update?id=job+1%2F2': {
        'jobs': [
          {'id': 'job-1', 'name': 'Updated job'},
        ],
      },
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://nanobot.test'));
    dio.httpClientAdapter = adapter;
    final client = NanobotApiClient(
      config: const NanobotConfig(
        baseUrl: 'https://nanobot.test',
        secret: 'redhat',
      ),
      dio: dio,
    );

    final disabled = await client.runAutomationAction(
      action: 'disable',
      id: 'job 1/2',
    );
    final updated = await client.updateAutomation(
      id: 'job 1/2',
      values: {
        'name': 'Updated job',
        'message': 'Keep going',
        'timezone': '',
        'schedule': null,
      },
    );

    expect(disabled.jobs.single['enabled'], isFalse);
    expect(updated.jobs.single['name'], 'Updated job');
    final updateCall = adapter.calls.last;
    expect(
      updateCall.headers['X-Nanobot-Automation-Values'],
      Uri.encodeComponent(
        jsonEncode({'name': 'Updated job', 'message': 'Keep going'}),
      ),
    );
  });
}

class _RouteAdapter implements HttpClientAdapter {
  _RouteAdapter(this.routes);

  final Map<String, Object?> routes;
  final List<RequestOptions> calls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    final key = _key(options);
    final body = routes[key];
    if (body == null) {
      return ResponseBody.fromString('missing route: $key', 404);
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}

  String _key(RequestOptions options) {
    final uri = options.uri;
    final query = uri.hasQuery ? '?${uri.query}' : '';
    return '${options.method} ${uri.path}$query';
  }
}
