import 'package:agent_client/features/nanobot/domain/nanobot_shell_models.dart';

class NanobotSessionSummary {
  const NanobotSessionSummary({
    required this.key,
    required this.channel,
    required this.chatId,
    required this.preview,
    this.title,
    this.createdAt,
    this.updatedAt,
    this.runStartedAt,
    this.workspaceScope,
  });

  final String key;
  final String channel;
  final String chatId;
  final String? title;
  final String preview;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? runStartedAt;
  final NanobotWorkspaceScope? workspaceScope;

  String get displayTitle {
    final trimmedTitle = title?.trim();
    if (trimmedTitle != null && trimmedTitle.isNotEmpty) {
      return trimmedTitle;
    }
    final trimmedPreview = preview.trim();
    if (trimmedPreview.isNotEmpty) {
      return trimmedPreview;
    }
    return 'Chat ${chatId.length > 8 ? chatId.substring(0, 8) : chatId}';
  }

  factory NanobotSessionSummary.fromJson(Map<String, Object?> json) {
    final key = (json['key'] as String?)?.trim() ?? '';
    final parts = _splitKey(key);
    return NanobotSessionSummary(
      key: key,
      channel: parts.$1,
      chatId: parts.$2,
      title: json['title'] as String?,
      preview: json['preview'] as String? ?? '',
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      runStartedAt: json['run_started_at'] is num
          ? (json['run_started_at'] as num).toInt()
          : null,
      workspaceScope: _parseWorkspaceScope(json['workspace_scope']),
    );
  }

  NanobotSessionSummary copyWith({NanobotWorkspaceScope? workspaceScope}) {
    return NanobotSessionSummary(
      key: key,
      channel: channel,
      chatId: chatId,
      title: title,
      preview: preview,
      createdAt: createdAt,
      updatedAt: updatedAt,
      runStartedAt: runStartedAt,
      workspaceScope: workspaceScope ?? this.workspaceScope,
    );
  }

  static (String, String) _splitKey(String key) {
    final index = key.indexOf(':');
    if (index < 0) {
      return ('', key);
    }
    return (key.substring(0, index), key.substring(index + 1));
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  static NanobotWorkspaceScope? _parseWorkspaceScope(Object? value) {
    if (value is! Map) {
      return null;
    }
    final json = Map<String, Object?>.from(value);
    final projectPath = json['project_path'] as String?;
    if (projectPath == null || projectPath.trim().isEmpty) {
      return null;
    }
    return NanobotWorkspaceScope(
      projectPath: projectPath,
      projectName: json['project_name'] as String?,
      accessMode: json['access_mode'] as String? ?? 'restricted',
      restrictToWorkspace: json['restrict_to_workspace'] as bool?,
      sandboxStatus: json['sandbox_status'] is Map
          ? Map<String, Object?>.from(json['sandbox_status'] as Map)
          : null,
    );
  }
}
