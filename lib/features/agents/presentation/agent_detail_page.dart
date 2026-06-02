import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:agent_client/features/agents/application/agent_controller.dart';
import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:agent_client/features/agents/domain/agent_avatar.dart';
import 'package:agent_client/features/agents/presentation/agent_avatar_editor_dialog.dart';
import 'package:agent_client/features/agents/presentation/agent_avatar_view.dart';
import 'package:agent_client/features/files/presentation/files_panel.dart';
import 'package:agent_client/features/settings/data/agent_settings_repository.dart';
import 'package:agent_client/features/settings/domain/agent_settings.dart';
import 'package:agent_client/features/tasks/presentation/tasks_panel.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AgentDetailPage extends ConsumerWidget {
  const AgentDetailPage({super.key, required this.agent});

  final Agent agent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAgent = _agentFrom(ref.watch(agentsProvider), agent);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        key: const Key('agent-detail-page'),
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              AgentAvatarView(
                agent: currentAgent,
                selected: true,
                radius: 18,
                showStatus: false,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  currentAgent.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            key: Key('agent-detail-tab-bar'),
            isScrollable: true,
            tabs: [
              Tab(
                key: Key('agent-detail-overview-tab-button'),
                icon: Icon(Icons.badge_outlined),
                text: 'Overview',
              ),
              Tab(
                key: Key('agent-detail-model-tab-button'),
                icon: Icon(Icons.tune_outlined),
                text: 'Model',
              ),
              Tab(
                key: Key('agent-detail-files-tab-button'),
                icon: Icon(Icons.folder_outlined),
                text: 'Files',
              ),
              Tab(
                key: Key('agent-detail-tasks-tab-button'),
                icon: Icon(Icons.fact_check_outlined),
                text: 'Tasks',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AgentOverviewTab(agent: currentAgent),
            _AgentModelTab(agent: currentAgent),
            FilesPanel(agentId: currentAgent.id),
            TasksPanel(agentId: currentAgent.id),
          ],
        ),
      ),
    );
  }
}

void openAgentDetailPage(BuildContext context, Agent agent) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AgentDetailPage(agent: agent),
      settings: RouteSettings(name: 'agent-detail-${agent.id}'),
    ),
  );
}

Agent _agentFrom(AsyncValue<List<Agent>> agents, Agent fallback) {
  return switch (agents) {
    AsyncData(:final value) => value.firstWhere(
      (agent) => agent.id == fallback.id,
      orElse: () => fallback,
    ),
    _ => fallback,
  };
}

class _AgentOverviewTab extends ConsumerStatefulWidget {
  const _AgentOverviewTab({required this.agent});

  final Agent agent;

  @override
  ConsumerState<_AgentOverviewTab> createState() => _AgentOverviewTabState();
}

