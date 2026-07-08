import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:agent_client/features/nanobot/application/nanobot_workspace_controller.dart';
import 'package:agent_client/features/nanobot/application/nanobot_workspace_state.dart';
import 'package:agent_client/features/nanobot/data/nanobot_ws_client.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_message.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_shell_models.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_thread_state.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NanobotWorkspacePage extends ConsumerStatefulWidget {
  const NanobotWorkspacePage({super.key});

  @override
  ConsumerState<NanobotWorkspacePage> createState() =>
      _NanobotWorkspacePageState();
}

class _NanobotWorkspacePageState extends ConsumerState<NanobotWorkspacePage> {
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nanobotWorkspaceControllerProvider);
    final controller = ref.read(nanobotWorkspaceControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppThemeTokens.workspace,
      drawer: MediaQuery.sizeOf(context).width < 760
          ? Drawer(
              child: SafeArea(
                child: _SessionList(
                  state: state,
                  onNewChat: controller.startNewSession,
                  onRefresh: controller.refreshSessions,
                  onSelected: (session) {
                    Navigator.of(context).pop();
                    controller.selectSession(session);
                  },
                  onOpenChat: controller.openChat,
                  onOpenSettings: controller.openSettings,
                  onOpenApps: controller.openApps,
                  onOpenAutomations: controller.openAutomations,
                  onOpenSkills: controller.openSkills,
                  onToggleShowArchived: controller.toggleShowArchived,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final chat = _ChatPane(
              state: state,
              inputController: _inputController,
              focusNode: _focusNode,
              onSend: () => _send(controller),
              onStop: controller.stopActiveTurn,
              onOpenSessions: wide
                  ? null
                  : () => Scaffold.of(context).openDrawer(),
              onOpenSettings: controller.openSettings,
              onRefresh: controller.initialize,
            );
            if (!wide) {
              return chat;
            }
            return Row(
              children: [
                SizedBox(
                  width: 320,
                  child: _SessionList(
                    state: state,
                    onNewChat: controller.startNewSession,
                    onRefresh: controller.refreshSessions,
                    onSelected: controller.selectSession,
                    onOpenChat: controller.openChat,
                    onOpenSettings: controller.openSettings,
                    onOpenApps: controller.openApps,
                    onOpenAutomations: controller.openAutomations,
                    onOpenSkills: controller.openSkills,
                    onToggleShowArchived: controller.toggleShowArchived,
                  ),
                ),
                const VerticalDivider(width: 1, color: AppThemeTokens.border),
                Expanded(child: chat),
              ],
            );
          },
        ),
      ),
    );
  }

  void _send(NanobotWorkspaceController controller) {
    final input = _inputController.text;
    if (input.trim().isEmpty) {
      return;
    }
    _inputController.clear();
    controller.sendMessage(input);
    _focusNode.requestFocus();
  }
}

class _SessionList extends StatelessWidget {
  const _SessionList({
    required this.state,
    required this.onNewChat,
    required this.onRefresh,
    required this.onSelected,
    required this.onOpenChat,
    required this.onOpenSettings,
    required this.onOpenApps,
    required this.onOpenAutomations,
    required this.onOpenSkills,
    required this.onToggleShowArchived,
  });

