import 'dart:convert';

import 'package:agent_client/features/nanobot/domain/nanobot_media_attachment.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final nanobotImageAttachmentPickerProvider =
    Provider<NanobotImageAttachmentPicker>(
      (ref) => NanobotImagePickerAttachmentPicker(),
    );

abstract class NanobotImageAttachmentPicker {
  Future<List<NanobotSendMedia>> pickImages();
}

class NanobotImagePickerAttachmentPicker
    implements NanobotImageAttachmentPicker {
  NanobotImagePickerAttachmentPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<NanobotSendMedia>> pickImages() async {
    final images = await _picker.pickMultiImage();
    return [
      for (final image in images)
        NanobotSendMedia(
          dataUrl: _dataUrl(
            mimeType: image.mimeType ?? _mimeTypeFromName(image.name),
            bytes: await image.readAsBytes(),
          ),
          name: image.name,
        ),
    ];
  }

  String _dataUrl({required String mimeType, required List<int> bytes}) {
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  String _mimeTypeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/png';
  }
}