class _AgentOverviewTabState extends ConsumerState<_AgentOverviewTab> {
  late AgentAvatarOption _selectedAvatar;
  String? _errorText;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedAvatar = _avatarFor(widget.agent.avatarUrl);
  }

  @override
  void didUpdateWidget(covariant _AgentOverviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agent.avatarUrl != widget.agent.avatarUrl && !_saving) {
      _selectedAvatar = _avatarFor(widget.agent.avatarUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatarChange = _selectedAvatar.assetPath != widget.agent.avatarUrl;

    return ColoredBox(
      color: AppThemeTokens.workspace,
      child: ListView(
        key: const Key('agent-detail-overview-tab'),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
        children: [
          _SettingsPanel(
            title: 'Identity',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AgentAvatarView(
                      agent: widget.agent,
                      selected: true,
                      radius: 34,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.agent.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppThemeTokens.text,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _statusLabel(widget.agent.status),
                            style: const TextStyle(
                              color: AppThemeTokens.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AgentAvatarPicker(
                  selectedAvatar: _selectedAvatar,
                  enabled: !_saving,
                  onSelected: (avatar) {
                    setState(() => _selectedAvatar = avatar);
                  },
                ),
                if (_errorText case final error?) ...[
                  const SizedBox(height: 12),
                  Text(
                    error,
                    style: const TextStyle(color: AppThemeTokens.dangerText),
                  ),
                ],
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    key: const Key('agent-detail-avatar-save-button'),
                    onPressed: !_saving && hasAvatarChange ? _saveAvatar : null,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save avatar'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsPanel(
            title: 'Details',
            child: Column(
              children: [
                _DetailRow(
                  label: 'Description',
                  value: widget.agent.description,
                ),
                _DetailRow(label: 'Provider', value: widget.agent.provider),
                _DetailRow(label: 'Model', value: widget.agent.model),
                _DetailRow(label: 'Workspace', value: widget.agent.workspace),
                _DetailRow(label: 'Backend', value: widget.agent.backendId),
                _DetailRow(
                  label: 'Backend agent',
                  value: widget.agent.backendAgentId,
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAvatar() async {
    setState(() {
      _saving = true;
      _errorText = null;
    });

    try {
      await ref
          .read(currentAgentIdProvider.notifier)
          .updateAgentAvatar(
            widget.agent,
            avatarUrl: _selectedAvatar.assetPath,
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Avatar saved')));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorText = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _AgentModelTab extends ConsumerStatefulWidget {
  const _AgentModelTab({required this.agent});

  final Agent agent;

  @override
  ConsumerState<_AgentModelTab> createState() => _AgentModelTabState();
}

class _AgentModelTabState extends ConsumerState<_AgentModelTab> {
  String? _provider;
  String? _model;
  String? _errorText;
  var _saving = false;

  @override
  Widget build(BuildContext context) {
    final settingsAgentName = widget.agent.backendAgentId;
    final settings = ref.watch(agentSettingsProvider(settingsAgentName));

    return ColoredBox(
      color: AppThemeTokens.workspace,
      child: settings.when(
        data: (settings) => ListView(
          key: const Key('agent-detail-model-tab'),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
          children: [
            _SettingsPanel(
              title: 'Runtime model',
              child: _buildSettingsForm(settingsAgentName, settings),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Unable to load settings: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsForm(
    String settingsAgentName,
    AgentSettingsSnapshot settings,
  ) {
    final selectedProviderName = _selectedProviderName(settings);
    final selectedProvider = _providerFor(settings, selectedProviderName);
    final selectedModelName = _selectedModelName(settings, selectedProvider);
    final modelOptions = selectedProvider?.models ?? const <String>[];
    final canSave = !_saving && selectedProviderName != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (settings.providers.isEmpty)
          _ReadOnlyValue(
            label: 'Provider',
            value: settings.provider ?? settings.resolvedProvider,
          )
        else
          DropdownButtonFormField<String>(
            key: const Key('agent-detail-provider-field'),
            initialValue: selectedProviderName,
            decoration: const InputDecoration(
              labelText: 'Provider',
              prefixIcon: Icon(Icons.hub_outlined),
            ),
            items: [
              for (final provider in settings.providers)
                DropdownMenuItem<String>(
                  value: provider.name,
                  child: Text(_providerLabel(provider)),
                ),
            ],
            onChanged: _saving
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }
                    final provider = _providerFor(settings, value);
                    setState(() {
                      _provider = value;
                      _model = _firstOrNull(provider?.models);
                      _errorText = null;
                    });
                  },
          ),
        const SizedBox(height: 14),
        if (modelOptions.isEmpty)
          _ReadOnlyValue(label: 'Model', value: selectedModelName)
        else
          KeyedSubtree(
            key: Key('agent-detail-model-field-scope-$selectedProviderName'),
            child: DropdownButtonFormField<String>(
              key: const Key('agent-detail-model-field'),
              initialValue: selectedModelName,
              decoration: const InputDecoration(
                labelText: 'Model',
                prefixIcon: Icon(Icons.memory_outlined),
              ),
              items: [
                for (final model in modelOptions)
                  DropdownMenuItem<String>(value: model, child: Text(model)),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      setState(() {
                        _model = value;
                        _errorText = null;
                      });
                    },
            ),
          ),
        const SizedBox(height: 14),
        _ProviderStatus(provider: selectedProvider, settings: settings),
        if (settings.requiresRestart) ...[
          const SizedBox(height: 12),
          const Text(
            'Restart required',
            style: TextStyle(color: AppThemeTokens.dangerText),
          ),
        ],
        if (_errorText case final error?) ...[
          const SizedBox(height: 12),
          Text(error, style: const TextStyle(color: AppThemeTokens.dangerText)),
        ],
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            key: const Key('agent-detail-model-save-button'),
            onPressed: canSave
                ? () => _saveSettings(
                    settingsAgentName: settingsAgentName,
                    provider: selectedProviderName,
                    model: selectedModelName,
                  )
                : null,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save'),
          ),
        ),
      ],
    );
  }

  String? _selectedProviderName(AgentSettingsSnapshot settings) {
    final candidate =
        _provider ?? settings.provider ?? settings.resolvedProvider;
    if (candidate != null &&
        settings.providers.any((provider) => provider.name == candidate)) {
      return candidate;
    }
    if (settings.providers.isNotEmpty) {
      return settings.providers.first.name;
    }
    return candidate;
  }

  AgentProviderSettingsItem? _providerFor(
    AgentSettingsSnapshot settings,
    String? providerName,
  ) {
    if (providerName == null) {
      return null;
    }
    for (final provider in settings.providers) {
      if (provider.name == providerName) {
        return provider;
      }
    }
    return null;
  }

  String? _selectedModelName(
    AgentSettingsSnapshot settings,
    AgentProviderSettingsItem? provider,
  ) {
    final models = provider?.models ?? const <String>[];
    final candidate = _model ?? settings.model;
    if (candidate != null && (models.isEmpty || models.contains(candidate))) {
      return candidate;
    }
    return _firstOrNull(models);
  }

  Future<void> _saveSettings({
    required String settingsAgentName,
    required String provider,
    required String? model,
  }) async {
    setState(() {
      _saving = true;
      _errorText = null;
    });

    try {
      final updated = await ref
          .read(agentSettingsRepositoryProvider)
          .update(
            agentName: settingsAgentName,
            provider: provider,
            model: model,
          );
      _provider = updated.provider ?? provider;
      _model = updated.model ?? model;
      ref.invalidate(agentSettingsProvider(settingsAgentName));
      ref.invalidate(agentsProvider);
      ref.invalidate(currentAgentProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Agent settings saved')));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorText = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String? value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 132,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppThemeTokens.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _displayValue(value),
                  style: const TextStyle(color: AppThemeTokens.text),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: AppThemeTokens.border),
      ],
    );
  }
}

class _ReadOnlyValue extends StatelessWidget {
  const _ReadOnlyValue({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
      ),
      child: Text(
        _displayValue(value),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ProviderStatus extends StatelessWidget {
  const _ProviderStatus({required this.provider, required this.settings});

  final AgentProviderSettingsItem? provider;
  final AgentSettingsSnapshot settings;

  @override
  Widget build(BuildContext context) {
    final selectedProvider = provider;
    final status = selectedProvider == null
        ? 'No provider selected'
        : selectedProvider.configured
        ? 'Configured'
        : 'Not configured';
    final apiBase =
        selectedProvider?.apiBase ?? selectedProvider?.defaultApiBase;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppThemeTokens.workspace,
        border: Border.all(color: AppThemeTokens.border),
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              status,
              style: TextStyle(
                color: selectedProvider?.configured == false
                    ? AppThemeTokens.dangerText
                    : AppThemeTokens.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'API key: ${settings.hasApiKey ? 'available' : 'missing'}',
              style: const TextStyle(color: AppThemeTokens.mutedText),
            ),
            if (apiBase?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                apiBase!.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppThemeTokens.mutedText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _displayValue(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return 'Not set';
  }
  return trimmed;
}

String _providerLabel(AgentProviderSettingsItem provider) {
  final label = provider.label.trim();
  if (label.isEmpty || label == provider.name) {
    return provider.name;
  }
  return '$label (${provider.name})';
}

String _statusLabel(AgentStatus status) {
  return switch (status) {
    AgentStatus.online => 'Online',
    AgentStatus.busy => 'Busy',
    AgentStatus.offline => 'Offline',
  };
}

AgentAvatarOption _avatarFor(String? avatarUrl) {
  for (final avatar in AgentAvatarOptions.defaults) {
    if (avatar.assetPath == avatarUrl) {
      return avatar;
    }
  }
  return AgentAvatarOptions.defaults.first;
}

String? _firstOrNull(List<String>? values) {
  if (values == null || values.isEmpty) {
    return null;
  }
  return values.first;
}