  final NanobotWorkspaceState state;
  final VoidCallback onNewChat;
  final VoidCallback onRefresh;
  final ValueChanged<NanobotSessionSummary> onSelected;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenApps;
  final VoidCallback onOpenAutomations;
  final VoidCallback onOpenSkills;
  final VoidCallback onToggleShowArchived;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppThemeTokens.workspaceAlt,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Nanobot',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppThemeTokens.headingText,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                ),
                IconButton.filled(
                  tooltip: 'New chat',
                  onPressed: state.isBootstrapping ? null : onNewChat,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppThemeTokens.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Column(
              children: [
                _ShellNavTile(
                  label: 'Chats',
                  icon: Icons.forum_outlined,
                  selected: state.activeView == NanobotShellView.chat,
                  onTap: onOpenChat,
                ),
                _ShellNavTile(
                  label: 'Settings',
                  icon: Icons.tune,
                  selected: state.activeView == NanobotShellView.settings,
                  onTap: onOpenSettings,
                ),
                _ShellNavTile(
                  label: 'Apps',
                  icon: Icons.apps_outlined,
                  selected: state.activeView == NanobotShellView.apps,
                  onTap: onOpenApps,
                ),
                _ShellNavTile(
                  label: 'Automations',
                  icon: Icons.schedule_outlined,
                  selected: state.activeView == NanobotShellView.automations,
                  onTap: onOpenAutomations,
                ),
                _ShellNavTile(
                  label: 'Skills',
                  icon: Icons.extension_outlined,
                  selected: state.activeView == NanobotShellView.skills,
                  onTap: onOpenSkills,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppThemeTokens.border),
          Expanded(
            child: state.isBootstrapping
                ? const Center(child: CircularProgressIndicator())
                : state.visibleSessions.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No sessions',
                        style: TextStyle(color: AppThemeTokens.mutedText),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.visibleSessions.length,
                    itemBuilder: (context, index) {
                      final session = state.visibleSessions[index];
                      return _SessionTile(
                        session: session,
                        title: state.displayTitleFor(session),
                        pinned: state.sidebarState.pinnedKeys.contains(
                          session.key,
                        ),
                        archived: state.sidebarState.archivedKeys.contains(
                          session.key,
                        ),
                        selected: session.key == state.selectedSessionKey,
                        onTap: () => onSelected(session),
                      );
                    },
                  ),
          ),
          if (state.sidebarState.archivedKeys.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: TextButton.icon(
                onPressed: onToggleShowArchived,
                icon: Icon(
                  state.sidebarState.showArchived
                      ? Icons.inventory_2_outlined
                      : Icons.unarchive_outlined,
                ),
                label: Text(
                  state.sidebarState.showArchived
                      ? 'Hide archived'
                      : 'Show archived',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShellNavTile extends StatelessWidget {
  const _ShellNavTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppThemeTokens.selected : Colors.transparent,
      borderRadius: BorderRadius.circular(AppThemeTokens.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppThemeTokens.mutedText),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppThemeTokens.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.title,
    required this.pinned,
    required this.archived,
    required this.selected,
    required this.onTap,
  });

  final NanobotSessionSummary session;
  final String title;
  final bool pinned;
  final bool archived;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? AppThemeTokens.selected : Colors.transparent,
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppThemeTokens.radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppThemeTokens.text,
                        ),
                      ),
                    ),
                    if (session.runStartedAt != null)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    if (pinned)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.push_pin_outlined,
                          size: 16,
                          color: AppThemeTokens.mutedText,
                        ),
                      ),
                    if (archived)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: AppThemeTokens.mutedText,
                        ),
                      ),
                  ],
                ),
                if (session.preview.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    session.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppThemeTokens.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatPane extends StatelessWidget {
  const _ChatPane({
    required this.state,
    required this.inputController,
    required this.focusNode,
    required this.onSend,
    required this.onStop,
    required this.onOpenSettings,
    required this.onRefresh,
    this.onOpenSessions,
  });

  final NanobotWorkspaceState state;
  final TextEditingController inputController;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final VoidCallback onOpenSettings;
  final VoidCallback onRefresh;
  final VoidCallback? onOpenSessions;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppThemeTokens.panel,
      child: Column(
        children: [
          _ChatHeader(
            state: state,
            onOpenSessions: onOpenSessions,
            onOpenSettings: onOpenSettings,
            onRefresh: onRefresh,
          ),
          const Divider(height: 1, color: AppThemeTokens.border),
          Expanded(
            child: state.isLoadingThread
                ? const Center(child: CircularProgressIndicator())
                : state.activeView == NanobotShellView.chat
                ? _MessageList(state: state)
                : _SecondarySurface(state: state),
          ),
          if (state.errorMessage != null)
            _InlineError(text: state.errorMessage!, onRetry: onRefresh),
          if (state.activeView == NanobotShellView.chat)
            _InputBar(
              controller: inputController,
              focusNode: focusNode,
              canSend: state.canSend,
              isStreaming: state.isStreaming,
              onSend: onSend,
              onStop: onStop,
            ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.state,
    required this.onOpenSettings,
    required this.onRefresh,
    this.onOpenSessions,
  });

  final NanobotWorkspaceState state;
  final VoidCallback onOpenSettings;
  final VoidCallback onRefresh;
  final VoidCallback? onOpenSessions;

  @override
  Widget build(BuildContext context) {
    final title = _titleFor(state);
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            if (onOpenSessions != null)
              IconButton(
                tooltip: 'Sessions',
                onPressed: onOpenSessions,
                icon: const Icon(Icons.forum_outlined),
              ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppThemeTokens.headingText,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _statusText(state),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppThemeTokens.mutedText,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Reconnect',
              onPressed: onRefresh,
              icon: const Icon(Icons.sync),
            ),
            IconButton(
              tooltip: 'Connection settings',
              onPressed: onOpenSettings,
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
      ),
    );
  }

  String _titleFor(NanobotWorkspaceState state) {
    return switch (state.activeView) {
      NanobotShellView.chat => state.selectedSession?.displayTitle ?? 'Nanobot',
      NanobotShellView.settings => 'Settings',
      NanobotShellView.apps => 'Apps',
      NanobotShellView.automations => 'Automations',
      NanobotShellView.skills => 'Skills',
    };
  }

  String _statusText(NanobotWorkspaceState state) {
    final model = state.modelName?.trim();
    final modelText = model == null || model.isEmpty ? 'model unknown' : model;
    return '${_socketText(state.socketStatus)} · $modelText';
  }

  String _socketText(NanobotSocketStatus status) {
    return switch (status) {
      NanobotSocketStatus.idle => 'idle',
      NanobotSocketStatus.connecting => 'connecting',
      NanobotSocketStatus.open => 'connected',
      NanobotSocketStatus.closed => 'closed',
      NanobotSocketStatus.error => 'error',
    };
  }
}

class _SecondarySurface extends StatelessWidget {
  const _SecondarySurface({required this.state});

  final NanobotWorkspaceState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingSurface) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: switch (state.activeView) {
        NanobotShellView.settings => _SettingsSurface(
          snapshot: state.settingsSnapshot,
        ),
        NanobotShellView.apps => _CatalogSurface(
          title: 'Apps',
          emptyText: 'No apps',
          items: state.appItems,
        ),
        NanobotShellView.automations => _CatalogSurface(
          title: 'Automations',
          emptyText: 'No automations',
          items: state.automationItems,
        ),
        NanobotShellView.skills => _CatalogSurface(
          title: 'Skills',
          emptyText: 'No skills',
          items: state.skillItems,
        ),
        NanobotShellView.chat => const SizedBox.shrink(),
      },
    );
  }
}

