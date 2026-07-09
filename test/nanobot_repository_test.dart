import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:agent_client/features/nanobot/data/nanobot_api_client.dart';
import 'package:agent_client/features/nanobot/data/nanobot_repository.dart';
import 'package:agent_client/features/nanobot/data/nanobot_ws_client.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_config.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_shell_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repository maps apps catalog across plugins cli and mcp', () async {
    final adapter = _RouteAdapter({
      'GET /webui/bootstrap': {
        'token': 'token-1',
        'ws_path': '/',
        'expires_in': 300,
      },
      'GET /api/settings/nanobot-features': {
        'features': [
          {
            'name': 'websocket',
            'display_name': 'WebSocket',
            'type': 'channel',
            'enabled': true,
            'ready': true,
            'installed': true,
          },
        ],
        'enabled_count': 1,
      },
      'GET /api/settings/cli-apps': {
        'apps': [
          {
            'name': 'gimp',
            'display_name': 'GIMP',
            'description': 'Image editor',
            'installed': true,
            'install_supported': true,
          },
        ],
        'installed_count': 1,
      },
      'GET /api/settings/mcp-presets': {
        'presets': [
          {
            'name': 'github',
            'display_name': 'GitHub',
            'description': 'Repository tools',
            'installed': true,
            'configured': true,
            'status': 'configured',
          },
        ],
        'installed_count': 1,
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

    final apps = await repository.fetchAppItems();

    expect(
      [for (final item in apps) item.id],
      ['cli:gimp', 'mcp:github', 'nanobot:websocket'],
    );
    expect(apps[0].title, 'GIMP');
    expect(apps[0].subtitle, 'Image editor');
    expect(apps[0].status, 'CLI');
    expect(apps[0].filterKeys, containsAll(['cli', 'ready']));
    expect(apps[1].status, 'Configured');
    expect(apps[1].filterKeys, containsAll(['mcp', 'ready']));
    expect(apps[2].subtitle, 'Required for WebUI');
    expect(apps[2].status, 'Channel');
    expect(apps[2].filterKeys, containsAll(['nanobot', 'ready']));
  });

  test(
    'repository keeps apps catalog when optional features endpoint is absent',
    () async {
      final adapter = _RouteAdapter({
        'GET /webui/bootstrap': {
          'token': 'token-1',
          'ws_path': '/',
          'expires_in': 300,
        },
        'GET /api/settings/cli-apps': {
          'apps': [
            {
              'name': 'blender',
              'display_name': 'Blender',
              'description': '3D modeling',
              'installed': false,
            },
          ],
        },
        'GET /api/settings/mcp-presets': {
          'presets': [
            {
              'name': 'browserbase',
              'display_name': 'Browserbase',
              'description': 'Cloud browser automation',
              'installed': false,
              'configured': false,
              'status': 'not_installed',
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

      final apps = await repository.fetchAppItems();

      expect([for (final item in apps) item.title], ['Blender', 'Browserbase']);
      expect(
        apps.every((item) => !item.filterKeys.contains('nanobot')),
        isTrue,
      );
    },
  );

  test('repository maps provider model catalog for settings picker', () async {
    final adapter = _RouteAdapter({
      'GET /webui/bootstrap': {
        'token': 'token-1',
        'ws_path': '/',
        'expires_in': 300,
      },
      'GET /api/settings/provider-models?provider=deepseek': {
        'provider': 'deepseek',
        'label': 'DeepSeek',
        'status': 'available',
        'catalog_kind': 'official',
        'models': [
          {
            'id': 'deepseek-chat',
            'owned_by': 'deepseek',
            'context_window': 65536,
          },
          {
            'id': 'deepseek-reasoner',
            'owned_by': 'deepseek',
            'context_window': 65536,
          },
        ],
        'model_count': 2,
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

    final catalog = await repository.fetchProviderModels('deepseek');

    expect(catalog.provider, 'deepseek');
    expect(catalog.label, 'DeepSeek');
    expect(catalog.status, 'available');
    expect(catalog.catalogKind, 'official');
    expect(catalog.modelCount, 2);
    expect(
      [for (final model in catalog.models) model.id],
      ['deepseek-chat', 'deepseek-reasoner'],
    );
    expect(catalog.models.last.ownedBy, 'deepseek');
    expect(catalog.models.last.contextWindow, 65536);
  });

  test('repository maps settings overview snapshot like webui', () async {
    final adapter = _RouteAdapter({
      'GET /webui/bootstrap': {
        'token': 'token-1',
        'ws_path': '/',
        'expires_in': 300,
      },
      'GET /api/settings': {
        'surface': 'native',
        'agent': {
          'model': 'MiniMax-M3',
          'provider': 'openai',
          'context_window_tokens': 262144,
          'timezone': 'Asia/Shanghai',
          'bot_name': 'Nanobot',
          'bot_icon': 'N',
          'project_path': '/home/user/project',
          'workspace_label': 'Project workspace',
        },
        'web_search': {
          'enabled': true,
          'provider': 'searxng',
          'max_results': 5,
        },
        'image_generation': {
          'enabled': true,
          'provider': 'openrouter',
          'model': 'google/gemini-flash-image',
        },
        'transcription': {
          'enabled': false,
          'provider': 'openai',
          'model': 'whisper-1',
        },
        'runtime': {
          'host': '127.0.0.1',
          'gateway_port': 8765,
          'config_path': '/tmp/nanobot.toml',
        },
        'advanced': {
          'webui_allow_local_service_access': false,
          'webui_default_access_mode': 'full',
        },
        'usage': {
          'days': [
            {
              'date': '2026-07-08',
              'total_tokens': 750,
              'estimated_tokens': 50,
              'requests': 4,
              'sources': {
                'user': {'total_tokens': 600},
                'cron': {'total_tokens': 150},
              },
            },
          ],
          'total_tokens': 1000,
          'total_tokens_30d': 900,
          'total_tokens_365d': 1000,
          'peak_day_tokens': 750,
          'current_streak_days': 2,
          'longest_streak_days': 4,
          'requests_30d': 12,
          'active_days_30d': 3,
        },
        'version': {'current': '1.2.3'},
        'requires_restart': true,
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

    final settings = await repository.fetchSettingsSnapshot();

    expect(settings.model, 'MiniMax-M3');
    expect(settings.provider, 'openai');
    expect(settings.contextWindowTokens, 262144);
    expect(settings.botName, 'Nanobot');
    expect(settings.botIcon, 'N');
    expect(settings.timezone, 'Asia/Shanghai');
    expect(settings.webSearchProvider, 'searxng');
    expect(settings.webSearchEnabled, isTrue);
    expect(settings.webSearchMaxResults, 5);
    expect(settings.imageGenerationEnabled, isTrue);
    expect(settings.imageGenerationProvider, 'openrouter');
    expect(settings.imageGenerationModel, 'google/gemini-flash-image');
    expect(settings.transcriptionEnabled, isFalse);
    expect(settings.transcriptionProvider, 'openai');
    expect(settings.transcriptionModel, 'whisper-1');
    expect(settings.runtimeHost, '127.0.0.1');
    expect(settings.runtimeGatewayPort, 8765);
    expect(settings.isNativeHostSurface, isTrue);
    expect(settings.webuiAllowLocalServiceAccess, isFalse);
    expect(settings.webuiDefaultAccessMode, 'full');
    expect(settings.workspaceCaption, 'Project workspace');
    expect(settings.usageDays, hasLength(1));
    expect(settings.usageDays.single.date, '2026-07-08');
    expect(settings.usageDays.single.totalTokens, 750);
    expect(settings.usageDays.single.estimatedTokens, 50);
    expect(settings.usageDays.single.requests, 4);
    expect(settings.usageDays.single.sources['user'], 600);
    expect(settings.totalTokens30d, 900);
    expect(settings.totalTokens365d, 1000);
    expect(settings.peakDayTokens, 750);
    expect(settings.currentStreakDays, 2);
    expect(settings.longestStreakDays, 4);
    expect(settings.requests30d, 12);
    expect(settings.activeDays30d, 3);
    expect(settings.requiresRestart, isTrue);
    expect(settings.version, '1.2.3');
  });

  test('repository maps version check result like webui', () async {
    final adapter = _RouteAdapter({
      'GET /webui/bootstrap': {
        'token': 'token-1',
        'ws_path': '/',
        'expires_in': 300,
      },
      'GET /api/settings/version-check': {
        'updateAvailable': {
          'currentVersion': '1.2.3',
          'latestVersion': '1.3.0',
          'pypiUrl': 'https://pypi.org/project/nanobot',
        },
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

    final result = await repository.checkVersion();

    expect(result.updateAvailable, isTrue);
    expect(result.currentVersion, '1.2.3');
    expect(result.latestVersion, '1.3.0');
    expect(result.pypiUrl, 'https://pypi.org/project/nanobot');
  });

  test('repository saves web search settings through webui endpoint', () async {
    final adapter = _RouteAdapter({
      'GET /webui/bootstrap': {
        'token': 'token-1',
        'ws_path': '/',
        'expires_in': 300,
      },
      'GET /api/settings/web-search/update?provider=searxng&max_results=7&timeout=11&use_jina_reader=true':
          {
            'agent': {'model': 'MiniMax-M3'},
            'web_search': {
              'provider': 'searxng',
              'max_results': 7,
              'timeout': 11,
            },
            'web': {
              'fetch': {'use_jina_reader': true},
            },
            'requires_restart': true,
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

    final settings = await repository.saveWebSearchSettings(
      provider: 'searxng',
      maxResults: 7,
      timeoutSeconds: 11,
      useJinaReader: true,
    );

    expect(
      adapter.requests.last.key,
      contains('/api/settings/web-search/update'),
    );
    expect(settings.webSearchProvider, 'searxng');
    expect(settings.webSearchMaxResults, 7);
    expect(settings.webSearchTimeoutSeconds, 11);
    expect(settings.webFetchUseJinaReader, isTrue);
    expect(settings.requiresRestart, isTrue);
  });

  test(
    'repository saves image generation settings through webui endpoint',
    () async {
      final adapter = _RouteAdapter({
        'GET /webui/bootstrap': {
          'token': 'token-1',
          'ws_path': '/',
          'expires_in': 300,
        },
        'GET /api/settings/image-generation/update?enabled=false&provider=openrouter&model=google%2Fgemini-flash-image&default_aspect_ratio=16%3A9&default_image_size=1024x1024&max_images_per_turn=3':
            {
              'agent': {'model': 'MiniMax-M3'},
              'image_generation': {
                'enabled': false,
                'provider': 'openrouter',
                'model': 'google/gemini-flash-image',
                'default_aspect_ratio': '16:9',
                'default_image_size': '1024x1024',
                'max_images_per_turn': 3,
                'save_dir': '/tmp/nanobot/images',
              },
              'requires_restart': true,
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

      final settings = await repository.saveImageGenerationSettings(
        enabled: false,
        provider: 'openrouter',
        model: 'google/gemini-flash-image',
        defaultAspectRatio: '16:9',
        defaultImageSize: '1024x1024',
        maxImagesPerTurn: 3,
      );

      expect(
        adapter.requests.last.key,
        contains('/api/settings/image-generation/update'),
      );
      expect(settings.imageGenerationEnabled, isFalse);
      expect(settings.imageGenerationProvider, 'openrouter');
      expect(settings.imageGenerationModel, 'google/gemini-flash-image');
      expect(settings.imageGenerationDefaultAspectRatio, '16:9');
      expect(settings.imageGenerationDefaultImageSize, '1024x1024');
      expect(settings.imageGenerationMaxImagesPerTurn, 3);
      expect(settings.imageGenerationSaveDir, '/tmp/nanobot/images');
      expect(settings.requiresRestart, isTrue);
    },
  );

  test(
    'repository saves transcription settings through webui endpoint',
    () async {
      final adapter = _RouteAdapter({
        'GET /webui/bootstrap': {
          'token': 'token-1',
          'ws_path': '/',
          'expires_in': 300,
        },
        'GET /api/settings/transcription/update?enabled=true&provider=groq&model=whisper-large-v3&language=zh&max_duration_sec=90&max_upload_mb=25':
            {
              'agent': {'model': 'MiniMax-M3'},
              'transcription': {
                'enabled': true,
                'provider': 'groq',
                'model': 'whisper-large-v3',
                'language': 'zh',
                'max_duration_sec': 90,
                'max_upload_mb': 25,
              },
              'requires_restart': true,
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

      final settings = await repository.saveTranscriptionSettings(
        enabled: true,
        provider: 'groq',
        model: 'whisper-large-v3',
        language: 'zh',
        maxDurationSec: 90,
        maxUploadMb: 25,
      );

      expect(
        adapter.requests.last.key,
        contains('/api/settings/transcription/update'),
      );
      expect(settings.transcriptionEnabled, isTrue);
      expect(settings.transcriptionProvider, 'groq');
      expect(settings.transcriptionModel, 'whisper-large-v3');
      expect(settings.transcriptionLanguage, 'zh');
      expect(settings.transcriptionMaxDurationSec, 90);
      expect(settings.transcriptionMaxUploadMb, 25);
      expect(settings.requiresRestart, isTrue);
    },
  );

  test(
    'repository saves network safety settings through webui endpoint',
    () async {
      final adapter = _RouteAdapter({
        'GET /webui/bootstrap': {
          'token': 'token-1',
          'ws_path': '/',
          'expires_in': 300,
        },
        'GET /api/settings/network-safety/update?webui_allow_local_service_access=false&webui_default_access_mode=full':
            {
              'agent': {'model': 'MiniMax-M3'},
              'advanced': {
                'webui_allow_local_service_access': false,
                'webui_default_access_mode': 'full',
              },
              'requires_restart': true,
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

      final settings = await repository.saveNetworkSafetySettings(
        webuiAllowLocalServiceAccess: false,
        webuiDefaultAccessMode: 'full',
      );

      expect(
        adapter.requests.last.key,
        contains('/api/settings/network-safety/update'),
      );
      expect(settings.webuiAllowLocalServiceAccess, isFalse);
      expect(settings.webuiDefaultAccessMode, 'full');
      expect(settings.requiresRestart, isTrue);
    },
  );

  test('repository saves runtime settings through webui endpoint', () async {
    final adapter = _RouteAdapter({
      'GET /webui/bootstrap': {
        'token': 'token-1',
        'ws_path': '/',
        'expires_in': 300,
      },
      'GET /api/settings/update?timezone=Asia%2FShanghai&bot_name=Nano+Mobile&bot_icon=N':
          {
            'agent': {
              'model': 'MiniMax-M3',
              'timezone': 'Asia/Shanghai',
              'bot_name': 'Nano Mobile',
              'bot_icon': 'N',
            },
            'requires_restart': true,
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

    final settings = await repository.saveRuntimeSettings(
      timezone: 'Asia/Shanghai',
      botName: 'Nano Mobile',
      botIcon: 'N',
    );

    expect(adapter.requests.last.key, contains('/api/settings/update'));
    expect(settings.timezone, 'Asia/Shanghai');
    expect(settings.botName, 'Nano Mobile');
    expect(settings.botIcon, 'N');
    expect(settings.requiresRestart, isTrue);
  });

  test(
    'repository saves default model settings through webui endpoint',
    () async {
      final adapter = _RouteAdapter({
        'GET /webui/bootstrap': {
          'token': 'token-1',
          'ws_path': '/',
          'expires_in': 300,
        },
        'GET /api/settings/update?model_preset=default&model=MiniMax-M4&provider=openai&context_window_tokens=131072':
            {
              'agent': {
                'model_preset': 'default',
                'model': 'MiniMax-M4',
                'provider': 'openai',
                'context_window_tokens': 131072,
              },
              'requires_restart': true,
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

      final settings = await repository.saveModelSettings(
        modelPreset: 'default',
        model: 'MiniMax-M4',
        provider: 'openai',
        contextWindowTokens: 131072,
      );

      expect(adapter.requests.last.key, contains('/api/settings/update'));
      expect(settings.modelPreset, 'default');
      expect(settings.model, 'MiniMax-M4');
      expect(settings.provider, 'openai');
      expect(settings.contextWindowTokens, 131072);
      expect(settings.requiresRestart, isTrue);
    },
  );

  test('repository maps apps action results by catalog kind', () async {
    final adapter = _RouteAdapter({
      'GET /webui/bootstrap': {
        'token': 'token-1',
        'ws_path': '/',
        'expires_in': 300,
      },
      'GET /api/settings/cli-apps/test?name=gimp': {
        'apps': [
          {
            'name': 'gimp',
            'display_name': 'GIMP',
            'description': 'Image editor',
            'installed': true,
          },
        ],
        'last_action': {'message': 'GIMP CLI is healthy'},
      },
      'GET /api/settings/nanobot-features/disable?name=matrix': {
        'features': [
          {
            'name': 'matrix',
            'display_name': 'Matrix',
            'type': 'channel',
            'enabled': false,
            'ready': false,
            'installed': true,
          },
        ],
        'requires_restart': true,
        'last_action': {'message': 'Matrix channel disabled'},
      },
      'GET /api/settings/mcp-presets/enable?name=browserbase': {
        'presets': [
          {
            'name': 'browserbase',
            'display_name': 'Browserbase',
            'description': 'Cloud browser automation',
            'installed': true,
            'configured': true,
            'status': 'configured',
          },
        ],
        'requires_restart': true,
        'last_action': {'message': 'Browserbase MCP enabled'},
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

    final cli = await repository.runCliAppAction(action: 'test', name: 'gimp');
    final feature = await repository.runNanobotFeatureAction(
      action: 'disable',
      name: 'matrix',
    );
    final mcp = await repository.runMcpPresetAction(
      action: 'enable',
      name: 'browserbase',
      values: const {'browserbase_api_key': 'bb_live_key'},
    );

    expect(cli.items.single.id, 'cli:gimp');
    expect(cli.items.single.status, 'CLI');
    expect(cli.items.single.filterKeys, containsAll(['cli', 'ready']));
    expect(cli.message, 'GIMP CLI is healthy');
    expect(cli.requiresRestart, isFalse);
    expect(feature.items.single.id, 'nanobot:matrix');
    expect(feature.items.single.subtitle, 'Channel is disabled');
    expect(
      feature.items.single.filterKeys,
      containsAll(['nanobot', 'unavailable']),
    );
    expect(feature.message, 'Matrix channel disabled');
    expect(feature.requiresRestart, isTrue);
    expect(mcp.items.single.id, 'mcp:browserbase');
    expect(mcp.items.single.status, 'Configured');
    expect(mcp.items.single.filterKeys, containsAll(['mcp', 'ready']));
    expect(mcp.message, 'Browserbase MCP enabled');
    expect(mcp.requiresRestart, isTrue);
  });

  test(
    'repository preserves mcp setup fields and tool scope metadata',
    () async {
      final adapter = _RouteAdapter({
        'GET /webui/bootstrap': {
          'token': 'token-1',
          'ws_path': '/',
          'expires_at': DateTime.now()
              .add(const Duration(hours: 1))
              .toIso8601String(),
        },
        'GET /api/settings/nanobot-features': {'features': <Object?>[]},
        'GET /api/settings/cli-apps': {'apps': <Object?>[]},
        'GET /api/settings/mcp-presets': {
          'presets': [
            {
              'name': 'browserbase',
              'display_name': 'Browserbase',
              'description': 'Cloud browser automation',
              'installed': true,
              'configured': false,
              'install_supported': true,
              'status': 'needs_setup',
              'required_fields': [
                {
                  'name': 'browserbase_api_key',
                  'label': 'API key',
                  'placeholder': 'Paste key',
                  'secret': true,
                  'required': true,
                  'configured': false,
                },
              ],
              'tool_names': ['browserbase_open', 'browserbase_click'],
              'enabled_tools': ['browserbase_open'],
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

      final items = await repository.fetchAppItems();
      final mcp = items.single;

      expect(mcp.id, 'mcp:browserbase');
      expect(
        mcp.filterKeys,
        containsAll(['mcp', 'unavailable', 'install_supported']),
      );
      expect(mcp.mcpRequiredFields.single.name, 'browserbase_api_key');
      expect(mcp.mcpRequiredFields.single.label, 'API key');
      expect(mcp.mcpRequiredFields.single.placeholder, 'Paste key');
      expect(mcp.mcpRequiredFields.single.secret, isTrue);
      expect(mcp.mcpRequiredFields.single.required, isTrue);
      expect(mcp.mcpRequiredFields.single.configured, isFalse);
      expect(mcp.mcpToolNames, ['browserbase_open', 'browserbase_click']);
      expect(mcp.mcpEnabledTools, ['browserbase_open']);
    },
  );

  test('repository maps mcp tool scope update results', () async {
    final adapter = _RouteAdapter({
      'GET /webui/bootstrap': {
        'token': 'token-1',
        'ws_path': '/',
        'expires_at': DateTime.now()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      },
      'GET /api/settings/mcp-presets/tools': {
        'presets': [
          {
            'name': 'github',
            'display_name': 'GitHub',
            'installed': true,
            'configured': true,
            'status': 'configured',
            'tool_names': ['repo_read', 'issue_create'],
            'enabled_tools': [],
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

    final items = await repository.updateMcpServerTools(
      name: 'github',
      enabledTools: const [],
    );

    expect(items.items.single.id, 'mcp:github');
    expect(items.items.single.mcpToolNames, ['repo_read', 'issue_create']);
    expect(items.items.single.mcpEnabledTools, isEmpty);
  });

  test('repository saves custom mcp servers and imports mcp config', () async {
    final adapter = _RouteAdapter({
      'GET /webui/bootstrap': {
        'token': 'token-1',
        'ws_path': '/',
        'expires_at': DateTime.now()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      },
      'GET /api/settings/mcp-presets/custom': {
        'presets': [
          {
            'name': 'docs',
            'display_name': 'docs',
            'description': 'Custom docs server',
            'installed': true,
            'configured': true,
            'status': 'configured',
          },
        ],
      },
      'GET /api/settings/mcp-presets/import': {
        'presets': [
          {
            'name': 'filesystem',
            'display_name': 'filesystem',
            'description': 'Imported server',
            'installed': true,
            'configured': true,
            'status': 'configured',
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

    final custom = await repository.saveCustomMcpServer(
      values: const {
        'name': 'docs',
        'transport': 'stdio',
        'command': 'npx',
        'args': '["-y","docs-mcp"]',
        'env': '{"API_KEY":"secret"}',
        'headers': '',
        'tool_timeout': '30',
      },
    );
    final imported = await repository.importMcpConfig(
      '{"mcpServers":{"filesystem":{"command":"npx"}}}',
    );

    expect(custom.items.single.id, 'mcp:docs');
    expect(imported.items.single.id, 'mcp:filesystem');
    expect(adapter.requests[1].key, 'GET /api/settings/mcp-presets/custom');
    expect(adapter.requests[1].mcpValues?['name'], 'docs');
    expect(adapter.requests[1].mcpValues?['command'], 'npx');
    expect(adapter.requests[1].mcpValues?['tool_timeout'], '30');
    expect(adapter.requests[2].key, 'GET /api/settings/mcp-presets/import');
    expect(
      adapter.requests[2].mcpValues?['config'],
      '{"mcpServers":{"filesystem":{"command":"npx"}}}',
    );
  });

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
    expect(automations.single.status, 'No schedule');
  });

  test('repository maps automation filter keys', () async {
    final adapter = _RouteAdapter({
      'GET /webui/bootstrap': {
        'token': 'token-1',
        'ws_path': '/',
        'expires_in': 300,
      },
      'GET /api/webui/automations': {
        'jobs': [
          {
            'id': 'active',
            'name': 'Active job',
            'enabled': true,
            'state': {'next_run_at_ms': 1, 'last_status': 'ok'},
          },
          {
            'id': 'paused',
            'name': 'Paused job',
            'enabled': false,
            'state': {'last_status': 'ok'},
          },
          {
            'id': 'failed',
            'name': 'Failed job',
            'enabled': true,
            'state': {'last_status': 'error'},
          },
          {
            'id': 'system',
            'name': 'System job',
            'enabled': true,
            'protected': true,
            'state': {'last_status': 'ok'},
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

    expect(automations[0].filterKeys, contains('active'));
    expect(automations[1].filterKeys, contains('paused'));
    expect(automations[2].filterKeys, contains('failed'));
    expect(automations[3].filterKeys, contains('system'));
  });

  test(
    'repository maps automation status and schedule labels like webui',
    () async {
      final adapter = _RouteAdapter({
        'GET /webui/bootstrap': {
          'token': 'token-1',
          'ws_path': '/',
          'expires_in': 300,
        },
        'GET /api/webui/automations': {
          'jobs': [
            {
              'id': 'active',
              'name': 'Active job',
              'enabled': true,
              'schedule': {'kind': 'cron', 'expr': '0 9 * * *'},
              'state': {'next_run_at_ms': 1, 'last_status': 'ok'},
            },
            {
              'id': 'running',
              'name': 'Running job',
              'enabled': true,
              'schedule': {'kind': 'cron', 'expr': '15 * * * *'},
              'state': {'pending': true, 'last_status': 'ok'},
            },
            {
              'id': 'paused',
              'name': 'Paused job',
              'enabled': false,
              'schedule': {'kind': 'every', 'every_ms': 3600000},
              'state': {'last_status': 'ok'},
            },
            {
              'id': 'failed',
              'name': 'Failed job',
              'enabled': true,
              'schedule': {'kind': 'cron', 'expr': '*/5 * * * *'},
              'state': {'last_status': 'error'},
            },
            {
              'id': 'completed',
              'name': 'Completed job',
              'enabled': true,
              'delete_after_run': true,
              'schedule': {'kind': 'at', 'at_ms': 2000},
              'state': {'last_status': 'ok'},
            },
            {
              'id': 'idle',
              'name': 'Idle job',
              'enabled': true,
              'schedule': {'kind': 'unknown'},
              'state': {'last_status': 'ok'},
            },
            {
              'id': 'system',
              'name': 'System job',
              'enabled': true,
              'protected': true,
              'schedule': {'kind': 'local'},
              'state': {'last_status': 'ok'},
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

      expect(automations.map((item) => item.status), [
        'Active',
        'Running now',
        'Paused',
        'Failed',
        'Completed',
        'No schedule',
        'System',
      ]);
      expect(automations[0].scheduleLabel, 'Daily at 09:00');
      expect(automations[1].scheduleLabel, 'Hourly at :15');
      expect(automations[2].scheduleLabel, 'Every 1 hour');
      expect(automations[3].scheduleLabel, 'Cron */5 * * * *');
      expect(automations[6].scheduleLabel, 'Local trigger');
    },
  );

  test('repository maps automation sort timestamps', () async {
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
            'name': 'Sort probe',
            'enabled': true,
            'updated_at_ms': 3000,
            'state': {
              'next_run_at_ms': 1000,
              'last_run_at_ms': 2000,
              'last_status': 'ok',
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

    expect(automations.single.nextRunAtMs, 1000);
    expect(automations.single.lastRunAtMs, 2000);
    expect(automations.single.updatedAtMs, 3000);
  });

  test('repository maps automation detail panel metadata', () async {
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
            'name': 'Detail probe',
            'enabled': true,
            'protected': true,
            'delete_after_run': true,
            'created_at_ms': 1000,
            'updated_at_ms': 3000,
            'schedule': {
              'kind': 'every',
              'every_ms': 7200000,
              'tz': 'Asia/Shanghai',
            },
            'payload': {'message': 'Check the repo status'},
            'origin': {
              'channel': 'websocket',
              'session_key': 'websocket:chat-1',
              'title': 'Release prep',
            },
            'state': {
              'next_run_at_ms': 4000,
              'last_run_at_ms': 2000,
              'last_error': 'Timed out',
              'pending': true,
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
    final item = automations.single;

    expect(item.scheduleLabel, 'Every 2 hours');
    expect(item.originLabel, 'Release prep');
    expect(item.originSessionKey, 'websocket:chat-1');
    expect(item.createdAtMs, 1000);
    expect(item.updatedAtMs, 3000);
    expect(item.lastError, 'Timed out');
    expect(item.isPending, isTrue);
    expect(item.isProtected, isTrue);
    expect(item.deleteAfterRun, isTrue);
    expect(item.automationScheduleKind, 'every');
    expect(item.automationEveryMs, 7200000);
    expect(item.automationTz, 'Asia/Shanghai');
    expect(item.isLocalTriggerAutomation, isFalse);
  });

  test('repository maps automation action results', () async {
    final adapter = _RouteAdapter({
      'GET /webui/bootstrap': {
        'token': 'token-1',
        'ws_path': '/',
        'expires_in': 300,
      },
      'GET /api/webui/automations/enable?id=job-1': {
        'jobs': [
          {
            'id': 'job-1',
            'name': 'Enabled job',
            'enabled': true,
            'state': {'next_run_at_ms': 1000},
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

    final automations = await repository.runAutomationAction(
      action: NanobotAutomationAction.enable,
      id: 'job-1',
    );

    expect(automations.single.title, 'Enabled job');
    expect(automations.single.status, 'Active');
    expect(automations.single.nextRunAtMs, 1000);
  });
}

class _RouteAdapter implements HttpClientAdapter {
  _RouteAdapter(this.routes);

  final Map<String, Object?> routes;
  final requests = <_RouteRequest>[];

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
    requests.add(
      _RouteRequest(
        key,
        _decodeMcpValues(options.headers['X-Nanobot-MCP-Values']),
      ),
    );
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

  Map<String, Object?>? _decodeMcpValues(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return Map<String, Object?>.from(jsonDecode(value) as Map);
  }
}

class _RouteRequest {
  const _RouteRequest(this.key, this.mcpValues);

  final String key;
  final Map<String, Object?>? mcpValues;
}
