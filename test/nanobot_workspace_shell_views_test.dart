import 'dart:async';

import 'package:agent_client/features/nanobot/application/nanobot_workspace_controller.dart';
import 'package:agent_client/features/nanobot/data/nanobot_providers.dart';
import 'package:agent_client/features/nanobot/data/nanobot_repository.dart';
import 'package:agent_client/features/nanobot/data/nanobot_ws_client.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_bootstrap.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_event.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_media_attachment.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_message.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_shell_models.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_thread_page.dart';
import 'package:agent_client/features/nanobot/presentation/nanobot_workspace_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets('sidebar utility entries switch to secondary webui surfaces', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    final appsTop = tester.getTopLeft(find.text('Apps').first).dy;
    final skillsTop = tester.getTopLeft(find.text('Skills').first).dy;
    final automationsTop = tester.getTopLeft(find.text('Automations').first).dy;
    expect(appsTop, lessThan(skillsTop));
    expect(skillsTop, lessThan(automationsTop));

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Token Usage'), findsOneWidget);
    expect(find.byKey(const ValueKey('usage-day-2026-07-08')), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Current model'), findsOneWidget);
    expect(find.text('Capabilities'), findsOneWidget);
    expect(find.text('Web search'), findsOneWidget);
    expect(find.text('Image generation'), findsOneWidget);
    expect(find.text('Voice input'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Gateway'), findsOneWidget);
    expect(find.text('Workspace'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('MiniMax-M3'), findsOneWidget);
    expect(find.textContaining('openai'), findsWidgets);
    expect(find.text('Check for updates'), findsOneWidget);

    await tester.ensureVisible(find.text('Check for updates'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(find.text('Update available v1.3.0'), findsOneWidget);

    await tester.ensureVisible(find.text('Web search'));
    await tester.tap(find.text('Web search'));
    await tester.pumpAndSettle();
    expect(find.text('Web search settings'), findsOneWidget);
    expect(find.text('Max results'), findsOneWidget);
    expect(find.text('Timeout'), findsOneWidget);
    expect(find.text('Jina reader'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('web-search-max-increment')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Web search'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Web search'));
    await tester.pumpAndSettle();
    expect(repository.webSearchSaveRequests, hasLength(1));
    expect(repository.webSearchSaveRequests.single.maxResults, 6);
    expect(find.text('Saved. Restart when ready.'), findsOneWidget);

    await tester.ensureVisible(find.byIcon(Icons.chevron_left).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_left).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Image generation'));
    await tester.tap(find.text('Image generation'));
    await tester.pumpAndSettle();
    expect(find.text('Image generation settings'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Image generation settings')).dy,
      greaterThanOrEqualTo(0),
    );
    expect(find.text('Image provider'), findsOneWidget);
    expect(find.text('Provider base'), findsOneWidget);
    expect(find.text('Image model'), findsOneWidget);
    expect(find.text('Default aspect'), findsOneWidget);
    expect(find.text('Default size'), findsOneWidget);
    expect(find.text('Max images per turn'), findsOneWidget);
    expect(find.text('Save directory'), findsOneWidget);

    expect(
      tester
          .widget<Switch>(
            find.byKey(const ValueKey('image-generation-enabled-toggle')),
          )
          .value,
      isTrue,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('image-generation-max-increment')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('image-generation-max-increment')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Image generation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Image generation'));
    await tester.pumpAndSettle();
    expect(repository.imageGenerationSaveRequests, hasLength(1));
    expect(repository.imageGenerationSaveRequests.single.enabled, isTrue);
    expect(repository.imageGenerationSaveRequests.single.maxImagesPerTurn, 3);
    expect(find.text('Saved. Restart when ready.'), findsOneWidget);

    await tester.tap(find.text('Apps'));
    await tester.pumpAndSettle();
    expect(find.text('Apps'), findsWidgets);
    expect(find.text('GIMP'), findsOneWidget);
    expect(find.text('installed'), findsOneWidget);

    await tester.tap(find.text('Automations'));
    await tester.pumpAndSettle();
    expect(find.text('Automations'), findsWidgets);
    expect(find.text('Daily ping'), findsWidgets);
    expect(find.text('Active'), findsOneWidget);

    await tester.tap(find.text('Skills'));
    await tester.pumpAndSettle();
    expect(find.text('Skills'), findsWidgets);
    expect(find.text('browser'), findsOneWidget);
    expect(find.text('available'), findsOneWidget);

    await tester.tap(find.text('Chats'));
    await tester.pumpAndSettle();
    final state = ProviderScope.containerOf(
      tester.element(find.byType(NanobotWorkspacePage)),
    ).read(nanobotWorkspaceControllerProvider);
    expect(state.activeView, NanobotShellView.chat);
    expect(find.text('Start a chat'), findsOneWidget);
  });

  testWidgets('settings voice input detail mirrors webui fields and saves', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Voice input'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voice input'));
    await tester.pumpAndSettle();

    expect(find.text('Voice input settings'), findsOneWidget);
    expect(find.text('Transcription'), findsOneWidget);
    expect(find.text('Provider'), findsOneWidget);
    expect(find.text('Provider status'), findsOneWidget);
    expect(find.text('Model'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Limits'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('voice-max-duration-increment')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('voice-max-duration-increment')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Voice input'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Voice input'));
    await tester.pumpAndSettle();

    expect(repository.transcriptionSaveRequests, hasLength(1));
    expect(repository.transcriptionSaveRequests.single.provider, 'openai');
    expect(repository.transcriptionSaveRequests.single.model, 'whisper');
    expect(repository.transcriptionSaveRequests.single.language, 'zh');
    expect(repository.transcriptionSaveRequests.single.maxDurationSec, 61);
    expect(repository.transcriptionSaveRequests.single.maxUploadMb, 20);
    expect(find.text('Saved. Restart when ready.'), findsOneWidget);
  });

  testWidgets('settings network safety detail mirrors webui fields and saves', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('App safety'), findsOneWidget);
    await tester.ensureVisible(find.text('App safety'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('App safety'));
    await tester.pumpAndSettle();

    expect(find.text('App safety settings'), findsOneWidget);
    expect(find.text('Local Service Access'), findsOneWidget);
    expect(find.text('Default access'), findsOneWidget);
    expect(
      find.text('Core channel safety stays in config.json.'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('network-local-service-toggle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('network-default-access-full')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save App safety'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save App safety'));
    await tester.pumpAndSettle();

    expect(repository.networkSafetySaveRequests, hasLength(1));
    expect(
      repository.networkSafetySaveRequests.single.webuiAllowLocalServiceAccess,
      isFalse,
    );
    expect(
      repository.networkSafetySaveRequests.single.webuiDefaultAccessMode,
      'full',
    );
    expect(find.text('Saved. Restart when ready.'), findsOneWidget);
  });

  testWidgets(
    'settings runtime identity detail mirrors webui fields and saves',
    (tester) async {
      final repository = _FakeNanobotRepository();
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: NanobotWorkspacePage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Runtime'), findsOneWidget);
      await tester.ensureVisible(find.text('Runtime'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Runtime'));
      await tester.pumpAndSettle();

      expect(find.text('Runtime settings'), findsOneWidget);
      expect(find.text('Identity'), findsOneWidget);
      expect(find.text('Bot name'), findsOneWidget);
      expect(find.text('Bot icon'), findsOneWidget);
      expect(find.text('Timezone'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('runtime-bot-name-field')),
        'Nano Mobile',
      );
      await tester.enterText(
        find.byKey(const ValueKey('runtime-bot-icon-field')),
        'N',
      );
      await tester.enterText(
        find.byKey(const ValueKey('runtime-timezone-field')),
        'Asia/Shanghai',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save Runtime'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Runtime'));
      await tester.pumpAndSettle();

      expect(repository.runtimeSaveRequests, hasLength(1));
      expect(repository.runtimeSaveRequests.single.botName, 'Nano Mobile');
      expect(repository.runtimeSaveRequests.single.botIcon, 'N');
      expect(repository.runtimeSaveRequests.single.timezone, 'Asia/Shanghai');
      expect(find.text('Saved. Restart when ready.'), findsOneWidget);
    },
  );

  testWidgets('settings model detail mirrors webui fields and saves', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Current model'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Current model'));
    await tester.pumpAndSettle();

    expect(find.text('Model settings'), findsOneWidget);
    expect(find.text('Current configuration'), findsOneWidget);
    expect(find.text('Provider'), findsOneWidget);
    expect(find.text('Model'), findsWidgets);
    expect(find.text('Context window'), findsOneWidget);
    expect(find.text('64K'), findsOneWidget);
    expect(find.text('200K'), findsOneWidget);
    expect(find.text('256K'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('model-provider-field')),
      'openai',
    );
    await tester.enterText(
      find.byKey(const ValueKey('model-id-field')),
      'MiniMax-M4',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('model-context-window-64k')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('model-context-window-64k')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Model'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Model'));
    await tester.pumpAndSettle();

    expect(repository.modelSaveRequests, hasLength(1));
    expect(repository.modelSaveRequests.single.modelPreset, 'default');
    expect(repository.modelSaveRequests.single.model, 'MiniMax-M4');
    expect(repository.modelSaveRequests.single.provider, isNull);
    expect(repository.modelSaveRequests.single.contextWindowTokens, 65536);
    expect(find.text('Saved. Restart when ready.'), findsOneWidget);
  });

  testWidgets('settings model detail loads provider models and selects one', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      settingsSnapshot: const NanobotSettingsSnapshot(
        modelPreset: 'default',
        model: 'deepseek-chat',
        provider: 'deepseek',
        contextWindowTokens: 65536,
      ),
      providerModelCatalogs: const {
        'deepseek': ['deepseek-chat', 'deepseek-reasoner'],
      },
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Current model'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Current model'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('model-picker-button')));
    await tester.pumpAndSettle();

    expect(repository.providerModelRequests, ['deepseek']);
    expect(find.text('deepseek-reasoner'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('provider-model-deepseek-reasoner')),
        matching: find.text('65.5K'),
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('provider-model-deepseek-reasoner')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('deepseek-reasoner'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Model'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Model'));
    await tester.pumpAndSettle();

    expect(repository.modelSaveRequests.single.model, 'deepseek-reasoner');
    expect(repository.modelSaveRequests.single.provider, isNull);
    expect(repository.modelSaveRequests.single.contextWindowTokens, isNull);
  });

  testWidgets('settings model picker filters provider catalog by query', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      settingsSnapshot: const NanobotSettingsSnapshot(
        modelPreset: 'default',
        model: 'deepseek-chat',
        provider: 'deepseek',
        contextWindowTokens: 65536,
      ),
      providerModelCatalogs: const {
        'deepseek': ['deepseek-chat', 'deepseek-coder', 'deepseek-reasoner'],
      },
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Current model'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Current model'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('model-picker-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('model-id-field')),
      'reasoner',
    );
    await tester.pumpAndSettle();

    expect(find.text('deepseek-reasoner'), findsOneWidget);
    expect(find.text('deepseek-chat'), findsNothing);
    expect(find.text('deepseek-coder'), findsNothing);
  });

  testWidgets('settings model picker accepts custom model ids', (tester) async {
    final repository = _FakeNanobotRepository(
      settingsSnapshot: const NanobotSettingsSnapshot(
        modelPreset: 'default',
        model: 'deepseek-chat',
        provider: 'deepseek',
        contextWindowTokens: 65536,
      ),
      providerModelCatalogs: const {
        'deepseek': ['deepseek-chat', 'deepseek-reasoner'],
      },
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Current model'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Current model'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('model-picker-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('model-id-field')),
      'deepseek-custom',
    );
    await tester.pumpAndSettle();

    expect(find.text('No matching models.'), findsOneWidget);
    expect(find.text('Use "deepseek-custom"'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('provider-model-custom')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use "deepseek-custom"'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Model'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Model'));
    await tester.pumpAndSettle();

    expect(repository.modelSaveRequests.single.model, 'deepseek-custom');
    expect(repository.modelSaveRequests.single.provider, isNull);
    expect(repository.modelSaveRequests.single.contextWindowTokens, isNull);
  });

  testWidgets(
    'settings model picker does not fetch models for unsigned OAuth providers',
    (tester) async {
      final repository = _FakeNanobotRepository(
        settingsSnapshot: const NanobotSettingsSnapshot(
          modelPreset: 'default',
          model: 'openai-codex/gpt-5.1-codex',
          provider: 'openai_codex',
          contextWindowTokens: 65536,
          providers: [
            NanobotProviderConfig(
              name: 'openai_codex',
              label: 'OpenAI Codex',
              configured: false,
              authType: 'oauth',
              oauthLoginSupported: true,
            ),
          ],
        ),
        providerModelCatalogs: const {
          'openai_codex': ['openai-codex/gpt-5.1-codex'],
        },
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: NanobotWorkspacePage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Current model'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Current model'));
      await tester.pumpAndSettle();

      expect(find.text('Not configured'), findsOneWidget);
      expect(find.text('OpenAI Codex'), findsOneWidget);
      expect(find.text('openai-codex/gpt-5.1-codex'), findsWidgets);

      await tester.ensureVisible(
        find.byKey(const ValueKey('model-picker-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('model-picker-button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Configure this provider before loading models.'),
        findsOneWidget,
      );
      expect(repository.providerModelRequests, isEmpty);
    },
  );

  testWidgets('settings model configuration dialog creates and cancels', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      settingsSnapshot: const NanobotSettingsSnapshot(
        modelPreset: 'default',
        model: 'deepseek-chat',
        provider: 'deepseek',
        contextWindowTokens: 65536,
        providers: [
          NanobotProviderConfig(
            name: 'deepseek',
            label: 'DeepSeek',
            configured: true,
            authType: 'api_key',
          ),
        ],
      ),
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Current model'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Current model'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('add-model-configuration-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('New model configuration'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('New model configuration'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('add-model-configuration-button')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('model-configuration-label-field')),
      'Fast writing',
    );
    await tester.enterText(
      find.byKey(const ValueKey('model-configuration-model-field')),
      'deepseek-reasoner',
    );
    await tester.enterText(
      find.byKey(const ValueKey('model-configuration-provider-field')),
      'deepseek',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.modelConfigurationCreateRequests, hasLength(1));
    expect(
      repository.modelConfigurationCreateRequests.single.label,
      'Fast writing',
    );
    expect(
      repository.modelConfigurationCreateRequests.single.provider,
      'deepseek',
    );
    expect(
      repository.modelConfigurationCreateRequests.single.model,
      'deepseek-reasoner',
    );
  });

  testWidgets('settings model preset rows switch saved configurations', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      settingsSnapshot: const NanobotSettingsSnapshot(
        modelPreset: 'default',
        model: 'deepseek-chat',
        provider: 'deepseek',
        contextWindowTokens: 65536,
        modelPresets: [
          NanobotModelPreset(
            name: 'default',
            label: 'Default',
            model: 'deepseek-chat',
            provider: 'deepseek',
            contextWindowTokens: 65536,
            isDefault: true,
            active: true,
          ),
          NanobotModelPreset(
            name: 'fast-writing',
            label: 'Fast writing',
            model: 'openai/gpt-4.1-mini',
            provider: 'openai',
            contextWindowTokens: 262144,
          ),
        ],
        providers: [
          NanobotProviderConfig(
            name: 'deepseek',
            label: 'DeepSeek',
            configured: true,
            authType: 'api_key',
          ),
          NanobotProviderConfig(
            name: 'openai',
            label: 'OpenAI',
            configured: true,
            authType: 'api_key',
          ),
        ],
      ),
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Current model'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Current model'));
    await tester.pumpAndSettle();

    expect(find.text('Saved configurations'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('model-preset-fast-writing')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('model-preset-fast-writing')));
    await tester.pumpAndSettle();

    expect(find.text('Fast writing'), findsWidgets);
    expect(
      find.widgetWithText(TextField, 'openai/gpt-4.1-mini'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextField, 'openai'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Fast writing'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('model-preset-label-field')),
      'Fast drafting',
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('model-context-window-256k')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('model-context-window-256k')),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Save Model'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Model'));
    await tester.pumpAndSettle();

    expect(repository.modelSaveRequests, isEmpty);
    expect(repository.modelConfigurationUpdateRequests, hasLength(1));
    final request = repository.modelConfigurationUpdateRequests.single;
    expect(request.name, 'fast-writing');
    expect(request.label, 'Fast drafting');
    expect(request.model, 'openai/gpt-4.1-mini');
    expect(request.provider, 'openai');
    expect(request.contextWindowTokens, isNull);
  });

  testWidgets('apps surface filters and searches webui catalog kinds', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      appItems: const [
        NanobotCatalogItem(
          id: 'nanobot:websocket',
          title: 'WebSocket',
          subtitle: 'Required for WebUI',
          status: 'Channel',
          filterKeys: ['nanobot', 'ready'],
        ),
        NanobotCatalogItem(
          id: 'cli:gimp',
          title: 'GIMP',
          subtitle: 'Image editor',
          status: 'CLI',
          filterKeys: ['cli', 'ready'],
        ),
        NanobotCatalogItem(
          id: 'mcp:github',
          title: 'GitHub',
          subtitle: 'Repository tools',
          status: 'Configured',
          filterKeys: ['mcp', 'ready'],
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apps'));
    await tester.pumpAndSettle();

    expect(find.text('1 Plugin · 1 CLI · 1 MCP'), findsOneWidget);
    expect(find.text('Catalog'), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.text('WebSocket'), findsOneWidget);
    expect(find.text('GIMP'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);

    await tester.tap(find.text('MCP services'));
    await tester.pumpAndSettle();

    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('GIMP'), findsNothing);
    expect(find.text('WebSocket'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('apps-catalog-search')),
      'image',
    );
    await tester.pumpAndSettle();

    expect(find.text('No apps match this filter.'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.text('GIMP'), findsOneWidget);
    expect(find.text('GitHub'), findsNothing);
  });

  testWidgets('apps surface runs installed CLI actions and keeps other kinds', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      appItems: const [
        NanobotCatalogItem(
          id: 'nanobot:websocket',
          title: 'WebSocket',
          subtitle: 'Required for WebUI',
          status: 'Channel',
          filterKeys: ['nanobot', 'ready'],
        ),
        NanobotCatalogItem(
          id: 'cli:gimp',
          title: 'GIMP',
          subtitle: 'Image editor',
          status: 'CLI',
          filterKeys: ['cli', 'ready'],
        ),
        NanobotCatalogItem(
          id: 'mcp:github',
          title: 'GitHub',
          subtitle: 'Repository tools',
          status: 'Configured',
          filterKeys: ['mcp', 'ready'],
        ),
      ],
      actionAppItems: const [
        NanobotCatalogItem(
          id: 'cli:gimp',
          title: 'GIMP',
          subtitle: 'CLI healthy',
          status: 'CLI',
          filterKeys: ['cli', 'ready'],
        ),
      ],
      actionMessage: 'GIMP CLI is healthy',
      actionRequiresRestart: true,
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apps'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('GIMP'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('CLI installed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test CLI'));
    await tester.pumpAndSettle();

    expect(repository.cliActionRequests, [(action: 'test', name: 'gimp')]);
    expect(find.text('CLI healthy'), findsOneWidget);
    expect(find.text('GIMP CLI is healthy'), findsOneWidget);
    expect(
      find.text('Restart nanobot to apply updated apps and features.'),
      findsOneWidget,
    );
    expect(find.text('WebSocket'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);
  });

  testWidgets(
    'apps surface runs nanobot feature actions and keeps other kinds',
    (tester) async {
      final repository = _FakeNanobotRepository(
        appItems: const [
          NanobotCatalogItem(
            id: 'nanobot:sms',
            title: 'SMS',
            subtitle: 'Enabled',
            status: 'Channel',
            filterKeys: ['nanobot', 'ready', 'channel'],
          ),
          NanobotCatalogItem(
            id: 'cli:gimp',
            title: 'GIMP',
            subtitle: 'Image editor',
            status: 'CLI',
            filterKeys: ['cli', 'ready'],
          ),
          NanobotCatalogItem(
            id: 'mcp:github',
            title: 'GitHub',
            subtitle: 'Repository tools',
            status: 'Configured',
            filterKeys: ['mcp', 'ready'],
          ),
        ],
        actionAppItems: const [
          NanobotCatalogItem(
            id: 'nanobot:sms',
            title: 'SMS',
            subtitle: 'Disabled',
            status: 'Channel',
            filterKeys: ['nanobot', 'unavailable', 'channel'],
          ),
        ],
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: NanobotWorkspacePage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apps'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Disable'));
      await tester.pumpAndSettle();

      expect(repository.nanobotFeatureActionRequests, [
        (action: 'disable', name: 'sms'),
      ]);
      expect(find.text('Disabled'), findsOneWidget);
      expect(find.text('GIMP'), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);
    },
  );

  testWidgets(
    'apps surface runs configured MCP actions and keeps other kinds',
    (tester) async {
      final repository = _FakeNanobotRepository(
        appItems: const [
          NanobotCatalogItem(
            id: 'nanobot:websocket',
            title: 'WebSocket',
            subtitle: 'Required for WebUI',
            status: 'Channel',
            filterKeys: ['nanobot', 'ready', 'channel'],
          ),
          NanobotCatalogItem(
            id: 'cli:gimp',
            title: 'GIMP',
            subtitle: 'Image editor',
            status: 'CLI',
            filterKeys: ['cli', 'ready'],
          ),
          NanobotCatalogItem(
            id: 'mcp:github',
            title: 'GitHub',
            subtitle: 'Repository tools',
            status: 'Configured',
            filterKeys: ['mcp', 'ready'],
          ),
        ],
        actionAppItems: const [
          NanobotCatalogItem(
            id: 'mcp:github',
            title: 'GitHub',
            subtitle: 'MCP healthy',
            status: 'Configured',
            filterKeys: ['mcp', 'ready'],
          ),
        ],
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: NanobotWorkspacePage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apps'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('GitHub'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('MCP configured'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test MCP'));
      await tester.pumpAndSettle();

      expect(repository.mcpPresetActionRequests, hasLength(1));
      expect(repository.mcpPresetActionRequests.single.action, 'test');
      expect(repository.mcpPresetActionRequests.single.name, 'github');
      expect(repository.mcpPresetActionRequests.single.values, isEmpty);
      expect(find.text('MCP healthy'), findsOneWidget);
      expect(find.text('WebSocket'), findsOneWidget);
      expect(find.text('GIMP'), findsOneWidget);
    },
  );

  testWidgets('apps surface collects required MCP setup fields before enable', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      appItems: const [
        NanobotCatalogItem(
          id: 'mcp:browserbase',
          title: 'Browserbase',
          subtitle: 'Cloud browser automation',
          status: 'Needs setup',
          filterKeys: ['mcp', 'unavailable', 'install_supported'],
          mcpRequiredFields: [
            NanobotMcpRequiredField(
              name: 'browserbase_api_key',
              label: 'API key',
              placeholder: 'Paste key',
              secret: true,
              required: true,
              configured: false,
            ),
          ],
        ),
      ],
      actionAppItems: const [
        NanobotCatalogItem(
          id: 'mcp:browserbase',
          title: 'Browserbase',
          subtitle: 'Configured',
          status: 'Configured',
          filterKeys: ['mcp', 'ready'],
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apps'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Set up'));
    await tester.pumpAndSettle();

    expect(find.text('Connect Browserbase'), findsOneWidget);
    expect(find.text('API key'), findsOneWidget);
    expect(find.text('Save and enable'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Save and enable'),
          )
          .enabled,
      isFalse,
    );

    await tester.enterText(find.byType(TextField).last, 'bb_live_key');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Save and enable'),
          )
          .enabled,
      isTrue,
    );
    await tester.tap(find.text('Save and enable'));
    await tester.pumpAndSettle();

    expect(repository.mcpPresetActionRequests, hasLength(1));
    expect(repository.mcpPresetActionRequests.single.action, 'enable');
    expect(repository.mcpPresetActionRequests.single.name, 'browserbase');
    expect(repository.mcpPresetActionRequests.single.values, {
      'browserbase_api_key': 'bb_live_key',
    });
    expect(find.text('Configured'), findsWidgets);
  });

  testWidgets('apps surface updates configured MCP tool scope', (tester) async {
    final repository = _FakeNanobotRepository(
      appItems: const [
        NanobotCatalogItem(
          id: 'mcp:github',
          title: 'GitHub',
          subtitle: 'Repository tools',
          status: 'Configured',
          filterKeys: ['mcp', 'ready'],
          mcpToolNames: ['repo_read', 'issue_create'],
          mcpEnabledTools: ['repo_read'],
        ),
        NanobotCatalogItem(
          id: 'cli:gimp',
          title: 'GIMP',
          subtitle: 'Image editor',
          status: 'CLI',
          filterKeys: ['cli', 'ready'],
        ),
      ],
      actionAppItems: const [
        NanobotCatalogItem(
          id: 'mcp:github',
          title: 'GitHub',
          subtitle: 'Repository tools',
          status: 'Configured',
          filterKeys: ['mcp', 'ready'],
          mcpToolNames: ['repo_read', 'issue_create'],
          mcpEnabledTools: [],
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apps'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('GitHub'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('MCP configured'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tools'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();

    expect(repository.mcpToolsUpdateRequests, hasLength(1));
    expect(repository.mcpToolsUpdateRequests.single.name, 'github');
    expect(repository.mcpToolsUpdateRequests.single.enabledTools, isEmpty);
    expect(find.text('GIMP'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);
  });

  testWidgets('apps surface saves custom MCP server values', (tester) async {
    final repository = _FakeNanobotRepository(
      appItems: const [
        NanobotCatalogItem(
          id: 'mcp:github',
          title: 'GitHub',
          subtitle: 'Repository tools',
          status: 'Configured',
          filterKeys: ['mcp', 'ready'],
        ),
      ],
      actionAppItems: const [
        NanobotCatalogItem(
          id: 'mcp:docs',
          title: 'docs',
          subtitle: 'Custom docs server',
          status: 'Configured',
          filterKeys: ['mcp', 'ready'],
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apps'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('More MCP options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();

    expect(find.text('Server name'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('Command'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save MCP'))
          .enabled,
      isFalse,
    );

    await tester.enterText(
      find.byKey(const ValueKey('custom-mcp-name')),
      'docs',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom-mcp-command')),
      'npx',
    );
    await tester.ensureVisible(find.text('Advanced options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Advanced options'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('custom-mcp-args')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('custom-mcp-args')),
      '["-y","docs-mcp"]',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom-mcp-env')),
      '{"API_KEY":"secret"}',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom-mcp-timeout')),
      '30',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save MCP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save MCP'));
    await tester.pumpAndSettle();

    expect(repository.customMcpRequests, hasLength(1));
    expect(repository.customMcpRequests.single, {
      'name': 'docs',
      'transport': 'stdio',
      'command': 'npx',
      'args': '["-y","docs-mcp"]',
      'url': '',
      'env': '{"API_KEY":"secret"}',
      'headers': '',
      'tool_timeout': '30',
    });
    expect(find.text('Custom docs server'), findsOneWidget);
    expect(find.text('GitHub'), findsNothing);
  });

  testWidgets('apps surface imports mcp.json config', (tester) async {
    final repository = _FakeNanobotRepository(
      appItems: const [
        NanobotCatalogItem(
          id: 'mcp:github',
          title: 'GitHub',
          subtitle: 'Repository tools',
          status: 'Configured',
          filterKeys: ['mcp', 'ready'],
        ),
      ],
      actionAppItems: const [
        NanobotCatalogItem(
          id: 'mcp:filesystem',
          title: 'filesystem',
          subtitle: 'Imported server',
          status: 'Configured',
          filterKeys: ['mcp', 'ready'],
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apps'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('More MCP options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    expect(find.text('Import mcp.json'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Import'))
          .enabled,
      isFalse,
    );
    await tester.enterText(
      find.byKey(const ValueKey('mcp-config-import')),
      '{"mcpServers":{"filesystem":{"command":"npx"}}}',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Import').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import').last);
    await tester.pumpAndSettle();

    expect(repository.mcpConfigImports, [
      '{"mcpServers":{"filesystem":{"command":"npx"}}}',
    ]);
    expect(find.text('filesystem'), findsOneWidget);
    expect(find.text('GitHub'), findsNothing);
  });

  testWidgets('automations empty surface keeps heading and webui empty copy', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(automationItems: const []);
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Automations'));
    await tester.pumpAndSettle();

    expect(find.text('Automations'), findsWidgets);
    expect(find.text('No automations yet.'), findsOneWidget);
    expect(find.text('No automations'), findsNothing);
  });

  testWidgets('automations surface shows message origin and expands details', (
    tester,
  ) async {
    const longMessage =
        'Review the release plan and prepare a concise status update.\n'
        'Include blockers, owners, follow-up dates, and risky assumptions.\n'
        'Keep the output actionable and avoid repeated context.\n'
        'Call out stale dependencies and ask for owner updates.\n'
        'This message is long enough to need progressive disclosure.';
    final repository = _FakeNanobotRepository(
      automationItems: const [
        NanobotCatalogItem(
          id: 'long-details',
          title: 'Long detail automation',
          subtitle: longMessage,
          details: 'Release prep',
          status: 'Active',
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Automations'));
    await tester.pumpAndSettle();

    expect(find.text('Long detail automation'), findsWidgets);
    expect(find.text('Release prep'), findsWidgets);
    expect(find.text('Show full message'), findsWidgets);

    await tester.ensureVisible(find.text('Show full message').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show full message').first);
    await tester.pumpAndSettle();

    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('automations surface filters by message and linked chat', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      automationItems: const [
        NanobotCatalogItem(
          id: 'repo-check',
          title: 'Daily repo check',
          subtitle: 'Check the repo status',
          details: 'Release prep',
          status: 'Active',
        ),
        NanobotCatalogItem(
          id: 'wechat-quiz',
          title: 'WeChat quiz',
          subtitle: 'Send a quiz',
          details: 'WeChat',
          status: 'Active',
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Automations'));
    await tester.pumpAndSettle();

    final search = find.widgetWithText(
      TextField,
      'Search task, message, linked chat, or schedule',
    );
    expect(search, findsOneWidget);

    await tester.enterText(search, 'Release');
    await tester.pumpAndSettle();

    expect(find.text('Daily repo check'), findsWidgets);
    expect(find.text('WeChat quiz'), findsNothing);

    await tester.enterText(search, 'quiz');
    await tester.pumpAndSettle();

    expect(find.text('Daily repo check'), findsNothing);
    expect(find.text('WeChat quiz'), findsWidgets);
  });

  testWidgets('automations search supports webui field prefixes', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      automationItems: const [
        NanobotCatalogItem(
          id: 'paused',
          title: 'Paused job',
          subtitle: 'every',
          details: 'Release prep',
          status: 'Paused',
          filterKeys: ['paused'],
        ),
        NanobotCatalogItem(
          id: 'cron',
          title: 'Cron job',
          subtitle: 'cron',
          details: 'WeChat',
          status: 'Active',
          filterKeys: ['active'],
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Automations'));
    await tester.pumpAndSettle();

    final search = find.widgetWithText(
      TextField,
      'Search task, message, linked chat, or schedule',
    );

    await tester.enterText(search, 'status:paused');
    await tester.pumpAndSettle();

    expect(find.text('Paused job'), findsWidgets);
    expect(find.text('Cron job'), findsNothing);

    await tester.enterText(search, 'schedule:cron');
    await tester.pumpAndSettle();

    expect(find.text('Paused job'), findsNothing);
    expect(find.text('Cron job'), findsWidgets);
  });

  testWidgets('automations surface filter chips narrow by status', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      automationItems: const [
        NanobotCatalogItem(
          id: 'active',
          title: 'Active job',
          status: 'Active',
          filterKeys: ['active'],
        ),
        NanobotCatalogItem(
          id: 'paused',
          title: 'Paused job',
          status: 'Paused',
          filterKeys: ['paused'],
        ),
        NanobotCatalogItem(
          id: 'failed',
          title: 'Failed job',
          status: 'Active',
          filterKeys: ['failed'],
        ),
        NanobotCatalogItem(
          id: 'system',
          title: 'System job',
          status: 'Active',
          filterKeys: ['system'],
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Automations'));
    await tester.pumpAndSettle();

    expect(find.text('All 4'), findsOneWidget);
    expect(find.text('Active 1'), findsOneWidget);
    expect(find.text('Paused 1'), findsOneWidget);
    expect(find.text('Needs attention 1'), findsOneWidget);
    expect(find.text('System 1'), findsOneWidget);

    await tester.tap(find.text('Paused 1'));
    await tester.pumpAndSettle();

    expect(find.text('Paused job'), findsWidgets);
    expect(find.text('Active job'), findsNothing);
    expect(find.text('Failed job'), findsNothing);

    await tester.tap(find.text('Needs attention 1'));
    await tester.pumpAndSettle();

    expect(find.text('Failed job'), findsWidgets);
    expect(find.text('Paused job'), findsNothing);
  });

  testWidgets('automations surface sorts by next run and name', (tester) async {
    final repository = _FakeNanobotRepository(
      automationItems: const [
        NanobotCatalogItem(
          id: 'zeta',
          title: 'Zeta job',
          status: 'Active',
          filterKeys: ['active'],
          nextRunAtMs: 1000,
        ),
        NanobotCatalogItem(
          id: 'alpha',
          title: 'Alpha job',
          status: 'Active',
          filterKeys: ['active'],
          nextRunAtMs: 2000,
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Automations'));
    await tester.pumpAndSettle();

    expect(_isAbove(tester, 'Zeta job', 'Alpha job'), isTrue);

    await tester.tap(find.text('Next run'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name').last);
    await tester.pumpAndSettle();

    expect(_isAbove(tester, 'Alpha job', 'Zeta job'), isTrue);
  });

  testWidgets('automations action buttons refresh action results', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      automationItems: const [
        NanobotCatalogItem(
          id: 'job-1',
          title: 'Daily job',
          status: 'Active',
          filterKeys: ['active'],
        ),
      ],
      actionAutomationItems: const [
        NanobotCatalogItem(
          id: 'job-1',
          title: 'Daily job',
          status: 'Paused',
          filterKeys: ['paused'],
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Automations'));
    await tester.pumpAndSettle();

    expect(find.text('Active'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause').last);
    await tester.pumpAndSettle();

    expect(repository.actionRequests, [
      (action: NanobotAutomationAction.disable, id: 'job-1'),
    ]);
    expect(find.text('Paused'), findsWidgets);
  });

  testWidgets('automations delete action asks for confirmation first', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      automationItems: const [
        NanobotCatalogItem(
          id: 'job-1',
          title: 'Daily job',
          status: 'Active',
          filterKeys: ['active'],
        ),
      ],
      actionAutomationItems: const [],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Automations'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Automation actions').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(repository.actionRequests, isEmpty);
    expect(find.text('Delete automation'), findsOneWidget);
    expect(
      find.text(
        'This removes Daily job from automations. '
        'Past chat messages stay in the session.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(repository.actionRequests, [
      (action: NanobotAutomationAction.delete, id: 'job-1'),
    ]);
  });

  testWidgets('automations action buttons mirror webui availability rules', (
    tester,
  ) async {
    Future<_FakeNanobotRepository> pumpAutomations(
      List<NanobotCatalogItem> items,
    ) async {
      final repository = _FakeNanobotRepository(automationItems: items);
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: NanobotWorkspacePage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Automations'));
      await tester.pumpAndSettle();
      return repository;
    }

    final protectedRepository = await pumpAutomations(const [
      NanobotCatalogItem(
        id: 'protected',
        title: 'Protected job',
        status: 'System',
        filterKeys: ['active'],
        isProtected: true,
      ),
    ]);

    expect(find.text('Protected'), findsWidgets);
    expect(find.byTooltip('Edit'), findsNothing);
    expect(find.byTooltip('Pause'), findsNothing);
    expect(find.byTooltip('Automation actions'), findsNothing);
    expect(protectedRepository.actionRequests, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    final localTriggerRepository = await pumpAutomations(const [
      NanobotCatalogItem(
        id: 'local',
        title: 'Local trigger',
        status: 'Active',
        filterKeys: ['active'],
        originLabel: 'Chat',
        originSessionKey: 'websocket:chat-1',
        isLocalTriggerAutomation: true,
      ),
    ]);

    await tester.tap(find.byTooltip('Automation actions').last);
    await tester.pumpAndSettle();

    expect(find.text('Run now'), findsNothing);
    expect(find.text('Delete'), findsOneWidget);
    expect(localTriggerRepository.actionRequests, isEmpty);

    await tester.tapAt(const Offset(1, 1));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    final unlinkedRepository = await pumpAutomations(const [
      NanobotCatalogItem(
        id: 'unlinked',
        title: 'Unlinked job',
        status: 'Active',
        filterKeys: ['active'],
      ),
    ]);

    await tester.tap(find.byTooltip('Automation actions').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run now').last);
    await tester.pumpAndSettle();

    expect(unlinkedRepository.actionRequests, isEmpty);

    await tester.tapAt(const Offset(1, 1));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    final pendingRepository = await pumpAutomations(const [
      NanobotCatalogItem(
        id: 'pending',
        title: 'Pending job',
        status: 'Running now',
        filterKeys: ['active'],
        originLabel: 'Chat',
        originSessionKey: 'websocket:chat-1',
        isPending: true,
      ),
    ]);

    await tester.tap(find.byTooltip('Automation actions').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run now').last);
    await tester.pumpAndSettle();

    expect(pendingRepository.actionRequests, isEmpty);

    await tester.tapAt(const Offset(1, 1));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    final pausedRepository = await pumpAutomations(const [
      NanobotCatalogItem(
        id: 'paused',
        title: 'Paused job',
        status: 'Paused',
        filterKeys: ['paused'],
      ),
    ]);

    await tester.tap(find.byTooltip('Resume').last);
    await tester.pumpAndSettle();

    expect(pausedRepository.actionRequests, isEmpty);
  });

  testWidgets('automations edit dialog updates name message and interval', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      automationItems: const [
        NanobotCatalogItem(
          id: 'job-1',
          title: 'Daily job',
          subtitle: 'Check the repo status',
          status: 'Active',
          filterKeys: ['active'],
          automationScheduleKind: 'every',
          automationEveryMs: 7200000,
        ),
      ],
      actionAutomationItems: const [
        NanobotCatalogItem(
          id: 'job-1',
          title: 'Updated job',
          subtitle: 'Send updated status',
          status: 'Active',
          filterKeys: ['active'],
          automationScheduleKind: 'every',
          automationEveryMs: 10800000,
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Automations'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byTooltip('Edit').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit').last);
    await tester.pumpAndSettle();

    expect(find.text('Edit automation'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('automation-edit-name')),
      'Updated job',
    );
    await tester.enterText(
      find.byKey(const ValueKey('automation-edit-message')),
      'Send updated status',
    );
    await tester.enterText(
      find.byKey(const ValueKey('automation-edit-every-value')),
      '3',
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.updateRequests, hasLength(1));
    expect(repository.updateRequests.single.id, 'job-1');
    expect(repository.updateRequests.single.values, {
      'name': 'Updated job',
      'message': 'Send updated status',
      'schedule': {'kind': 'every', 'every_ms': 10800000},
    });
    expect(find.text('Updated job'), findsWidgets);
  });

  testWidgets('automations edit dialog validates webui required fields', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      automationItems: const [
        NanobotCatalogItem(
          id: 'job-1',
          title: 'Daily job',
          subtitle: 'Check the repo status',
          status: 'Active',
          filterKeys: ['active'],
          automationScheduleKind: 'every',
          automationEveryMs: 7200000,
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Automations'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byTooltip('Edit').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('automation-edit-name')),
      '',
    );
    await tester.pumpAndSettle();

    expect(find.text('Name is required.'), findsOneWidget);
    var save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
    );
    expect(save.onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('automation-edit-name')),
      'Daily job',
    );
    await tester.enterText(
      find.byKey(const ValueKey('automation-edit-message')),
      '',
    );
    await tester.pumpAndSettle();

    expect(find.text('Message is required.'), findsOneWidget);
    save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
    );
    expect(save.onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('automation-edit-message')),
      'Check the repo status',
    );
    await tester.enterText(
      find.byKey(const ValueKey('automation-edit-every-value')),
      '0',
    );
    await tester.pumpAndSettle();

    expect(find.text('Interval must be a positive number.'), findsOneWidget);
    save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
    );
    expect(save.onPressed, isNull);
    expect(repository.updateRequests, isEmpty);
  });

  testWidgets('automations edit dialog sends once schedule run time', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      automationItems: [
        NanobotCatalogItem(
          id: 'job-1',
          title: 'One shot',
          subtitle: 'Send launch note',
          status: 'Active',
          filterKeys: const ['active'],
          automationScheduleKind: 'at',
          automationAtMs: DateTime(2099).millisecondsSinceEpoch,
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Automations'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byTooltip('Edit').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit').last);
    await tester.pumpAndSettle();

    expect(find.text('Run at'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('automation-edit-at-local')),
      '2099-01-02T03:04',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.updateRequests, hasLength(1));
    expect(repository.updateRequests.single.values, {
      'name': 'One shot',
      'message': 'Send launch note',
      'schedule': {
        'kind': 'at',
        'at_ms': DateTime(2099, 1, 2, 3, 4).millisecondsSinceEpoch,
      },
    });
  });

  testWidgets('automations surface shows queue and selected detail panel', (
    tester,
  ) async {
    final repository = _FakeNanobotRepository(
      automationItems: const [
        NanobotCatalogItem(
          id: 'job-1',
          title: 'Daily job',
          subtitle: 'Check the repo status',
          details: 'Release prep',
          status: 'Active',
          filterKeys: ['active'],
          scheduleLabel: 'Every 2 hours',
          originLabel: 'Release prep',
          originSessionKey: 'websocket:chat-1',
          nextRunAtMs: 1000,
          createdAtMs: 500,
          updatedAtMs: 900,
          lastError: 'Timed out',
        ),
        NanobotCatalogItem(
          id: 'job-2',
          title: 'Second job',
          subtitle: 'Send summary',
          details: 'WeChat',
          status: 'Active',
          filterKeys: ['active'],
          scheduleLabel: 'Cron 0 * * * *',
          originLabel: 'WeChat',
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Automations'));
    await tester.pumpAndSettle();

    expect(find.text('Queue'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Daily job'), findsWidgets);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Linked chat'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Created'), findsOneWidget);
    expect(find.text('Updated'), findsOneWidget);
    expect(find.text('Every 2 hours'), findsWidgets);
    expect(find.text('Release prep'), findsWidgets);
    expect(find.text('Timed out'), findsOneWidget);

    await tester.ensureVisible(find.text('Second job').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Second job').first);
    await tester.pumpAndSettle();

    expect(find.text('Cron 0 * * * *'), findsWidgets);
    expect(find.text('Timed out'), findsNothing);
  });

  testWidgets('automations surface mirrors webui status and schedule copy', (
    tester,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final repository = _FakeNanobotRepository(
      automationItems: [
        NanobotCatalogItem(
          id: 'active',
          title: 'Active job',
          subtitle: 'Send summary',
          status: 'Active',
          filterKeys: const ['active'],
          nextRunAtMs: now + const Duration(minutes: 5).inMilliseconds,
          scheduleLabel: 'Daily at 09:00',
          originLabel: 'Roadmap',
        ),
        const NanobotCatalogItem(
          id: 'running',
          title: 'Running job',
          subtitle: 'Check progress',
          status: 'Running now',
          filterKeys: ['active'],
          isPending: true,
          scheduleLabel: 'Hourly at :15',
          originLabel: 'Builds',
        ),
        const NanobotCatalogItem(
          id: 'failed',
          title: 'Failed job',
          subtitle: 'Retry deployment',
          status: 'Failed',
          filterKeys: ['failed'],
          lastError: 'boom',
          scheduleLabel: 'Cron */5 * * * *',
        ),
        const NanobotCatalogItem(
          id: 'idle',
          title: 'Idle job',
          subtitle: 'No future run',
          status: 'No schedule',
          filterKeys: ['active'],
          scheduleLabel: 'Custom schedule',
        ),
        const NanobotCatalogItem(
          id: 'system',
          title: 'System job',
          subtitle: 'heartbeat',
          status: 'System',
          filterKeys: ['system'],
          isProtected: true,
          scheduleLabel: 'Every 2 hours',
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Automations'));
    await tester.pumpAndSettle();

    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Running now'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('No schedule'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Protected'), findsOneWidget);

    expect(find.text('Daily at 09:00'), findsWidgets);
    await tester.ensureVisible(find.text('Running job').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Running job').first);
    await tester.pumpAndSettle();
    expect(find.text('Hourly at :15'), findsWidgets);
    await tester.ensureVisible(find.text('System job').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('System job').first);
    await tester.pumpAndSettle();
    expect(find.text('Every 2 hours'), findsWidgets);
    await tester.ensureVisible(find.text('Idle job').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Idle job').first);
    await tester.pumpAndSettle();
    expect(find.text('No next run'), findsOneWidget);
    expect(find.textContaining('2026-'), findsNothing);
  });

  testWidgets('skills surface opens unavailable skill details', (tester) async {
    final repository = _FakeNanobotRepository(
      skillItems: const [
        NanobotCatalogItem(
          id: 'github',
          title: 'github',
          subtitle: 'Work with GitHub.',
          status: 'Missing: CLI: gh',
        ),
      ],
      skillDetails: const {
        'github': NanobotSkillDetail(
          name: 'github',
          description: 'Work with GitHub.',
          source: 'builtin',
          available: false,
          unavailableReason: 'CLI: gh',
          bins: ['gh'],
          missingBins: ['gh'],
          rawMarkdown: '# GitHub',
        ),
      },
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [nanobotRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NanobotWorkspacePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skills'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('github').last);
    await tester.pumpAndSettle();

    expect(repository.requestedSkillDetails, ['github']);
    expect(find.text('Unavailable reason'), findsOneWidget);
    expect(find.text('CLI: gh'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Work with GitHub.'), findsWidgets);
    expect(find.text('Requirements'), findsOneWidget);
    expect(find.text('Missing CLI'), findsOneWidget);
    expect(find.text('Raw SKILL.md'), findsOneWidget);
    await tester.tap(find.text('Raw SKILL.md'));
    await tester.pumpAndSettle();
    expect(find.text('# GitHub'), findsOneWidget);
  });
}

bool _isAbove(WidgetTester tester, String upperText, String lowerText) {
  final upperTop = tester.getTopLeft(find.text(upperText).first).dy;
  final lowerTop = tester.getTopLeft(find.text(lowerText).first).dy;
  return upperTop < lowerTop;
}

class _FakeNanobotRepository implements NanobotRepositoryPort {
  _FakeNanobotRepository({
    List<NanobotCatalogItem>? appItems,
    List<NanobotCatalogItem>? automationItems,
    List<NanobotCatalogItem>? actionAutomationItems,
    List<NanobotCatalogItem>? actionAppItems,
    this.actionMessage,
    this.actionRequiresRestart = false,
    List<NanobotCatalogItem>? skillItems,
    Map<String, NanobotSkillDetail>? skillDetails,
    this.settingsSnapshot,
    this.providerModelCatalogs = const {},
  }) : _appItems = appItems ?? _defaultAppItems,
       _automationItems = automationItems ?? _defaultAutomationItems,
       _actionAutomationItems = actionAutomationItems ?? automationItems,
       _actionAppItems = actionAppItems ?? appItems,
       _skillItems = skillItems ?? _defaultSkillItems,
       _skillDetails = skillDetails ?? const {};

  final _events = StreamController<NanobotEvent>.broadcast();
  final _status = StreamController<NanobotSocketStatus>.broadcast();
  final List<NanobotCatalogItem> _appItems;
  final List<NanobotCatalogItem> _automationItems;
  final List<NanobotCatalogItem>? _actionAutomationItems;
  final List<NanobotCatalogItem>? _actionAppItems;
  final String? actionMessage;
  final bool actionRequiresRestart;
  final List<NanobotCatalogItem> _skillItems;
  final Map<String, NanobotSkillDetail> _skillDetails;
  final NanobotSettingsSnapshot? settingsSnapshot;
  final Map<String, List<String>> providerModelCatalogs;
  final requestedSkillDetails = <String>[];
  final providerModelRequests = <String>[];
  final actionRequests = <({NanobotAutomationAction action, String id})>[];
  final cliActionRequests = <({String action, String name})>[];
  final nanobotFeatureActionRequests = <({String action, String name})>[];
  final mcpPresetActionRequests =
      <({String action, String name, Map<String, Object?> values})>[];
  final mcpToolsUpdateRequests = <({String name, List<String> enabledTools})>[];
  final customMcpRequests = <Map<String, Object?>>[];
  final mcpConfigImports = <String>[];
  final webSearchSaveRequests =
      <
        ({
          String provider,
          int maxResults,
          int timeoutSeconds,
          bool useJinaReader,
        })
      >[];
  final imageGenerationSaveRequests =
      <
        ({
          bool enabled,
          String provider,
          String model,
          String defaultAspectRatio,
          String defaultImageSize,
          int maxImagesPerTurn,
        })
      >[];
  final transcriptionSaveRequests =
      <
        ({
          bool enabled,
          String provider,
          String model,
          String language,
          int maxDurationSec,
          int maxUploadMb,
        })
      >[];
  final networkSafetySaveRequests =
      <({bool webuiAllowLocalServiceAccess, String webuiDefaultAccessMode})>[];
  final runtimeSaveRequests =
      <({String timezone, String botName, String botIcon})>[];
  final modelSaveRequests =
      <
        ({
          String modelPreset,
          String? model,
          String? provider,
          int? contextWindowTokens,
        })
      >[];
  final modelConfigurationCreateRequests =
      <({String label, String provider, String model})>[];
  final modelConfigurationUpdateRequests =
      <
        ({
          String name,
          String label,
          String provider,
          String model,
          int? contextWindowTokens,
        })
      >[];
  final updateRequests = <({String id, Map<String, Object?> values})>[];
  final _sessions = [
    NanobotSessionSummary(
      key: 'websocket:chat-1',
      channel: 'websocket',
      chatId: 'chat-1',
      preview: '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
  ];

  @override
  Stream<NanobotEvent> get events => _events.stream;

  @override
  Stream<NanobotSocketStatus> get status => _status.stream;

  @override
  NanobotSocketStatus get currentStatus => NanobotSocketStatus.open;

  @override
  Future<NanobotBootstrap> bootstrap({bool forceRefresh = false}) async {
    return NanobotBootstrap(
      token: 'token',
      wsPath: '/',
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      modelName: 'MiniMax-M3',
    );
  }

  @override
  Future<void> connect() async {}

  @override
  Future<List<NanobotSessionSummary>> listSessions() async => _sessions;

  @override
  Future<List<NanobotSlashCommand>> listSlashCommands() async {
    return const [];
  }

  @override
  Future<NanobotSidebarState> fetchSidebarState() async {
    return const NanobotSidebarState();
  }

  @override
  Future<NanobotSidebarState> updateSidebarState(
    NanobotSidebarState state,
  ) async {
    return state;
  }

  @override
  Future<NanobotSessionDeleteResult> deleteSession({
    required String sessionKey,
    bool deleteAutomations = false,
  }) async {
    return const NanobotSessionDeleteResult(deleted: true);
  }

  @override
  Future<NanobotWorkspaceSnapshot> fetchWorkspacesSnapshot() async {
    return const NanobotWorkspaceSnapshot(
      defaultScope: NanobotWorkspaceScope(
        projectPath: '/tmp/project',
        accessMode: 'restricted',
      ),
    );
  }

  @override
  Future<void> setWorkspaceScope({
    required String chatId,
    required NanobotWorkspaceScope workspaceScope,
  }) async {}

  @override
  Future<List<NanobotMessage>> fetchThread(
    NanobotSessionSummary session,
  ) async {
    return const [];
  }

  @override
  Future<NanobotThreadPage> fetchThreadPage(
    NanobotSessionSummary session, {
    int limit = 120,
    String? before,
  }) async {
    return NanobotThreadPage(messages: await fetchThread(session));
  }

  @override
  Future<NanobotFilePreview> fetchFilePreview({
    required String sessionKey,
    required String path,
  }) async {
    return NanobotFilePreview(
      path: path,
      displayPath: path,
      projectPath: '',
      language: '',
      content: '',
      size: 0,
      truncated: false,
    );
  }

  @override
  Future<String> newChat({NanobotWorkspaceScope? workspaceScope}) async =>
      'chat-1';

  @override
  Future<void> attach(String chatId) async {}

  @override
  Future<void> sendMessage({
    required String chatId,
    required String content,
    List<NanobotSendMedia> media = const [],
    List<NanobotCapabilityMention> cliApps = const [],
    List<NanobotCapabilityMention> mcpPresets = const [],
  }) async {}

  @override
  Future<String> forkChat({
    required String sourceChatId,
    required int beforeUserIndex,
    String? title,
  }) async {
    return 'chat-fork';
  }

  @override
  Future<String> transcribeAudio({
    required String requestId,
    required String dataUrl,
    int? durationMs,
  }) async {
    return '';
  }

  @override
  Future<NanobotSettingsSnapshot> fetchSettingsSnapshot() async {
    return settingsSnapshot ??
        const NanobotSettingsSnapshot(
          model: 'MiniMax-M3',
          provider: 'openai',
          contextWindowTokens: 262144,
          timezone: 'UTC',
          botName: 'Nanobot',
          botIcon: 'N',
          webSearchEnabled: true,
          webSearchProvider: 'searxng',
          webSearchMaxResults: 5,
          webSearchTimeoutSeconds: 10,
          webFetchUseJinaReader: false,
          imageGenerationEnabled: true,
          imageGenerationProvider: 'openrouter',
          imageGenerationModel: 'image-model',
          imageGenerationDefaultAspectRatio: '1:1',
          imageGenerationDefaultImageSize: '1024x1024',
          imageGenerationMaxImagesPerTurn: 2,
          imageGenerationSaveDir: '/tmp/nanobot/images',
          transcriptionEnabled: false,
          transcriptionProvider: 'openai',
          transcriptionModel: 'whisper',
          transcriptionLanguage: 'zh',
          transcriptionMaxDurationSec: 60,
          transcriptionMaxUploadMb: 20,
          isNativeHostSurface: true,
          webuiAllowLocalServiceAccess: true,
          webuiDefaultAccessMode: 'default',
          runtimeHost: '127.0.0.1',
          runtimeGatewayPort: 8765,
          workspaceCaption: 'Project workspace',
          usageDays: [
            NanobotUsageDay(
              date: '2026-07-08',
              totalTokens: 750,
              estimatedTokens: 50,
              requests: 4,
              sources: {'user': 600, 'cron': 150},
            ),
          ],
          totalTokens30d: 900,
          totalTokens365d: 1000,
          peakDayTokens: 750,
          currentStreakDays: 2,
          longestStreakDays: 4,
          totalTokens: 42,
          requests30d: 2,
          activeDays30d: 1,
          requiresRestart: false,
          version: '1.2.3',
        );
  }

  @override
  Future<NanobotProviderModelCatalog> fetchProviderModels(
    String provider,
  ) async {
    providerModelRequests.add(provider);
    final models = providerModelCatalogs[provider] ?? const [];
    return NanobotProviderModelCatalog(
      provider: provider,
      label: provider,
      status: 'available',
      catalogKind: 'official',
      models: [
        for (final id in models)
          NanobotProviderModel(id: id, ownedBy: provider, contextWindow: 65536),
      ],
      modelCount: models.length,
    );
  }

  @override
  Future<NanobotVersionCheckResult> checkVersion() async {
    return const NanobotVersionCheckResult.updateAvailable(
      currentVersion: '1.2.3',
      latestVersion: '1.3.0',
      pypiUrl: 'https://pypi.org/project/nanobot',
    );
  }

  @override
  Future<NanobotSettingsSnapshot> saveWebSearchSettings({
    required String provider,
    required int maxResults,
    required int timeoutSeconds,
    required bool useJinaReader,
  }) async {
    webSearchSaveRequests.add((
      provider: provider,
      maxResults: maxResults,
      timeoutSeconds: timeoutSeconds,
      useJinaReader: useJinaReader,
    ));
    return NanobotSettingsSnapshot(
      model: 'MiniMax-M3',
      provider: 'openai',
      webSearchEnabled: true,
      webSearchProvider: provider,
      webSearchMaxResults: maxResults,
      webSearchTimeoutSeconds: timeoutSeconds,
      webFetchUseJinaReader: useJinaReader,
      imageGenerationEnabled: true,
      imageGenerationProvider: 'openrouter',
      imageGenerationModel: 'image-model',
      imageGenerationDefaultAspectRatio: '1:1',
      imageGenerationDefaultImageSize: '1024x1024',
      imageGenerationMaxImagesPerTurn: 2,
      imageGenerationSaveDir: '/tmp/nanobot/images',
      transcriptionEnabled: false,
      transcriptionProvider: 'openai',
      transcriptionModel: 'whisper',
      transcriptionLanguage: 'zh',
      transcriptionMaxDurationSec: 60,
      transcriptionMaxUploadMb: 20,
      requiresRestart: true,
    );
  }

  @override
  Future<NanobotSettingsSnapshot> saveImageGenerationSettings({
    required bool enabled,
    required String provider,
    required String model,
    required String defaultAspectRatio,
    required String defaultImageSize,
    required int maxImagesPerTurn,
  }) async {
    imageGenerationSaveRequests.add((
      enabled: enabled,
      provider: provider,
      model: model,
      defaultAspectRatio: defaultAspectRatio,
      defaultImageSize: defaultImageSize,
      maxImagesPerTurn: maxImagesPerTurn,
    ));
    return NanobotSettingsSnapshot(
      model: 'MiniMax-M3',
      provider: 'openai',
      imageGenerationEnabled: enabled,
      imageGenerationProvider: provider,
      imageGenerationModel: model,
      imageGenerationDefaultAspectRatio: defaultAspectRatio,
      imageGenerationDefaultImageSize: defaultImageSize,
      imageGenerationMaxImagesPerTurn: maxImagesPerTurn,
      imageGenerationSaveDir: '/tmp/nanobot/images',
      requiresRestart: true,
    );
  }

  @override
  Future<NanobotSettingsSnapshot> saveTranscriptionSettings({
    required bool enabled,
    required String provider,
    required String model,
    required String language,
    required int maxDurationSec,
    required int maxUploadMb,
  }) async {
    transcriptionSaveRequests.add((
      enabled: enabled,
      provider: provider,
      model: model,
      language: language,
      maxDurationSec: maxDurationSec,
      maxUploadMb: maxUploadMb,
    ));
    return NanobotSettingsSnapshot(
      model: 'MiniMax-M3',
      provider: 'openai',
      transcriptionEnabled: enabled,
      transcriptionProvider: provider,
      transcriptionModel: model,
      transcriptionLanguage: language,
      transcriptionMaxDurationSec: maxDurationSec,
      transcriptionMaxUploadMb: maxUploadMb,
      requiresRestart: true,
    );
  }

  @override
  Future<NanobotSettingsSnapshot> saveNetworkSafetySettings({
    required bool webuiAllowLocalServiceAccess,
    required String webuiDefaultAccessMode,
  }) async {
    networkSafetySaveRequests.add((
      webuiAllowLocalServiceAccess: webuiAllowLocalServiceAccess,
      webuiDefaultAccessMode: webuiDefaultAccessMode,
    ));
    return NanobotSettingsSnapshot(
      model: 'MiniMax-M3',
      provider: 'openai',
      isNativeHostSurface: true,
      webuiAllowLocalServiceAccess: webuiAllowLocalServiceAccess,
      webuiDefaultAccessMode: webuiDefaultAccessMode,
      requiresRestart: true,
    );
  }

  @override
  Future<NanobotSettingsSnapshot> saveRuntimeSettings({
    required String timezone,
    required String botName,
    required String botIcon,
  }) async {
    runtimeSaveRequests.add((
      timezone: timezone,
      botName: botName,
      botIcon: botIcon,
    ));
    return NanobotSettingsSnapshot(
      model: 'MiniMax-M3',
      provider: 'openai',
      timezone: timezone,
      botName: botName,
      botIcon: botIcon,
      requiresRestart: true,
    );
  }

  @override
  Future<NanobotSettingsSnapshot> saveModelSettings({
    required String modelPreset,
    String? model,
    String? provider,
    int? contextWindowTokens,
  }) async {
    modelSaveRequests.add((
      modelPreset: modelPreset,
      model: model,
      provider: provider,
      contextWindowTokens: contextWindowTokens,
    ));
    final current = settingsSnapshot;
    return NanobotSettingsSnapshot(
      modelPreset: modelPreset,
      model: model ?? current?.model,
      provider: provider ?? current?.provider,
      contextWindowTokens: contextWindowTokens ?? current?.contextWindowTokens,
      requiresRestart: true,
    );
  }

  @override
  Future<NanobotSettingsSnapshot> createModelConfiguration({
    required String label,
    required String provider,
    required String model,
  }) async {
    modelConfigurationCreateRequests.add((
      label: label,
      provider: provider,
      model: model,
    ));
    final current = settingsSnapshot;
    return NanobotSettingsSnapshot(
      modelPreset: label.toLowerCase().replaceAll(' ', '-'),
      model: model,
      provider: provider,
      contextWindowTokens: current?.contextWindowTokens,
      requiresRestart: true,
      providers: current?.providers ?? const [],
    );
  }

  @override
  Future<NanobotSettingsSnapshot> updateModelConfiguration({
    required String name,
    required String label,
    required String provider,
    required String model,
    int? contextWindowTokens,
  }) async {
    modelConfigurationUpdateRequests.add((
      name: name,
      label: label,
      provider: provider,
      model: model,
      contextWindowTokens: contextWindowTokens,
    ));
    final current = settingsSnapshot;
    return NanobotSettingsSnapshot(
      modelPreset: name,
      model: model,
      provider: provider,
      contextWindowTokens: contextWindowTokens ?? current?.contextWindowTokens,
      requiresRestart: true,
      modelPresets: current?.modelPresets ?? const [],
      providers: current?.providers ?? const [],
    );
  }

  @override
  Future<List<NanobotCatalogItem>> fetchAppItems() async {
    return _appItems;
  }

  @override
  Future<NanobotAppsActionResult> runCliAppAction({
    required String action,
    required String name,
  }) async {
    cliActionRequests.add((action: action, name: name));
    return _appActionResult();
  }

  @override
  Future<NanobotAppsActionResult> runNanobotFeatureAction({
    required String action,
    required String name,
  }) async {
    nanobotFeatureActionRequests.add((action: action, name: name));
    return _appActionResult();
  }

  @override
  Future<NanobotAppsActionResult> runMcpPresetAction({
    required String action,
    required String name,
    Map<String, Object?> values = const {},
  }) async {
    mcpPresetActionRequests.add((action: action, name: name, values: values));
    return _appActionResult();
  }

  @override
  Future<NanobotAppsActionResult> updateMcpServerTools({
    required String name,
    required List<String> enabledTools,
  }) async {
    mcpToolsUpdateRequests.add((name: name, enabledTools: enabledTools));
    return _appActionResult();
  }

  @override
  Future<NanobotAppsActionResult> saveCustomMcpServer({
    required Map<String, Object?> values,
  }) async {
    customMcpRequests.add(values);
    return _appActionResult();
  }

  @override
  Future<NanobotAppsActionResult> importMcpConfig(String config) async {
    mcpConfigImports.add(config);
    return _appActionResult();
  }

  NanobotAppsActionResult _appActionResult() {
    return NanobotAppsActionResult(
      items: _actionAppItems ?? _appItems,
      message: actionMessage,
      requiresRestart: actionRequiresRestart,
    );
  }

  @override
  Future<List<NanobotCatalogItem>> fetchAutomationItems() async {
    return _automationItems;
  }

  @override
  Future<List<NanobotCatalogItem>> runAutomationAction({
    required NanobotAutomationAction action,
    required String id,
  }) async {
    actionRequests.add((action: action, id: id));
    return _actionAutomationItems ?? _automationItems;
  }

  @override
  Future<List<NanobotCatalogItem>> updateAutomation({
    required String id,
    required Map<String, Object?> values,
  }) async {
    updateRequests.add((id: id, values: values));
    return _actionAutomationItems ?? _automationItems;
  }

  @override
  Future<List<NanobotCatalogItem>> fetchSkillItems() async {
    return _skillItems;
  }

  @override
  Future<NanobotSkillDetail> fetchSkillDetail(String name) async {
    requestedSkillDetails.add(name);
    final detail = _skillDetails[name];
    if (detail == null) {
      throw StateError('Missing skill detail: $name');
    }
    return detail;
  }

  @override
  Future<List<NanobotCapabilityMention>> fetchCapabilityMentions() async {
    return const [];
  }

  @override
  Future<void> dispose() async {
    await _events.close();
    await _status.close();
  }

  static const _defaultAppItems = [
    NanobotCatalogItem(
      id: 'gimp',
      title: 'GIMP',
      subtitle: 'Image editor',
      status: 'installed',
    ),
  ];

  static const _defaultAutomationItems = [
    NanobotCatalogItem(
      id: 'job-1',
      title: 'Daily ping',
      subtitle: 'cron',
      status: 'Active',
    ),
  ];

  static const _defaultSkillItems = [
    NanobotCatalogItem(
      id: 'browser',
      title: 'browser',
      subtitle: 'Browse',
      status: 'available',
    ),
  ];
}
