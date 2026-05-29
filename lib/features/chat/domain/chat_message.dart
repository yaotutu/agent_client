import 'package:agent_client/features/chat/domain/chat_attachment.dart';

enum ChatRole { system, user, assistant, tool }

enum ChatMessageStatus { sending, streaming, completed, failed, stopped }

class ChatMessage {
  const ChatMessage({
    required String id,
    required String agentId,
    required String conversationId,
    required ChatRole role,
    required String content,
    required ChatMessageStatus status,
    required DateTime createdAt,
    List<ChatAttachment>? attachments,
  }) : this._(
         id: id,
         agentId: agentId,
         conversationId: conversationId,
         role: role,
         content: content,
         status: status,
         createdAt: createdAt,
         attachments: attachments,
       );

  const ChatMessage._({
    required this.id,
    required this.agentId,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.status,
    required this.createdAt,
    this._attachments,
  });

  final String id;
  final String agentId;
  final String conversationId;
  final ChatRole role;
  final String content;
  final ChatMessageStatus status;
  final DateTime createdAt;
  final List<ChatAttachment>? _attachments;

  List<ChatAttachment> get attachments => _attachments ?? const [];

  ChatMessage copyWith({
    String? id,
    String? agentId,
    String? conversationId,
    ChatRole? role,
    String? content,
    ChatMessageStatus? status,
    DateTime? createdAt,
    List<ChatAttachment>? attachments,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      attachments: attachments ?? this.attachments,
    );
  }
}
