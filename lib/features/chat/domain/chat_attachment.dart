enum ChatAttachmentKind { file, image }

class ChatAttachment {
  const ChatAttachment({
    required this.id,
    required this.kind,
    required this.name,
    this.url,
    this.thumbnailUrl,
    this.mimeType,
    this.sizeLabel,
    this.typeLabel,
    this.description,
  });

  final String id;
  final ChatAttachmentKind kind;
  final String name;
  final String? url;
  final String? thumbnailUrl;
  final String? mimeType;
  final String? sizeLabel;
  final String? typeLabel;
  final String? description;

  String get metadataLabel {
    final parts = [
      if (sizeLabel != null && sizeLabel!.isNotEmpty) sizeLabel!,
      if (typeLabel != null && typeLabel!.isNotEmpty) typeLabel!,
    ];
    return parts.join(' · ');
  }
}
