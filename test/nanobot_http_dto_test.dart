import 'package:agent_client/features/nanobot/data/protocol/nanobot_http_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('webui thread dto preserves paging and workspace metadata', () {
    final dto = NanobotWebuiThreadDto.fromJson({
      'schemaVersion': 1,
      'sessionKey': 'websocket:chat-1',
      'savedAt': '2026-07-08T10:00:00Z',
      'messages': [
        {'id': 'm1', 'role': 'user', 'content': 'hello'},
      ],
      'fork_boundary_message_count': 2,
      'has_pending_tool_calls': true,
      'page': {
        'before_cursor': 'cursor-1',
        'has_more_before': true,
        'loaded_message_count': 1,
        'total_known_message_count': 20,
        'user_message_offset': 4,
      },
      'workspace_scope': {
        'project_path': '/tmp/app',
        'project_name': 'app',
        'access_mode': 'restricted',
      },
    });

    expect(dto.schemaVersion, 1);
    expect(dto.sessionKey, 'websocket:chat-1');
    expect(dto.messages.single['id'], 'm1');
    expect(dto.forkBoundaryMessageCount, 2);
    expect(dto.hasPendingToolCalls, isTrue);
    expect(dto.page?.beforeCursor, 'cursor-1');
    expect(dto.page?.hasMoreBefore, isTrue);
    expect(dto.page?.userMessageOffset, 4);
    expect(dto.workspaceScope?.projectPath, '/tmp/app');
  });

  test('workspace dto maps default scope and controls', () {
    final dto = NanobotWorkspacesDto.fromJson({
      'default_scope': {
        'project_path': '/tmp/app',
        'project_name': 'app',
        'access_mode': 'restricted',
      },
      'controls': {'can_change_project': true, 'can_change_access': false},
      'recent': [
        {
          'project_path': '/tmp/other',
          'project_name': 'other',
          'access_mode': 'full',
        },
      ],
    });

    expect(dto.defaultScope.projectPath, '/tmp/app');
    expect(dto.defaultScope.accessMode, 'restricted');
    expect(dto.controls?['can_change_project'], isTrue);
    expect(dto.recent.single.projectName, 'other');
  });

  test('sidebar state dto normalizes missing fields', () {
    final dto = NanobotSidebarStateDto.fromJson({
      'pinned_keys': ['websocket:chat-1'],
      'title_overrides': {'websocket:chat-1': 'Pinned'},
      'view': {
        'density': 'compact',
        'sort': 'title_asc',
        'show_previews': true,
        'show_timestamps': true,
      },
    });

    expect(dto.pinnedKeys, ['websocket:chat-1']);
    expect(dto.archivedKeys, isEmpty);
    expect(dto.titleOverrides['websocket:chat-1'], 'Pinned');
    expect(dto.projectNameOverrides, isEmpty);
    expect(dto.view.density, 'compact');
    expect(dto.view.sort, 'title_asc');
    expect(dto.view.showPreviews, isTrue);
    expect(dto.view.showTimestamps, isTrue);
    expect(dto.view.showArchived, isFalse);
    expect(dto.toJson()['pinned_keys'], ['websocket:chat-1']);
    expect(
      (dto.toJson()['view'] as Map<String, Object?>)['show_previews'],
      isTrue,
    );
  });

  test('slash command dto keeps supported lifecycle rows only', () {
    final commands = NanobotSlashCommandDto.listFromJson({
      'commands': [
        {
          'command': '/stop',
          'title': 'Stop',
          'description': 'Stop active turn',
          'icon': 'stop',
          'lifecycle': 'stop_active_turn',
          'accepts_args': false,
        },
        {
          'command': '/help',
          'title': 'Show help',
          'description': 'List available slash commands.',
          'icon': 'circle-help',
        },
        {
          'command': '',
          'title': 'Bad',
          'description': 'Ignored',
          'icon': 'x',
          'lifecycle': 'unknown_lifecycle',
        },
      ],
    });

    expect(commands, hasLength(2));
    expect(commands.first.command, '/stop');
    expect(commands.first.lifecycle, 'stop_active_turn');
    expect(commands.first.acceptsArgs, isFalse);
    expect(commands.last.command, '/help');
    expect(commands.last.lifecycle, 'side_channel');
  });

  test('file preview dto preserves truncation metadata', () {
    final dto = NanobotFilePreviewDto.fromJson({
      'path': 'lib/main.dart',
      'display_path': 'lib/main.dart',
      'project_path': '/tmp/app',
      'language': 'dart',
      'content': 'void main() {}',
      'size': 1024,
      'truncated': true,
    });

    expect(dto.path, 'lib/main.dart');
    expect(dto.language, 'dart');
    expect(dto.size, 1024);
    expect(dto.truncated, isTrue);
  });

  test('settings dto preserves broad webui settings surface', () {
    final dto = NanobotSettingsDto.fromJson({
      'surface': 'native',
      'apply_state': {
        'status': 'requires_app_restart',
        'sections': ['runtime'],
      },
      'agent': {
        'model': 'minimax',
        'provider': 'openai',
        'context_window_tokens': 262144,
        'bot_name': 'nanobot',
      },
      'model_presets': [
        {'name': 'default', 'label': 'Default', 'active': true},
      ],
      'providers': [
        {'name': 'openai', 'label': 'OpenAI', 'configured': true},
      ],
      'web_search': {'provider': 'searxng', 'max_results': 5},
      'image_generation': {
        'enabled': true,
        'provider': 'openrouter',
        'model': 'image-model',
      },
      'transcription': {
        'enabled': true,
        'provider': 'openai',
        'model': 'whisper',
      },
      'runtime': {'config_path': '/tmp/config.toml', 'gateway_port': 8765},
      'advanced': {
        'webui_allow_local_service_access': false,
        'webui_default_access_mode': 'default',
      },
      'usage': {
        'days': [
          {'date': '2026-07-08', 'total_tokens': 100, 'requests': 2},
        ],
        'total_tokens': 100,
        'requests_30d': 2,
      },
      'requires_restart': true,
      'version': {'current': '1.2.3'},
    });

    expect(dto.surface, 'native');
    expect(dto.applyState?['status'], 'requires_app_restart');
    expect(dto.agent['model'], 'minimax');
    expect(dto.modelPresets.single['name'], 'default');
    expect(dto.providers.single['configured'], isTrue);
    expect(dto.webSearch?['provider'], 'searxng');
    expect(dto.imageGeneration?['enabled'], isTrue);
    expect(dto.transcription?['model'], 'whisper');
    expect(dto.runtime?['gateway_port'], 8765);
    expect(dto.advanced?['webui_default_access_mode'], 'default');
    expect(dto.usage?.totalTokens, 100);
    expect(dto.usage?.days.single['date'], '2026-07-08');
    expect(dto.requiresRestart, isTrue);
    expect(dto.version?['current'], '1.2.3');
  });

  test(
    'catalog dtos preserve skills apps features mcp and provider models',
    () {
      final skills = NanobotSkillsDto.fromJson({
        'skills': [
          {
            'name': 'browser',
            'description': 'Browse',
            'source': 'builtin',
            'available': true,
          },
        ],
      });
      final skill = NanobotSkillDetailDto.fromJson({
        'name': 'browser',
        'description': 'Browse',
        'source': 'builtin',
        'available': true,
        'requirements': {
          'bins': ['node'],
          'missing_bins': [],
        },
        'raw_markdown': '# Browser',
      });
      final apps = NanobotCliAppsDto.fromJson({
        'apps': [
          {
            'name': 'gimp',
            'display_name': 'GIMP',
            'installed': true,
            'status': 'installed',
            'manifest': {'id': 'gimp'},
          },
        ],
        'installed_count': 1,
        'last_action': {'ok': true, 'message': 'installed'},
      });
      final features = NanobotFeaturesDto.fromJson({
        'features': [
          {'name': 'matrix', 'enabled': false, 'ready': true},
        ],
        'enabled_count': 0,
        'requires_restart': true,
      });
      final mcp = NanobotMcpPresetsDto.fromJson({
        'presets': [
          {
            'name': 'github',
            'display_name': 'GitHub',
            'configured': true,
            'required_fields': [
              {'name': 'GITHUB_TOKEN', 'secret': true},
            ],
          },
        ],
        'installed_count': 1,
        'hot_reload': {'ok': true},
      });
      final models = NanobotProviderModelsDto.fromJson({
        'provider': 'openai',
        'label': 'OpenAI',
        'status': 'available',
        'catalog_kind': 'official',
        'models': [
          {'id': 'gpt-test', 'context_window': 128000},
        ],
        'model_count': 1,
      });

      expect(skills.skills.single['name'], 'browser');
      expect(skill.rawMarkdown, '# Browser');
      expect(skill.requirements?['bins'], ['node']);
      expect(apps.apps.single['manifest'], {'id': 'gimp'});
      expect(apps.lastAction?['message'], 'installed');
      expect(features.requiresRestart, isTrue);
      expect(features.features.single['ready'], isTrue);
      expect(mcp.presets.single['required_fields'], hasLength(1));
      expect(mcp.hotReload?['ok'], isTrue);
      expect(models.provider, 'openai');
      expect(models.models.single['id'], 'gpt-test');
    },
  );

  test('automation and version dtos preserve action metadata', () {
    final automations = NanobotAutomationsDto.fromJson({
      'jobs': [
        {
          'id': 'job-1',
          'name': 'Daily',
          'enabled': true,
          'schedule': {'kind': 'cron', 'expr': '* * * * *'},
          'payload': {'message': 'ping'},
          'state': {'pending': false},
        },
      ],
    });
    final deleteResult = NanobotSessionDeleteResultDto.fromJson({
      'deleted': false,
      'blocked_by_automations': true,
      'automations': [
        {'id': 'job-1', 'name': 'Daily'},
      ],
    });
    final version = NanobotVersionCheckDto.fromJson({
      'updateAvailable': {
        'currentVersion': '1.0.0',
        'latestVersion': '1.1.0',
        'pypiUrl': 'https://pypi.org/project/nanobot',
      },
    });

    expect(automations.jobs.single['id'], 'job-1');
    expect(deleteResult.deleted, isFalse);
    expect(deleteResult.blockedByAutomations, isTrue);
    expect(deleteResult.automations.single['id'], 'job-1');
    expect(version.updateAvailable?['latestVersion'], '1.1.0');
  });
}
