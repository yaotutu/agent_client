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
      'view': {'density': 'compact', 'sort': 'title_asc'},
    });

    expect(dto.pinnedKeys, ['websocket:chat-1']);
    expect(dto.archivedKeys, isEmpty);
    expect(dto.titleOverrides['websocket:chat-1'], 'Pinned');
    expect(dto.projectNameOverrides, isEmpty);
    expect(dto.view.density, 'compact');
    expect(dto.view.sort, 'title_asc');
    expect(dto.view.showArchived, isFalse);
    expect(dto.toJson()['pinned_keys'], ['websocket:chat-1']);
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
          'command': '/bad',
          'title': 'Bad',
          'description': 'Ignored',
          'icon': 'x',
          'lifecycle': 'unknown_lifecycle',
        },
      ],
    });

    expect(commands, hasLength(1));
    expect(commands.single.command, '/stop');
    expect(commands.single.lifecycle, 'stop_active_turn');
    expect(commands.single.acceptsArgs, isFalse);
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
}