class _SettingsSurface extends StatelessWidget {
  const _SettingsSurface({required this.snapshot});

  final NanobotSettingsSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final value = snapshot;
    if (value == null) {
      return const _EmptySurface(text: 'No settings loaded');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SurfaceTitle('Settings'),
        const SizedBox(height: 16),
        _SurfaceRow(label: 'Model', value: value.model ?? 'unknown'),
        _SurfaceRow(label: 'Provider', value: value.provider ?? 'unknown'),
        _SurfaceRow(label: 'Usage', value: '${value.totalTokens} tokens'),
        if (value.version != null)
          _SurfaceRow(label: 'Version', value: value.version!),
        _SurfaceRow(
          label: 'Restart',
          value: value.requiresRestart ? 'required' : 'not required',
        ),
      ],
    );
  }
}

class _CatalogSurface extends StatelessWidget {
  const _CatalogSurface({
    required this.title,
    required this.emptyText,
    required this.items,
  });

  final String title;
  final String emptyText;
  final List<NanobotCatalogItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptySurface(text: emptyText);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SurfaceTitle(title),
        const SizedBox(height: 16),
        for (final item in items)
          _CatalogRow(key: ValueKey(item.id), item: item),
      ],
    );
  }
}

class _CatalogRow extends StatelessWidget {
  const _CatalogRow({super.key, required this.item});

