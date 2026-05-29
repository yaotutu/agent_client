import 'dart:convert';

import 'package:agent_client/core/config/app_config.dart';
import 'package:agent_client/features/chat/data/agent_chat_repository.dart';
import 'package:agent_client/features/chat/data/openai_chat_completions_sse_parser.dart';
import 'package:agent_client/features/chat/domain/chat_event.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:dio/dio.dart';

class OpenAiChatCompletionsAgentChatRepository implements AgentChatRepository {
  OpenAiChatCompletionsAgentChatRepository({
    required this.dio,
    required this.config,
    OpenAiChatCompletionsSseParser? parser,
  }) : _parser = parser ?? OpenAiChatCompletionsSseParser();

  final Dio dio;
  final AppConfig config;
  final OpenAiChatCompletionsSseParser _parser;
  final Map<String, CancelToken> _cancelTokens = {};

  static Map<String, Object?> buildRequestBody({
    required SendMessageRequest request,
    required String model,
  }) {
    final messages = <Map<String, String>>[
      for (final message in request.history)
        if (_canSendToChatCompletions(message))
          {'role': _roleName(message.role), 'content': message.content},
    ];

    final latestUserAlreadyIncluded =
        messages.isNotEmpty &&
        messages.last['role'] == 'user' &&
        messages.last['content'] == request.input;

    if (!latestUserAlreadyIncluded) {
      messages.add({'role': 'user', 'content': request.input});
    }

    return {
      'model': model,
      'messages': messages,
      'stream': true,
      'metadata': {
        'agent_id': request.agentId,
        'conversation_id': request.conversationId,
      },
    };
  }

  static bool _canSendToChatCompletions(ChatMessage message) {
    return message.content.trim().isNotEmpty &&
        switch (message.role) {
          ChatRole.user || ChatRole.assistant || ChatRole.system => true,
          ChatRole.tool => false,
        };
  }

  static String _roleName(ChatRole role) {
    return switch (role) {
      ChatRole.system => 'system',
      ChatRole.user => 'user',
      ChatRole.assistant => 'assistant',
      ChatRole.tool => 'tool',
    };
  }

  @override
  Future<void> cancelActiveResponse(String conversationId) async {
    _cancelTokens.remove(conversationId)?.cancel('stopped by user');
  }

  @override
  Future<List<ChatMessage>> loadRecentMessages(String agentId) async =>
      const [];

  @override
  Stream<ChatEvent> sendMessage(SendMessageRequest request) async* {
    final cancelToken = CancelToken();
    _cancelTokens[request.conversationId] = cancelToken;

    try {
      final response = await dio.post<ResponseBody>(
        '/v1/chat/completions',
        data: buildRequestBody(request: request, model: config.defaultModel),
        cancelToken: cancelToken,
        options: Options(responseType: ResponseType.stream),
      );

      final body = response.data;
      if (body == null) {
        yield const ChatEvent.error(
          messageId: 'assistant',
          errorMessage: 'Empty response stream',
        );
        return;
      }

      await for (final chunk in body.stream.cast<List<int>>().transform(
        utf8.decoder,
      )) {
        for (final event in _parser.parseChunk(chunk)) {
          yield event;
        }
      }
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        yield const ChatEvent.messageCompleted(messageId: 'assistant');
      } else {
        yield ChatEvent.error(
          messageId: 'assistant',
          errorMessage: error.message ?? 'Network request failed',
        );
      }
    } finally {
      _cancelTokens.remove(request.conversationId);
    }
  }
}
