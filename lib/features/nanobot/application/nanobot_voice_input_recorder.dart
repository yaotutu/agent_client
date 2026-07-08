import 'package:hooks_riverpod/hooks_riverpod.dart';

final nanobotVoiceInputRecorderProvider = Provider<NanobotVoiceInputRecorder?>(
  (ref) => null,
);

abstract class NanobotVoiceInputRecorder {
  Future<NanobotRecordedAudio?> record();
}

class NanobotRecordedAudio {
  const NanobotRecordedAudio({required this.dataUrl, this.durationMs});

  final String dataUrl;
  final int? durationMs;
}
