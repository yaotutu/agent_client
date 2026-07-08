class NanobotMediaAttachment {
  const NanobotMediaAttachment({required this.kind, this.url, this.name});

  final String kind;
  final String? url;
  final String? name;

  factory NanobotMediaAttachment.fromJson(Map<String, Object?> json) {
    final url = json['url'] as String?;
    final name = json['name'] as String?;
    return NanobotMediaAttachment(
      kind: json['kind'] as String? ?? _inferKind(url: url, name: name),
      url: url,
      name: name,
    );
  }

  factory NanobotMediaAttachment.fromUrl(String url) {
    return NanobotMediaAttachment(
      kind: _inferKind(url: url),
      url: url,
      name: _nameFromUrl(url),
    );
  }

  static String _inferKind({String? url, String? name}) {
    final value = '${url ?? ''} ${name ?? ''}'.toLowerCase();
    if (value.contains('video') ||
        value.endsWith('.mp4') ||
        value.endsWith('.webm') ||
        value.endsWith('.mov')) {
      return 'video';
    }
    if (value.contains('image') ||
        value.endsWith('.png') ||
        value.endsWith('.jpg') ||
        value.endsWith('.jpeg') ||
        value.endsWith('.gif') ||
        value.endsWith('.webp') ||
        value.endsWith('.svg')) {
      return 'image';
    }
    return 'file';
  }

  static String? _nameFromUrl(String url) {
    final clean = url.split('?').first.split('#').first;
    final parts = clean.split('/').where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.last;
  }
}
