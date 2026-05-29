import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:agent_client/core/config/app_config.dart';
import 'package:agent_client/features/agents/application/agent_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AppSettingsPage extends HookConsumerWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final baseUrlController = useTextEditingController(text: config.apiBaseUrl);
    final apiKeyController = useTextEditingController(text: config.apiKey);
    final saving = useState(false);
    final errorText = useState<String?>(null);
    final obscureApiKey = useState(true);

    useEffect(() {
      baseUrlController.text = config.apiBaseUrl;
      apiKeyController.text = config.apiKey;
      return null;
    }, [config.apiBaseUrl, config.apiKey]);

    Future<void> save({bool defaults = false}) async {
      final apiBaseUrl = defaults
          ? AppConfig.defaultApiBaseUrl
          : baseUrlController.text;
      final apiKey = defaults ? AppConfig.defaultApiKey : apiKeyController.text;
      final validationError = _validate(apiBaseUrl: apiBaseUrl, apiKey: apiKey);
      if (validationError != null) {
        errorText.value = validationError;
        return;
      }

      saving.value = true;
      errorText.value = null;
      try {
        await ref
            .read(appConfigControllerProvider.notifier)
            .save(apiBaseUrl: apiBaseUrl, apiKey: apiKey);
        ref.invalidate(agentsProvider);
        ref.invalidate(currentAgentProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Settings saved')));
        }
      } catch (error) {
        errorText.value = error.toString();
      } finally {
        saving.value = false;
      }
    }

    return Scaffold(
      key: const Key('app-settings-page'),
      appBar: AppBar(title: const Text('Settings')),
      body: ColoredBox(
        color: AppThemeTokens.workspace,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppThemeTokens.panel,
                    border: Border.all(color: AppThemeTokens.border),
                    borderRadius: BorderRadius.circular(AppThemeTokens.radius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Backend',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          key: const Key('app-settings-base-url-field'),
                          controller: baseUrlController,
                          enabled: !saving.value,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Server URL',
                            prefixIcon: Icon(Icons.dns_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          key: const Key('app-settings-api-key-field'),
                          controller: apiKeyController,
                          enabled: !saving.value,
                          obscureText: obscureApiKey.value,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'API key',
                            prefixIcon: const Icon(Icons.key_outlined),
                            suffixIcon: IconButton(
                              tooltip: obscureApiKey.value
                                  ? 'Show API key'
                                  : 'Hide API key',
                              icon: Icon(
                                obscureApiKey.value
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () =>
                                  obscureApiKey.value = !obscureApiKey.value,
                            ),
                          ),
                          onSubmitted: (_) => save(),
                        ),
                        if (errorText.value != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            errorText.value!,
                            style: const TextStyle(
                              color: AppThemeTokens.dangerText,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          alignment: WrapAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              key: const Key(
                                'app-settings-reset-defaults-button',
                              ),
                              onPressed: saving.value
                                  ? null
                                  : () => save(defaults: true),
                              icon: const Icon(Icons.restart_alt, size: 18),
                              label: const Text('Defaults'),
                            ),
                            FilledButton.icon(
                              key: const Key('app-settings-save-button'),
                              onPressed: saving.value ? null : save,
                              icon: saving.value
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined, size: 18),
                              label: const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void openAppSettingsPage(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const AppSettingsPage(),
      settings: const RouteSettings(name: 'app-settings'),
    ),
  );
}

String? _validate({required String apiBaseUrl, required String apiKey}) {
  final normalizedBaseUrl = AppConfig.normalizeBaseUrl(apiBaseUrl);
  if (normalizedBaseUrl.isEmpty) {
    return 'Server URL is required';
  }

  final uri = Uri.tryParse(normalizedBaseUrl);
  if (uri == null ||
      uri.host.isEmpty ||
      (uri.scheme != 'http' && uri.scheme != 'https')) {
    return 'Server URL must start with http:// or https://';
  }

  if (apiKey.trim().isEmpty) {
    return 'API key is required';
  }

  return null;
}
