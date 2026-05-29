import 'dart:convert';

import 'package:agent_client/features/chat/domain/chat_event.dart';

class OpenAiChatCompletionsSseParser {
  String _buffer = '';

  List<ChatEvent> parseChunk(String chunk) {
    _buffer += chunk;
    final blocks = _buffer.split(RegExp(r'\r?\n\r?\n'));
    _buffer = blocks.removeLast();

    return blocks.map(_parseBlock).whereType<ChatEvent>().toList();
  }

  ChatEvent? _parseBlock(String block) {
    final data = block
        .split(RegExp(r'\r?\n'))
        .where((line) => line.startsWith('data:'))
        .map((line) => line.substring(5).trimLeft())
        .join('\n')
        .trim();

    if (data.isEmpty || data == '[DONE]') {
      return null;
    }

    final decoded = jsonDecode(data);
    if (decoded is! Map<String, Object?>) {
      return null;
    }

    if (decoded['error'] case final error?) {
      return ChatEvent.error(
        messageId: _messageId(decoded),
        errorMessage: error.toString(),
      );
    }

    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      return null;
    }

    final choice = choices.first;
    if (choice is! Map<String, Object?>) {
      return null;
    }

    final messageId = _messageId(decoded);
    final delta = choice['delta'];
    final finishReason = choice['finish_reason'];

    if (finishReason != null) {
      return ChatEvent.messageCompleted(messageId: messageId);
    }

    if (delta is! Map<String, Object?>) {
      return null;
    }

    if (delta['content'] case final content?) {
      return ChatEvent.textDelta(
        messageId: messageId,
        delta: content.toString(),
      );
    }

    if (delta['tool_calls'] case final toolCalls?) {
      return ChatEvent.toolEvent(
        messageId: messageId,
        payload: {'tool_calls': toolCalls},
      );
    }

    if (delta['function_call'] case final functionCall?) {
      return ChatEvent.toolEvent(
        messageId: messageId,
        payload: {'function_call': functionCall},
      );
    }

    if (delta['role'] == 'assistant') {
      return ChatEvent.messageStarted(messageId: messageId);
    }

    return null;
  }

  String _messageId(Map<String, Object?> decoded) {
    return decoded['id']?.toString() ?? 'assistant';
  }
}