  final NanobotCatalogItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemeTokens.workspaceAlt,
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
        border: Border.all(color: AppThemeTokens.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppThemeTokens.headingText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      color: AppThemeTokens.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (item.status.trim().isNotEmpty)
            Text(
              item.status,
              style: const TextStyle(
                color: AppThemeTokens.brandPressed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _SurfaceRow extends StatelessWidget {
  const _SurfaceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemeTokens.workspaceAlt,
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
        border: Border.all(color: AppThemeTokens.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AppThemeTokens.mutedText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppThemeTokens.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceTitle extends StatelessWidget {
  const _SurfaceTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppThemeTokens.headingText,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _EmptySurface extends StatelessWidget {
  const _EmptySurface({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(color: AppThemeTokens.mutedText),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.state});

  final NanobotWorkspaceState state;

  @override
  Widget build(BuildContext context) {
    final threadEntries = state.threadState?.entries;
    if (threadEntries != null) {
      if (threadEntries.isEmpty) {
        return const Center(
          child: Text(
            'Start a chat',
            style: TextStyle(color: AppThemeTokens.mutedText),
          ),
        );
      }
      return ListView.builder(
        reverse: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        addAutomaticKeepAlives: false,
        addSemanticIndexes: false,
        itemCount: threadEntries.length,
        itemBuilder: (context, index) {
          final entry = threadEntries[threadEntries.length - 1 - index];
          return RepaintBoundary(
            key: ValueKey(entry.id),
            child: _ThreadEntryBubble(entry: entry),
          );
        },
      );
    }

    final hasActivity =
        state.reasoningText?.trim().isNotEmpty == true ||
        state.activityText?.trim().isNotEmpty == true;
    if (state.messages.isEmpty && !hasActivity) {
      return const Center(
        child: Text(
          'Start a chat',
          style: TextStyle(color: AppThemeTokens.mutedText),
        ),
      );
    }
    return ListView.builder(
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      addAutomaticKeepAlives: false,
      addSemanticIndexes: false,
      itemCount: state.messages.length + (hasActivity ? 1 : 0),
      itemBuilder: (context, index) {
        if (hasActivity && index == 0) {
          return _ActivityBubble(
            reasoningText: state.reasoningText,
            activityText: state.activityText,
          );
        }
        final offset = hasActivity ? 1 : 0;
        final messageIndex = state.messages.length - 1 - (index - offset);
        final message = state.messages[messageIndex];
        return RepaintBoundary(
          key: ValueKey(message.id),
          child: _MessageBubble(message: message),
        );
      },
    );
  }
}

class _ThreadEntryBubble extends StatelessWidget {
  const _ThreadEntryBubble({required this.entry});

  final NanobotThreadEntry entry;

  @override
  Widget build(BuildContext context) {
    return switch (entry.kind) {
      NanobotThreadEntryKind.message => _ThreadMessageBubble(entry: entry),
      NanobotThreadEntryKind.trace => _ThreadTraceBubble(entry: entry),
      NanobotThreadEntryKind.fileEdit => _ThreadFileEditBubble(entry: entry),
    };
  }
}

class _ThreadMessageBubble extends StatelessWidget {
  const _ThreadMessageBubble({required this.entry});

  final NanobotThreadEntry entry;

  @override
  Widget build(BuildContext context) {
    final isUser = entry.role == NanobotThreadRole.user;
    final color = isUser ? AppThemeTokens.brand : AppThemeTokens.workspaceAlt;
    final textColor = isUser ? Colors.white : AppThemeTokens.text;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppThemeTokens.radius),
            border: isUser ? null : Border.all(color: AppThemeTokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (entry.reasoning?.trim().isNotEmpty == true) ...[
                Text(
                  entry.reasoning!,
                  style: TextStyle(
                    color: isUser ? Colors.white70 : AppThemeTokens.mutedText,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                if (entry.content.trim().isNotEmpty) const SizedBox(height: 8),
              ],
              if (entry.content.trim().isNotEmpty)
                Text(
                  entry.content,
                  style: TextStyle(color: textColor, height: 1.4),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadTraceBubble extends StatelessWidget {
  const _ThreadTraceBubble({required this.entry});

  final NanobotThreadEntry entry;

  @override
  Widget build(BuildContext context) {
    final traces = entry.traces.isNotEmpty ? entry.traces : [entry.content];
    return _ThreadActivityShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final trace in traces)
            if (trace.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  trace,
                  style: const TextStyle(
                    color: AppThemeTokens.text,
                    height: 1.35,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _ThreadFileEditBubble extends StatelessWidget {
  const _ThreadFileEditBubble({required this.entry});

  final NanobotThreadEntry entry;

  @override
  Widget build(BuildContext context) {
    return _ThreadActivityShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Editing files',
            style: TextStyle(
              color: AppThemeTokens.brandPressed,
              fontWeight: FontWeight.w600,
            ),
          ),
          for (final edit in entry.fileEdits) ...[
            const SizedBox(height: 8),
            _ThreadFileEditRow(edit: edit),
          ],
        ],
      ),
    );
  }
}

class _ThreadFileEditRow extends StatelessWidget {
  const _ThreadFileEditRow({required this.edit});

  final Map<String, Object?> edit;

  @override
  Widget build(BuildContext context) {
    final path = edit['path'] as String? ?? '';
    final added = edit['added'] is num ? (edit['added'] as num).toInt() : 0;
    final deleted = edit['deleted'] is num
        ? (edit['deleted'] as num).toInt()
        : 0;
    return Row(
      children: [
        Expanded(
          child: Text(
            path.isEmpty ? 'Pending file edit' : path,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppThemeTokens.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '+$added -$deleted',
          style: const TextStyle(color: AppThemeTokens.mutedText, fontSize: 12),
        ),
      ],
    );
  }
}

class _ThreadActivityShell extends StatelessWidget {
  const _ThreadActivityShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppThemeTokens.brandSofter,
            borderRadius: BorderRadius.circular(AppThemeTokens.radius),
            border: Border.all(color: AppThemeTokens.selectedBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final NanobotMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == NanobotMessageRole.user;
    final color = message.status == NanobotMessageStatus.failed
        ? AppThemeTokens.dangerSoft
        : isUser
        ? AppThemeTokens.brand
        : AppThemeTokens.workspaceAlt;
    final textColor = isUser ? Colors.white : AppThemeTokens.text;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppThemeTokens.radius),
            border: isUser
                ? null
                : Border.all(
                    color: message.status == NanobotMessageStatus.failed
                        ? AppThemeTokens.dangerBorder
                        : AppThemeTokens.border,
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.reasoning?.trim().isNotEmpty == true) ...[
                Text(
                  message.reasoning!,
                  style: TextStyle(
                    color: isUser ? Colors.white70 : AppThemeTokens.mutedText,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                message.content,
                style: TextStyle(color: textColor, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityBubble extends StatelessWidget {
  const _ActivityBubble({this.reasoningText, this.activityText});

  final String? reasoningText;
  final String? activityText;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppThemeTokens.brandSofter,
            borderRadius: BorderRadius.circular(AppThemeTokens.radius),
            border: Border.all(color: AppThemeTokens.selectedBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (activityText?.trim().isNotEmpty == true)
                Text(
                  activityText!,
                  style: const TextStyle(
                    color: AppThemeTokens.brandPressed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (reasoningText?.trim().isNotEmpty == true) ...[
                if (activityText?.trim().isNotEmpty == true)
                  const SizedBox(height: 8),
                Text(
                  reasoningText!,
                  style: const TextStyle(
                    color: AppThemeTokens.text,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: AppThemeTokens.dangerSoft,
        border: Border(top: BorderSide(color: AppThemeTokens.dangerBorder)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppThemeTokens.dangerText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppThemeTokens.dangerText),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.isStreaming,
    required this.onSend,
    required this.onStop,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final bool isStreaming;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: const BoxDecoration(
          color: AppThemeTokens.panel,
          border: Border(top: BorderSide(color: AppThemeTokens.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Message nanobot',
                  fillColor: AppThemeTokens.panelMuted,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: isStreaming ? 'Stop' : 'Send',
              onPressed: isStreaming
                  ? onStop
                  : canSend
                  ? onSend
                  : null,
              style: ButtonStyle(
                fixedSize: const WidgetStatePropertyAll(Size.square(44)),
                minimumSize: const WidgetStatePropertyAll(Size.square(44)),
                padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppThemeTokens.controlRadius,
                    ),
                  ),
                ),
              ),
              icon: Icon(isStreaming ? Icons.stop : Icons.arrow_upward),
            ),
          ],
        ),
      ),
    );
  }
}
