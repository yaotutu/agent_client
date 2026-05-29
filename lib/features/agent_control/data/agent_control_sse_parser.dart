import 'dart:convert';

import 'package:agent_client/features/agent_control/domain/agent_control_models.dart';

class AgentControlSseParser {
  String _buffer = '';

  List<AgentControlStreamEvent> parseChunk(String chunk) {
    _buffer += chunk;
    final blocks = _buffer.split(RegExp(r'\r?\n\r?\n'));
    _buffer = blocks.removeLast();

    return blocks
        .map(_parseBlock)
        .whereType<AgentControlStreamEvent>()
        .toList();
  }

  AgentControlStreamEvent? _parseBlock(String block) {
    final data = block
        .split(RegExp(r'\r?\n'))
        .where((line) => line.startsWith('data:'))
        .map((line) => line.substring(5).trimLeft())
        .join('\n')
        .trim();

    if (data.isEmpty) {
      return null;
    }
    if (data == '[DONE]') {
      return AgentControlStreamEvent.doneMarker();
    }

    final decoded = jsonDecode(data);
    if (decoded is! Map<String, Object?>) {
      return null;
    }
    return AgentControlStreamEvent.fromJson(decoded);
  }
}
