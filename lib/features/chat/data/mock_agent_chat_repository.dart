import 'package:agent_client/features/chat/data/agent_chat_repository.dart';
import 'package:agent_client/features/chat/domain/chat_attachment.dart';
import 'package:agent_client/features/chat/domain/chat_event.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';

class MockAgentChatRepository implements AgentChatRepository {
  const MockAgentChatRepository();

  @override
  Future<void> cancelActiveResponse(String conversationId) async {}

  @override
  Future<List<ChatMessage>> loadRecentMessages(String agentId) async {
    return switch (agentId) {
      'agent-research' => _researchMessages,
      'agent-ops' => _opsMessages,
      _ => _generalMessages,
    };
  }

  @override
  Stream<ChatEvent> sendMessage(SendMessageRequest request) async* {
    const messageId = 'mock-assistant-reply';
    yield const ChatEvent.messageStarted(messageId: messageId);
    yield const ChatEvent.textDelta(
      messageId: messageId,
      delta: 'I will keep this as a static UI response for now. ',
    );
    yield const ChatEvent.textDelta(
      messageId: messageId,
      delta:
          'Once the screens are settled, we can switch the provider to the real Chat Completions adapter.',
    );
    yield const ChatEvent.messageCompleted(messageId: messageId);
  }
}

final _generalMessages = [
  ChatMessage(
    id: 'mock-user-1',
    agentId: 'agent-general',
    conversationId: 'conversation-agent-general',
    role: ChatRole.user,
    content: 'Review the mobile chat layout',
    status: ChatMessageStatus.completed,
    createdAt: DateTime(2026, 5, 29, 9, 20),
  ),
  ChatMessage(
    id: 'mock-assistant-1',
    agentId: 'agent-general',
    conversationId: 'conversation-agent-general',
    role: ChatRole.assistant,
    content:
        'I found three UI priorities: keep the composer fixed at the bottom, keep Agent switching away from the bottom edge, and make Files and Tasks feel like peer tabs instead of separate pages.',
    status: ChatMessageStatus.completed,
    createdAt: DateTime(2026, 5, 29, 9, 21),
  ),
  ChatMessage(
    id: 'mock-assistant-rich-content',
    agentId: 'agent-general',
    conversationId: 'conversation-agent-general',
    role: ChatRole.assistant,
    content:
        '### Implementation checklist\n\n- Render **Markdown** directly inside the chat bubble.\n- Keep attached files scannable without leaving the chat.\n- Show image previews with a stable aspect ratio before download.',
    status: ChatMessageStatus.completed,
    createdAt: DateTime(2026, 5, 29, 9, 22),
    attachments: const [
      ChatAttachment(
        id: 'ui-spec-file',
        kind: ChatAttachmentKind.file,
        name: 'UI-specification.md',
        mimeType: 'text/markdown',
        sizeLabel: '18 KB',
        typeLabel: 'Markdown',
      ),
      ChatAttachment(
        id: 'tablet-layout-preview',
        kind: ChatAttachmentKind.image,
        name: 'Tablet layout preview',
        url: 'https://picsum.photos/seed/agent-tablet-layout/960/540',
        mimeType: 'image/jpeg',
        sizeLabel: '240 KB',
        typeLabel: 'Image',
        description: 'Static preview placeholder for rich chat rendering.',
      ),
    ],
  ),
  ChatMessage(
    id: 'mock-user-2',
    agentId: 'agent-general',
    conversationId: 'conversation-agent-general',
    role: ChatRole.user,
    content: 'Prepare a static version before wiring the server',
    status: ChatMessageStatus.completed,
    createdAt: DateTime(2026, 5, 29, 9, 24),
  ),
  ChatMessage(
    id: 'mock-assistant-2',
    agentId: 'agent-general',
    conversationId: 'conversation-agent-general',
    role: ChatRole.assistant,
    content:
        'Static mode is active. I will use local sample conversations, files, and tasks so the interaction model can be reviewed without backend noise.',
    status: ChatMessageStatus.completed,
    createdAt: DateTime(2026, 5, 29, 9, 25),
  ),
];

final _researchMessages = [
  ChatMessage(
    id: 'mock-research-user-1',
    agentId: 'agent-research',
    conversationId: 'conversation-agent-research',
    role: ChatRole.user,
    content: 'Summarize the latest notes',
    status: ChatMessageStatus.completed,
    createdAt: DateTime(2026, 5, 29, 10, 2),
  ),
  ChatMessage(
    id: 'mock-research-assistant-1',
    agentId: 'agent-research',
    conversationId: 'conversation-agent-research',
    role: ChatRole.assistant,
    content:
        'The research thread is organized around product scope, adaptive layout, and service integration. The next decision is which parts of the task model need approval states.',
    status: ChatMessageStatus.completed,
    createdAt: DateTime(2026, 5, 29, 10, 3),
  ),
];

final _opsMessages = [
  ChatMessage(
    id: 'mock-ops-assistant-1',
    agentId: 'agent-ops',
    conversationId: 'conversation-agent-ops',
    role: ChatRole.assistant,
    content:
        'Ops Agent is watching release checklist items. No production endpoint is connected in static mode.',
    status: ChatMessageStatus.completed,
    createdAt: DateTime(2026, 5, 29, 10, 12),
  ),
];
