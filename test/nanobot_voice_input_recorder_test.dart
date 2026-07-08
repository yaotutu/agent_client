import 'package:agent_client/features/nanobot/application/nanobot_voice_input_recorder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('default voice input recorder provider creates a record backed recorder', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final recorder = container.read(nanobotVoiceInputRecorderProvider);

    expect(recorder, isA<NanobotRecordVoiceInputRecorder>());
  });
}
