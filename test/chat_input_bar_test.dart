import 'package:agent_client/app/theme/app_theme.dart';
import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:agent_client/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('send button has explicit readable enabled colors', (
    tester,
  ) async {
    await _pumpInputBar(tester, canSend: true);

    final button = tester.widget<IconButton>(
      find.byKey(const Key('chat-send-button')),
    );

    expect(button.onPressed, isNotNull);
    expect(button.style?.backgroundColor?.resolve({}), AppThemeTokens.brand);
    expect(button.style?.foregroundColor?.resolve({}), Colors.white);
    expect(button.style?.side?.resolve({})?.color, AppThemeTokens.brandPressed);
  });

  testWidgets('send button disabled state stays visible but muted', (
    tester,
  ) async {
    await _pumpInputBar(tester);

    final button = tester.widget<IconButton>(
      find.byKey(const Key('chat-send-button')),
    );
    final disabled = {WidgetState.disabled};

    expect(button.onPressed, isNull);
    expect(
      button.style?.backgroundColor?.resolve(disabled),
      AppThemeTokens.workspace,
    );
    expect(
      button.style?.foregroundColor?.resolve(disabled),
      AppThemeTokens.subtleText,
    );
    expect(
      button.style?.side?.resolve(disabled)?.color,
      AppThemeTokens.strongBorder,
    );
  });

  testWidgets('send button streaming state uses stop affordance colors', (
    tester,
  ) async {
    await _pumpInputBar(tester, isStreaming: true);

    final button = tester.widget<IconButton>(
      find.byKey(const Key('chat-send-button')),
    );

    expect(button.onPressed, isNotNull);
    expect(
      button.style?.backgroundColor?.resolve({}),
      AppThemeTokens.dangerSoft,
    );
    expect(
      button.style?.foregroundColor?.resolve({}),
      AppThemeTokens.dangerText,
    );
    expect(button.style?.side?.resolve({})?.color, AppThemeTokens.dangerBorder);
  });
}

Future<void> _pumpInputBar(
  WidgetTester tester, {
  bool canSend = false,
  bool isStreaming = false,
  bool isStopping = false,
}) async {
  final controller = TextEditingController(text: canSend ? 'hello' : '');
  final focusNode = FocusNode();
  addTearDown(controller.dispose);
  addTearDown(focusNode.dispose);

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: ChatInputBar(
          controller: controller,
          focusNode: focusNode,
          canSend: canSend,
          isStreaming: isStreaming,
          isStopping: isStopping,
          onSend: () {},
          onStop: () {},
          onSwitchSession: () {},
        ),
      ),
    ),
  );
}
