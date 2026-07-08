import 'package:agent_client/features/nanobot/domain/nanobot_message.dart';

class NanobotThreadPage {
  const NanobotThreadPage({
    this.messages = const [],
    this.userMessageOffset = 0,
    this.forkBoundaryMessageCount,
  });

  final List<NanobotMessage> messages;
  final int userMessageOffset;
  final int? forkBoundaryMessageCount;
}
