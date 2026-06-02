import 'package:agent_client/features/chat/domain/chat_session.dart';
import 'package:agent_client/features/chat/presentation/widgets/chat_session_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders running session elapsed time when runStartedAt is set', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatSessionTile(
            session: ChatSessionSummary(
              id: 'session-1',
              title: 'Active chat',
              preview: 'Working',
              messageCount: 4,
              status: ChatSessionStatus.running,
              runStartedAt: DateTime.now().subtract(const Duration(minutes: 2)),
            ),
            selected: false,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('Running '), findsOneWidget);
  });
}
