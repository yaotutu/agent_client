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
  });

  final String key;
  final String channel;
  final String chatId;
  final String? title;
  final String preview;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? runStartedAt;

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
}
