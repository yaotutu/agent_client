import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

final nanobotVoiceInputRecorderProvider = Provider<NanobotVoiceInputRecorder?>(
  (ref) {
    final recorder = NanobotRecordVoiceInputRecorder();
    ref.onDispose(recorder.dispose);
    return recorder;
  },
);

abstract class NanobotVoiceInputRecorder {
  Future<NanobotRecordedAudio?> record(BuildContext context);
}

class NanobotRecordedAudio {
  const NanobotRecordedAudio({required this.dataUrl, this.durationMs});

  final String dataUrl;
  final int? durationMs;
}

class NanobotRecordVoiceInputRecorder implements NanobotVoiceInputRecorder {
  NanobotRecordVoiceInputRecorder({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  @override
  Future<NanobotRecordedAudio?> record(BuildContext context) async {
    if (!await _recorder.hasPermission()) {
      throw StateError('microphone_permission_denied');
    }
    final directory = await getTemporaryDirectory();
    final startedAt = DateTime.now();
    final path =
        '${directory.path}/nanobot-voice-${startedAt.microsecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav, numChannels: 1),
      path: path,
    );
    if (!context.mounted) {
      await _recorder.cancel();
      return null;
    }
    try {
      final shouldStop = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _VoiceRecordingDialog(),
      );
      if (shouldStop != true) {
        await _recorder.cancel();
        return null;
      }
      final stoppedPath = await _recorder.stop();
      if (stoppedPath == null) {
        return null;
      }
      final file = File(stoppedPath);
      final bytes = await file.readAsBytes();
      unawaited(file.delete().catchError((_) => file));
      return NanobotRecordedAudio(
        dataUrl: 'data:audio/wav;base64,${base64Encode(bytes)}',
        durationMs: DateTime.now().difference(startedAt).inMilliseconds,
      );
    } catch (_) {
      await _recorder.cancel();
      rethrow;
    }
  }

  Future<void> dispose() => _recorder.dispose();
}

class _VoiceRecordingDialog extends StatefulWidget {
  const _VoiceRecordingDialog();

  @override
  State<_VoiceRecordingDialog> createState() => _VoiceRecordingDialogState();
}

class _VoiceRecordingDialogState extends State<_VoiceRecordingDialog> {
  late final DateTime _startedAt;
  Timer? _timer;
  var _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      setState(() => _elapsed = DateTime.now().difference(_startedAt));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Voice input'),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic, color: Colors.redAccent),
          const SizedBox(width: 12),
          Text('Recording ${_formatElapsed(_elapsed)}'),
        ],
      ),
      actions: [
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.stop),
          label: const Text('Stop'),
        ),
      ],
    );
  }

  String _formatElapsed(Duration elapsed) {
    final seconds = elapsed.inSeconds;
    final minutes = seconds ~/ 60;
    return '$minutes:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}
