import 'package:agent_client/app/agent_client_app.dart';
import 'package:agent_client/core/config/app_config.dart';
import 'package:agent_client/features/agent_control/data/agent_control_api_client.dart';
import 'package:agent_client/features/agent_control/domain/agent_control_models.dart';
import 'package:agent_client/features/agents/application/agent_controller.dart';
import 'package:agent_client/features/agents/data/agent_avatar_store.dart';
import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:agent_client/features/agents/domain/agent_avatar.dart';
import 'package:agent_client/features/chat/data/agent_chat_repository.dart';
import 'package:agent_client/features/chat/data/agent_chat_repository_provider.dart';
import 'package:agent_client/features/chat/data/chat_cache_provider.dart';
import 'package:agent_client/features/chat/data/chat_cache_store.dart';
import 'package:agent_client/features/chat/domain/chat_attachment.dart';
import 'package:agent_client/features/chat/domain/chat_event.dart';
import 'package:agent_client/features/chat/domain/chat_message.dart';
import 'package:agent_client/features/chat/domain/chat_session.dart';
import 'package:agent_client/features/files/application/agent_files_provider.dart';
import 'package:agent_client/features/files/data/agent_resources_repository.dart';
import 'package:agent_client/features/files/domain/agent_file_content.dart';
import 'package:agent_client/features/files/domain/agent_file_item.dart';
import 'package:agent_client/features/files/domain/agent_resources_repository.dart';
import 'package:agent_client/features/files/presentation/files_panel.dart';
import 'package:agent_client/features/settings/data/agent_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  Future<void> pumpAppAtSize(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigStoreProvider.overrideWithValue(_MemoryAppConfigStore()),
          agentsProvider.overrideWith((ref) async => _agents),
          agentChatRepositoryProvider.overrideWithValue(
            _FakeAgentChatRepository(),
          ),
          chatCacheStoreProvider.overrideWithValue(InMemoryChatCacheStore()),
          agentFilesProvider.overrideWith((ref, query) async => _files),
          agentCommandsProvider.overrideWith((ref, agentId) async => const []),
        ],
        child: const AgentClientApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpAppWithAgentApi(
    WidgetTester tester,
    Size size,
    _FakeAgentControlApi api, {
    _FakeAgentAvatarStore? avatarStore,
  }) async {
    final effectiveAvatarStore = avatarStore ?? _FakeAgentAvatarStore();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentControlApiClientProvider.overrideWithValue(api),
          agentAvatarStoreProvider.overrideWithValue(effectiveAvatarStore),
          agentChatRepositoryProvider.overrideWithValue(
            _FakeAgentChatRepository(),
          ),
          chatCacheStoreProvider.overrideWithValue(InMemoryChatCacheStore()),
          agentFilesProvider.overrideWith((ref, query) async => _files),
          agentCommandsProvider.overrideWith((ref, agentId) async => const []),
        ],
        child: const AgentClientApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMobileAgentChat(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('agent-conversation-agent-nanobot')));
    await tester.pumpAndSettle();
  }

  testWidgets('desktop layout uses an IM shell with conversation list', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(1200, 800));

    expect(find.byKey(const Key('agent-im-shell')), findsOneWidget);
    expect(find.byKey(const Key('agent-app-rail')), findsOneWidget);
    expect(find.byKey(const Key('agent-conversation-list')), findsOneWidget);
    expect(
      find.byKey(const Key('agent-conversation-everyone')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('agent-conversation-agent-nanobot')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('agent-chat-detail')), findsOneWidget);
    expect(find.byKey(const Key('agent-tab-bar')), findsNothing);
    expect(find.byKey(const Key('agent-side-rail')), findsNothing);
    expect(find.byKey(const Key('agent-create-button')), findsNothing);
    expect(find.text('Compose'), findsNothing);
    expect(find.byKey(const Key('chat-message-list')), findsOneWidget);
    expect(find.byKey(const Key('agent-detail-files-button')), findsOneWidget);
    expect(find.byKey(const Key('agent-detail-tasks-button')), findsOneWidget);
  });

  testWidgets('phone layout starts at the conversation list and opens chat', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(390, 844));

    expect(
      find.byKey(const Key('agent-mobile-conversation-list')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('agent-conversation-agent-nanobot')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('chat-message-list')), findsNothing);

    await tester.tap(find.byKey(const Key('agent-conversation-agent-nanobot')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agent-chat-detail')), findsOneWidget);
    expect(find.byKey(const Key('agent-chat-back-button')), findsOneWidget);
    expect(find.byKey(const Key('chat-message-list')), findsOneWidget);

    await tester.tap(find.byKey(const Key('agent-chat-back-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('agent-mobile-conversation-list')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('chat-message-list')), findsNothing);
  });

  testWidgets(
    'phone conversation list keeps safe area while styling status bar',
    (tester) async {
      tester.view.padding = const FakeViewPadding(top: 44);
      addTearDown(tester.view.resetPadding);

      await pumpAppAtSize(tester, const Size(390, 844));

      final listRect = tester.getRect(
        find.byKey(const Key('agent-conversation-list')),
      );
      final rootScaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      final overlayStyle = tester
          .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
          )
          .first
          .value;

      expect(listRect.top, moreOrLessEquals(44, epsilon: 1));
      expect(rootScaffold.backgroundColor, const Color(0xFFF8FBFE));
      expect(overlayStyle.statusBarColor, const Color(0xFFF8FBFE));
      expect(overlayStyle.statusBarIconBrightness, Brightness.dark);
    },
  );

  testWidgets('phone layout prioritizes chat and keeps input at the bottom', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(390, 844));
    await openMobileAgentChat(tester);

    expect(find.byKey(const Key('agent-chat-detail')), findsOneWidget);
    expect(find.byKey(const Key('agent-settings-tab')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('current-agent-title')),
        matching: find.text('nanobot'),
      ),
      findsOneWidget,
    );
    final currentAgentTitle = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('current-agent-title')),
        matching: find.text('nanobot'),
      ),
    );
    expect(currentAgentTitle.maxLines, 1);
    expect(currentAgentTitle.overflow, TextOverflow.ellipsis);
    expect(currentAgentTitle.softWrap, isFalse);
    expect(find.byKey(const Key('chat-message-list')), findsOneWidget);
    expect(find.textContaining('MiniMax-M2.7-highspeed'), findsNothing);
    final headerAvatarRect = tester.getRect(
      find.descendant(
        of: find.byKey(const Key('agent-chat-detail')),
        matching: find.byType(CircleAvatar),
      ),
    );
    expect(headerAvatarRect.top, greaterThanOrEqualTo(8));
    expect(headerAvatarRect.bottom, lessThanOrEqualTo(48));
    expect(
      tester.getTopLeft(find.byKey(const Key('chat-message-list'))).dy,
      lessThanOrEqualTo(60),
    );
    expect(find.text('Review the mobile chat layout'), findsOneWidget);
    expect(find.textContaining('I found three UI priorities'), findsOneWidget);
    expect(find.byKey(const Key('chat-input-bar')), findsOneWidget);
    expect(find.byKey(const Key('bottom-navigation')), findsNothing);

    final inputRect = tester.getRect(find.byKey(const Key('chat-input-bar')));
    expect(inputRect.bottom, moreOrLessEquals(844, epsilon: 1));
    expect(inputRect.height, greaterThan(48));

    final detailRect = tester.getRect(
      find.byKey(const Key('agent-chat-detail')),
    );
    expect(detailRect.top, lessThan(inputRect.top));
  });

  testWidgets('phone chat keeps safe area while styling the status bar', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 44);
    addTearDown(tester.view.resetPadding);

    await pumpAppAtSize(tester, const Size(390, 844));
    await openMobileAgentChat(tester);

    final detailRect = tester.getRect(
      find.byKey(const Key('agent-chat-detail')),
    );
    final headerRect = tester.getRect(
      find.byKey(const Key('agent-chat-header')),
    );
    final headerAvatarRect = tester.getRect(
      find.descendant(
        of: find.byKey(const Key('agent-chat-detail')),
        matching: find.byType(CircleAvatar),
      ),
    );
    final mobileScaffold = tester
        .widgetList<Scaffold>(find.byType(Scaffold))
        .last;
    final overlayStyle = tester
        .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        )
        .last
        .value;

    expect(detailRect.top, moreOrLessEquals(44, epsilon: 1));
    expect(headerRect.top, moreOrLessEquals(44, epsilon: 1));
    expect(headerRect.height, moreOrLessEquals(56, epsilon: 1));
    expect(headerAvatarRect.top, greaterThanOrEqualTo(52));
    expect(mobileScaffold.backgroundColor, const Color(0xFFFBFDFF));
    expect(overlayStyle.statusBarColor, const Color(0xFFFBFDFF));
    expect(overlayStyle.statusBarIconBrightness, Brightness.dark);
  });

  testWidgets('phone keyboard inset moves input without resizing chat detail', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(390, 844));
    await openMobileAgentChat(tester);

    final detailBefore = tester.getRect(
      find.byKey(const Key('agent-chat-detail')),
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    final detailAfter = tester.getRect(
      find.byKey(const Key('agent-chat-detail')),
    );
    final inputAfter = tester.getRect(find.byKey(const Key('chat-input-bar')));

    expect(
      detailAfter.height,
      moreOrLessEquals(detailBefore.height, epsilon: 1),
    );
    expect(inputAfter.bottom, lessThan(detailBefore.bottom - 260));
  });

  testWidgets('phone conversation list opens a backend agent chat', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(390, 844));

    expect(
      find.byKey(const Key('agent-mobile-conversation-list')),
      findsOneWidget,
    );
    expect(find.text('nanobot'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const Key('agent-tile-nanobot')),
        matching: find.text('MiniMax-M2.7-highspeed'),
      ),
      findsNothing,
    );
    final agentTileTitle = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('agent-tile-nanobot')),
        matching: find.text('nanobot'),
      ),
    );
    expect(agentTileTitle.maxLines, 1);
    expect(agentTileTitle.overflow, TextOverflow.ellipsis);
    expect(agentTileTitle.softWrap, isFalse);

    await tester.tap(find.byKey(const Key('agent-conversation-agent-nanobot')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('current-agent-title')),
        matching: find.text('nanobot'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('chat-input-bar')), findsOneWidget);
  });

  testWidgets('phone chat switches conversations from a dialog', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(390, 844));
    await openMobileAgentChat(tester);

    expect(find.byKey(const Key('chat-session-rail')), findsNothing);
    expect(find.byKey(const Key('chat-session-picker-button')), findsNothing);
    expect(find.byKey(const Key('chat-session-switch-button')), findsOneWidget);
    expect(find.text('Backend layout review'), findsNothing);

    final inputBarRect = tester.getRect(
      find.byKey(const Key('chat-input-bar')),
    );
    final switchButtonRect = tester.getRect(
      find.byKey(const Key('chat-session-switch-button')),
    );
    final messageFieldRect = tester.getRect(find.byType(TextField).first);
    expect(switchButtonRect.left, lessThan(messageFieldRect.left));
    expect(
      switchButtonRect.bottom,
      lessThanOrEqualTo(inputBarRect.bottom + 0.1),
    );

    await tester.tap(find.byKey(const Key('chat-session-switch-button')));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byKey(const Key('chat-session-dialog')), findsOneWidget);
    expect(find.text('Conversations'), findsWidgets);
    expect(find.text('Backend flaky test'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-session-session-flaky-test')));
    await tester.pumpAndSettle();

    expect(
      find.text('The failing test is tied to session restore.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('chat-session-dialog')), findsNothing);
  });

  testWidgets('phone conversation dialog creates a new session', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(390, 844));
    await openMobileAgentChat(tester);

    await tester.tap(find.byKey(const Key('chat-session-switch-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-session-dialog-new-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-session-dialog')), findsNothing);
    expect(find.text('Start a chat'), findsOneWidget);
  });

  testWidgets('desktop layout keeps chat input bottom in the IM shell', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(1200, 800));

    expect(find.byKey(const Key('agent-app-rail')), findsOneWidget);
    expect(find.byKey(const Key('agent-conversation-list')), findsOneWidget);
    expect(find.byKey(const Key('agent-navigation-button')), findsNothing);
    expect(find.text('Agent Navigator'), findsNothing);
    expect(find.byKey(const Key('chat-input-bar')), findsOneWidget);

    final inputRect = tester.getRect(find.byKey(const Key('chat-input-bar')));
    expect(inputRect.bottom, moreOrLessEquals(800, epsilon: 1));
  });

  testWidgets('wide fullscreen constrains and centers the chat surface', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(1728, 1117));

    final workspaceRect = tester.getRect(
      find.byKey(const Key('agent-chat-detail')),
    );
    final frameRect = tester.getRect(
      find.byKey(const Key('agent-chat-detail-frame')),
    );

    expect(frameRect.width, lessThanOrEqualTo(1120));
    expect(frameRect.left, greaterThan(workspaceRect.left));
    expect(frameRect.right, lessThan(workspaceRect.right));
    expect(
      frameRect.center.dx,
      moreOrLessEquals(workspaceRect.center.dx, epsilon: 1),
    );
  });

  testWidgets('desktop agent navigator deletes the current agent', (
    tester,
  ) async {
    final api = _FakeAgentControlApi([
      _agentSummary('nanobot'),
      _agentSummary('reviewer'),
    ]);
    await pumpAppWithAgentApi(tester, const Size(1200, 800), api);

    await tester.tap(find.byKey(const Key('agent-tile-reviewer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('agent-menu-reviewer')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete agent'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('agent-delete-confirm-button')));
    await tester.pumpAndSettle();

    expect(api.deletedName, 'reviewer');
    expect(find.byKey(const Key('agent-tile-reviewer')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('agent-tile-nanobot')),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
  });

  testWidgets('create agent dialog saves the selected default avatar', (
    tester,
  ) async {
    final api = _FakeAgentControlApi([_agentSummary('nanobot')]);
    final avatarStore = _FakeAgentAvatarStore();
    await pumpAppWithAgentApi(
      tester,
      const Size(1200, 800),
      api,
      avatarStore: avatarStore,
    );

    await tester.tap(find.byKey(const Key('agent-conversation-create-button')));
    await tester.pumpAndSettle();

    final avatar = AgentAvatarOptions.defaults[2];
    await tester.tap(find.byKey(Key('agent-avatar-option-${avatar.id}')));
    await tester.enterText(
      find.byKey(const Key('agent-create-name-field')),
      'researcher',
    );
    await tester.enterText(
      find.byKey(const Key('agent-create-description-field')),
      '调研助手',
    );
    await tester.tap(find.byKey(const Key('agent-create-submit-button')));
    await tester.pumpAndSettle();

    expect(api.createdName, 'researcher');
    expect(api.createdDescription, '调研助手');
    expect(avatarStore.avatarFor('researcher'), avatar.assetPath);
    expect(
      find.byKey(const Key('agent-avatar-image-researcher')),
      findsWidgets,
    );
  });

  testWidgets('agent menu updates the selected avatar for an existing agent', (
    tester,
  ) async {
    final api = _FakeAgentControlApi([_agentSummary('nanobot')]);
    final avatarStore = _FakeAgentAvatarStore();
    await pumpAppWithAgentApi(
      tester,
      const Size(1200, 800),
      api,
      avatarStore: avatarStore,
    );

    await tester.tap(find.byKey(const Key('agent-menu-nanobot')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change avatar'));
    await tester.pumpAndSettle();

    final avatar = AgentAvatarOptions.defaults[4];
    await tester.tap(find.byKey(Key('agent-avatar-option-${avatar.id}')));
    await tester.tap(find.byKey(const Key('agent-avatar-save-button')));
    await tester.pumpAndSettle();

    expect(avatarStore.avatarFor('nanobot'), avatar.assetPath);
    expect(find.byKey(const Key('agent-avatar-image-nanobot')), findsWidgets);
  });

  testWidgets('desktop chat shows mock conversations and switches sessions', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(1200, 800));

    expect(find.byKey(const Key('agent-app-rail')), findsOneWidget);
    expect(find.byKey(const Key('agent-conversation-list')), findsOneWidget);
    expect(find.byKey(const Key('chat-session-rail')), findsNothing);
    expect(find.byKey(const Key('chat-session-picker-button')), findsNothing);
    expect(find.byKey(const Key('chat-session-switch-button')), findsOneWidget);
    expect(find.text('Backend layout review'), findsNothing);

    await tester.tap(find.byKey(const Key('chat-session-switch-button')));
    await tester.pumpAndSettle();
    expect(find.text('Conversations'), findsWidgets);
    expect(find.text('Backend flaky test'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-session-session-flaky-test')));
    await tester.pumpAndSettle();

    expect(
      find.text('The failing test is tied to session restore.'),
      findsOneWidget,
    );
    expect(find.text('Review the mobile chat layout'), findsNothing);
  });

  testWidgets('desktop conversation dialog creates a backend session', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(1200, 800));

    await tester.tap(find.byKey(const Key('chat-session-switch-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-session-dialog-new-button')));
    await tester.pumpAndSettle();

    expect(find.text('Start a chat'), findsOneWidget);
  });

  testWidgets('desktop conversation switch button opens the session dialog', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(1200, 800));

    await tester.tap(find.byKey(const Key('chat-session-switch-button')));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byKey(const Key('chat-session-dialog')), findsOneWidget);
    expect(find.text('Backend layout review'), findsWidgets);
  });

  testWidgets('backend outage still shows the chat workspace', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentsProvider.overrideWith((ref) async => throw Exception('down')),
          agentChatRepositoryProvider.overrideWithValue(
            _FakeAgentChatRepository(),
          ),
          chatCacheStoreProvider.overrideWithValue(InMemoryChatCacheStore()),
          agentFilesProvider.overrideWith((ref, query) async => _files),
          agentCommandsProvider.overrideWith((ref, agentId) async => const []),
        ],
        child: const AgentClientApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agent-im-shell')), findsOneWidget);
    expect(find.byKey(const Key('agent-conversation-list')), findsOneWidget);
    expect(find.byKey(const Key('chat-message-list')), findsOneWidget);
    expect(find.byKey(const Key('chat-input-bar')), findsOneWidget);
    expect(find.text('Backend offline'), findsNothing);
    expect(find.textContaining('Unable to load agent'), findsNothing);
  });

  testWidgets('tablet layout uses compact agent rail and no session rail', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(768, 1024));

    expect(find.byKey(const Key('agent-im-shell')), findsOneWidget);
    expect(find.byKey(const Key('agent-app-rail')), findsOneWidget);
    expect(find.byKey(const Key('agent-conversation-list')), findsOneWidget);
    expect(find.byKey(const Key('agent-compact-rail')), findsNothing);
    expect(find.byKey(const Key('agent-side-rail')), findsNothing);
    expect(find.byKey(const Key('agent-navigation-button')), findsNothing);
    expect(find.byKey(const Key('current-agent-title')), findsOneWidget);
    expect(find.text('nanobot'), findsWidgets);
    expect(find.byKey(const Key('agent-tab-bar')), findsNothing);
    expect(find.byKey(const Key('chat-session-rail')), findsNothing);
    expect(find.byKey(const Key('chat-session-picker-button')), findsNothing);
    expect(find.byKey(const Key('chat-session-switch-button')), findsOneWidget);
    expect(find.byKey(const Key('chat-message-list')), findsOneWidget);
  });

  testWidgets('chat bubbles render markdown, files, and images', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(390, 844));
    await openMobileAgentChat(tester);

    expect(
      find.byKey(const Key('chat-markdown-mock-assistant-rich-content')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('chat-file-ui-spec-file')), findsOneWidget);
    expect(find.text('UI-specification.md'), findsOneWidget);
    expect(find.text('18 KB · Markdown'), findsOneWidget);
    expect(
      find.byKey(const Key('chat-image-tablet-layout-preview')),
      findsOneWidget,
    );
    expect(find.text('Tablet layout preview'), findsOneWidget);
  });

  testWidgets('agent detail toolbar opens workspace files and live task data', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(1200, 800));

    await tester.tap(find.byKey(const Key('agent-detail-files-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agent-tool-dialog')), findsOneWidget);
    expect(find.byKey(const Key('agent-files-list')), findsOneWidget);
    expect(find.text('AGENTS.md'), findsWidgets);
    expect(find.text('workspace'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('agent-detail-tasks-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agent-tool-dialog')), findsOneWidget);
    expect(find.byKey(const Key('agent-tasks-list')), findsOneWidget);
    expect(find.text('No active task'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('global settings page edits backend URL and API key', (
    tester,
  ) async {
    final store = _MemoryAppConfigStore();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigStoreProvider.overrideWithValue(store),
          agentsProvider.overrideWith((ref) async => _agents),
          agentChatRepositoryProvider.overrideWithValue(
            _FakeAgentChatRepository(),
          ),
          chatCacheStoreProvider.overrideWithValue(InMemoryChatCacheStore()),
          agentFilesProvider.overrideWith((ref, query) async => _files),
          agentCommandsProvider.overrideWith((ref, agentId) async => const []),
        ],
        child: const AgentClientApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('global-settings-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agent-tab-bar')), findsNothing);
    final baseUrlField = tester.widget<TextField>(
      find.byKey(const Key('app-settings-base-url-field')),
    );
    final apiKeyField = tester.widget<TextField>(
      find.byKey(const Key('app-settings-api-key-field')),
    );
    expect(baseUrlField.controller?.text, AppConfig.defaultApiBaseUrl);
    expect(apiKeyField.controller?.text, AppConfig.defaultApiKey);

    await tester.enterText(
      find.byKey(const Key('app-settings-base-url-field')),
      'http://10.0.0.2:9800/',
    );
    await tester.enterText(
      find.byKey(const Key('app-settings-api-key-field')),
      'edited-key',
    );
    await tester.tap(find.byKey(const Key('app-settings-save-button')));
    await tester.pumpAndSettle();

    expect(
      store.saved,
      const AppConfig(apiBaseUrl: 'http://10.0.0.2:9800', apiKey: 'edited-key'),
    );
    expect(find.text('Settings saved'), findsOneWidget);
  });

  testWidgets('desktop settings opens from the global side rail', (
    tester,
  ) async {
    await pumpAppAtSize(tester, const Size(1200, 800));

    expect(find.byKey(const Key('agent-settings-tab')), findsNothing);
    expect(find.byKey(const Key('global-settings-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('global-settings-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('app-settings-page')), findsOneWidget);
    expect(find.byKey(const Key('agent-tab-bar')), findsNothing);
  });

  testWidgets('files panel opens folders and saves edited files', (
    tester,
  ) async {
    final resources = _FakeResourcesRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentResourcesRepositoryProvider.overrideWithValue(resources),
        ],
        child: const MaterialApp(
          home: Scaffold(body: FilesPanel(agentId: 'nanobot')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Workspace'), findsOneWidget);
    expect(find.byKey(const Key('agent-file-row-notes')), findsOneWidget);

    await tester.tap(find.byKey(const Key('agent-file-row-notes')));
    await tester.pumpAndSettle();

    expect(find.text('Workspace / notes'), findsOneWidget);
    expect(find.text('TODO.md'), findsOneWidget);

    await tester.tap(find.byKey(const Key('agent-file-row-notes/TODO.md')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agent-file-editor-title')), findsOneWidget);
    final editor = tester.widget<TextField>(
      find.byKey(const Key('agent-file-editor-field')),
    );
    expect(editor.controller?.text, contains('# Todo'));

    await tester.enterText(
      find.byKey(const Key('agent-file-editor-field')),
      '# Todo\n- saved from test\n',
    );
    await tester.tap(find.byKey(const Key('agent-file-save-button')));
    await tester.pumpAndSettle();

    expect(
      resources.savedContentByPath['notes/TODO.md'],
      '# Todo\n- saved from test\n',
    );
    expect(find.byKey(const Key('agent-file-editor-title')), findsNothing);
  });
}

const _agents = [
  Agent(
    id: 'nanobot',
    name: 'nanobot',
    description: '代码审查助手',
    model: 'MiniMax-M2.7-highspeed',
    provider: 'minimax',
    workspace: '/workspace',
  ),
];

AgentSummary _agentSummary(String name, {String? description}) {
  return AgentSummary(
    name: name,
    description: description ?? (name == 'nanobot' ? '代码审查助手' : null),
    wsPort: 8760,
    gatewayPort: 18760,
    workspaceDir: '/workspace/$name',
    status: 'running',
    health: 'healthy',
    model: 'MiniMax-M2.7-highspeed',
    provider: 'minimax',
  );
}

class _FakeAgentControlApi extends Fake implements AgentControlApi {
  _FakeAgentControlApi(this._agents);

  final List<AgentSummary> _agents;
  String? createdName;
  String? createdDescription;
  String? deletedName;

  @override
  Future<AgentListResponse> listAgents() async {
    return AgentListResponse(object: 'list', data: List.of(_agents));
  }

  @override
  Future<CreateAgentResponse> createAgent({
    required String name,
    String? description,
  }) async {
    createdName = name;
    createdDescription = description;
    _agents.add(_agentSummary(name, description: description));
    return CreateAgentResponse(
      name: name,
      wsPort: 8761,
      gatewayPort: 18761,
      configPath: '/agents/$name/config.json',
      workspaceDir: '/workspace/$name',
      status: 'stopped',
      model: 'MiniMax-M2.7-highspeed',
      provider: 'minimax',
    );
  }

  @override
  Future<DeleteAgentResponse> deleteAgent(String agentName) async {
    deletedName = agentName;
    _agents.removeWhere((agent) => agent.name == agentName);
    return DeleteAgentResponse(deleted: true, name: agentName);
  }
}

class _FakeAgentAvatarStore implements AgentAvatarStore {
  final _avatars = <String, String>{};

  String? avatarFor(String agentId) => _avatars[agentId];

  @override
  Future<Map<String, String>> loadAvatarUrls() async {
    return Map.of(_avatars);
  }

  @override
  Future<void> saveAvatar({
    required String agentId,
    required String agentName,
    required String avatarUrl,
    required AgentStatus status,
  }) async {
    _avatars[agentId] = avatarUrl;
  }

  @override
  Future<void> deleteAvatar(String agentId) async {
    _avatars.remove(agentId);
  }
}

class _FakeResourcesRepository implements AgentResourcesRepository {
  final savedContentByPath = <String, String>{};

  @override
  Future<List<AgentFileItem>> listWorkspaceRoot(String agentName) {
    return listWorkspaceDirectory(agentName);
  }

  @override
  Future<List<AgentFileItem>> listWorkspaceDirectory(
    String agentName, {
    String path = '.',
  }) async {
    if (path == 'notes') {
      return const [
        AgentFileItem(
          name: 'TODO.md',
          path: 'notes/TODO.md',
          kind: AgentFileKind.document,
          sizeLabel: 'file',
          updatedLabel: 'notes/TODO.md',
          owner: 'workspace',
        ),
      ];
    }
    return const [
      AgentFileItem(
        name: 'notes',
        path: 'notes',
        kind: AgentFileKind.directory,
        sizeLabel: 'directory',
        updatedLabel: 'notes',
        owner: 'workspace',
      ),
      AgentFileItem(
        name: 'AGENTS.md',
        path: 'AGENTS.md',
        kind: AgentFileKind.document,
        sizeLabel: 'file',
        updatedLabel: 'AGENTS.md',
        owner: 'workspace',
      ),
    ];
  }

  @override
  Future<AgentFileContent> readFile({
    required String agentName,
    required String path,
  }) async {
    final content = savedContentByPath[path] ?? '# Todo\n- write tests\n';
    return AgentFileContent(
      path: path,
      size: content.length,
      mtimeMs: 1,
      content: content,
    );
  }

  @override
  Future<AgentFileWriteResult> writeFile({
    required String agentName,
    required String path,
    required String content,
  }) async {
    savedContentByPath[path] = content;
    return AgentFileWriteResult(path: path, size: content.length, mtimeMs: 2);
  }

  @override
  Future<List<AgentFileItem>> search({
    required String agentName,
    required String query,
  }) async {
    return const [];
  }
}

const _files = [
  AgentFileItem(
    name: 'AGENTS.md',
    path: 'AGENTS.md',
    kind: AgentFileKind.document,
    sizeLabel: 'file',
    updatedLabel: 'AGENTS.md',
    owner: 'workspace',
  ),
];

class _FakeAgentChatRepository implements AgentChatRepository {
  @override
  Future<String> ensureSessionId(String agentId) async => 'session-1';

  @override
  Future<ChatSessionSummary> startNewSession(String agentId) async {
    return const ChatSessionSummary(
      id: 'session-new',
      title: 'New chat',
      preview: '',
      messageCount: 0,
    );
  }

  @override
  Future<List<ChatSessionSummary>> listSessions(String agentId) async {
    return const [
      ChatSessionSummary(
        id: 'session-1',
        title: 'Backend layout review',
        preview: 'I found three UI priorities.',
        messageCount: 2,
      ),
      ChatSessionSummary(
        id: 'session-flaky-test',
        title: 'Backend flaky test',
        preview: 'Session restore looks suspicious.',
        messageCount: 4,
        status: ChatSessionStatus.running,
      ),
      ChatSessionSummary(
        id: 'session-api3',
        title: 'API3 migration',
        preview: 'Align sessions, attach, and SSE.',
        messageCount: 6,
      ),
    ];
  }

  @override
  Future<void> cancelActiveResponse({
    required String agentId,
    required String sessionId,
  }) async {}

  @override
  Future<List<ChatMessage>> loadRecentMessages(
    String agentId, {
    String? sessionId,
  }) async {
    if (sessionId == 'session-flaky-test') {
      return [
        ChatMessage(
          id: 'session-flaky-test-user',
          agentId: agentId,
          conversationId: sessionId!,
          role: ChatRole.user,
          content: 'Why is the restore test flaky?',
          status: ChatMessageStatus.completed,
          createdAt: DateTime(2026, 5, 28, 16),
        ),
        ChatMessage(
          id: 'session-flaky-test-assistant',
          agentId: agentId,
          conversationId: sessionId,
          role: ChatRole.assistant,
          content: 'The failing test is tied to session restore.',
          status: ChatMessageStatus.completed,
          createdAt: DateTime(2026, 5, 28, 16, 1),
        ),
      ];
    }
    if (sessionId != null && sessionId != 'session-1') {
      return const [];
    }
    return [
      ChatMessage(
        id: 'mock-user-layout-request',
        agentId: agentId,
        conversationId: 'session-1',
        role: ChatRole.user,
        content: 'Review the mobile chat layout',
        status: ChatMessageStatus.completed,
        createdAt: DateTime(2026, 5, 29, 9),
      ),
      ChatMessage(
        id: 'mock-assistant-rich-content',
        agentId: agentId,
        conversationId: 'session-1',
        role: ChatRole.assistant,
        content: 'I found three UI priorities:\n\n- Keep chat primary.',
        status: ChatMessageStatus.completed,
        createdAt: DateTime(2026, 5, 29, 9, 1),
        attachments: const [
          ChatAttachment(
            id: 'ui-spec-file',
            kind: ChatAttachmentKind.file,
            name: 'UI-specification.md',
            sizeLabel: '18 KB',
            typeLabel: 'Markdown',
          ),
          ChatAttachment(
            id: 'tablet-layout-preview',
            kind: ChatAttachmentKind.image,
            name: 'Tablet layout preview',
            sizeLabel: '1.1 MB',
            typeLabel: 'PNG',
          ),
        ],
      ),
    ];
  }

  @override
  Stream<ChatEvent> sendMessage(SendMessageRequest request) async* {}
}

class _MemoryAppConfigStore implements AppConfigStore {
  AppConfig? saved;

  @override
  Future<AppConfig?> load() async => saved;

  @override
  Future<void> save(AppConfig config) async {
    saved = config;
  }
}
