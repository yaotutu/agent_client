import 'package:agent_client/features/chat/domain/chat_message.dart';

class ChatState {
  const ChatState({
    required this.agentId,
    required this.conversationId,
    this.messages = const [],
    this.isStreaming = false,
    this.errorMessage,
  });

  factory ChatState.initial(String agentId) {
    return ChatState(agentId: agentId, conversationId: 'conversation-$agentId');
  }

  final String agentId;
  final String conversationId;
  final List<ChatMessage> messages;
  final bool isStreaming;
  final String? errorMessage;

  ChatState copyWith({
    String? agentId,
    String? conversationId,
    List<ChatMessage>? messages,
    bool? isStreaming,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      agentId: agentId ?? this.agentId,
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
