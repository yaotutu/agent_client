import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:agent_client/features/nanobot/application/nanobot_workspace_controller.dart';
import 'package:agent_client/features/nanobot/application/nanobot_workspace_state.dart';
import 'package:agent_client/features/nanobot/data/nanobot_ws_client.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_message.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_shell_models.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_thread_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                  onTogglePinned: controller.toggleSessionPinned,
                  onToggleArchived: controller.toggleSessionArchived,
                  onRenameSession: controller.renameSession,
                  onDeleteSession: controller.deleteSession,
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
              onWorkspaceAccessMode: controller.applyWorkspaceAccessMode,
              onWorkspaceProjectPath: controller.applyWorkspaceProjectPath,
              onOpenFilePreview: controller.openFilePreview,
              onCloseFilePreview: controller.closeFilePreview,
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
                    onTogglePinned: controller.toggleSessionPinned,
                    onToggleArchived: controller.toggleSessionArchived,
                    onRenameSession: controller.renameSession,
                    onDeleteSession: controller.deleteSession,
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
    required this.onTogglePinned,
    required this.onToggleArchived,
    required this.onRenameSession,
    required this.onDeleteSession,
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
  final ValueChanged<String> onTogglePinned;
  final ValueChanged<String> onToggleArchived;
  final Future<void> Function(String key, String title) onRenameSession;
  final Future<void> Function(String key) onDeleteSession;

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
                  label: 'Search',
                  icon: Icons.search,
                  selected: false,
                  onTap: () => _openSearch(context),
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
                        onTogglePinned: () => onTogglePinned(session.key),
                        onToggleArchived: () => onToggleArchived(session.key),
                        onRename: () => _renameSession(context, session),
                        onDelete: () => _deleteSession(context, session),
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

  Future<void> _renameSession(
    BuildContext context,
    NanobotSessionSummary session,
  ) async {
    final title = state.displayTitleFor(session);
    final next = await showDialog<String>(
      context: context,
      builder: (context) => _RenameSessionDialog(initialTitle: title),
    );
    if (next == null) {
      return;
    }
    await onRenameSession(session.key, next);
  }

  Future<void> _deleteSession(
    BuildContext context,
    NanobotSessionSummary session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteSessionDialog(),
    );
    if (confirmed != true) {
      return;
    }
    await onDeleteSession(session.key);
  }

  Future<void> _openSearch(BuildContext context) async {
    final selected = await showDialog<NanobotSessionSummary>(
      context: context,
      builder: (context) => _SessionSearchDialog(state: state),
    );
    if (selected == null) {
      return;
    }
    onSelected(selected);
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
    required this.onTogglePinned,
    required this.onToggleArchived,
    required this.onRename,
    required this.onDelete,
  });

  final NanobotSessionSummary session;
  final String title;
  final bool pinned;
  final bool archived;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onTogglePinned;
  final VoidCallback onToggleArchived;
  final VoidCallback onRename;
  final VoidCallback onDelete;

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
                    PopupMenuButton<_SessionAction>(
                      tooltip: 'Actions for $title',
                      icon: const Icon(Icons.more_horiz, size: 18),
                      padding: EdgeInsets.zero,
                      position: PopupMenuPosition.under,
                      onSelected: (action) {
                        switch (action) {
                          case _SessionAction.pin:
                            onTogglePinned();
                          case _SessionAction.rename:
                            onRename();
                          case _SessionAction.archive:
                            onToggleArchived();
                          case _SessionAction.delete:
                            onDelete();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _SessionAction.pin,
                          child: Text(pinned ? 'Unpin' : 'Pin'),
                        ),
                        const PopupMenuItem(
                          value: _SessionAction.rename,
                          child: Text('Rename'),
                        ),
                        PopupMenuItem(
                          value: _SessionAction.archive,
                          child: Text(archived ? 'Unarchive' : 'Archive'),
                        ),
                        const PopupMenuItem(
                          value: _SessionAction.delete,
                          child: Text('Delete'),
                        ),
                      ],
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

enum _SessionAction { pin, rename, archive, delete }

class _DeleteSessionDialog extends StatelessWidget {
  const _DeleteSessionDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete this chat?'),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

class _SessionSearchDialog extends StatefulWidget {
  const _SessionSearchDialog({required this.state});

  final NanobotWorkspaceState state;

  @override
  State<_SessionSearchDialog> createState() => _SessionSearchDialogState();
}

class _SessionSearchDialogState extends State<_SessionSearchDialog> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryController.text.trim().toLowerCase();
    final results = _searchResults(query);
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: TextField(
        controller: _queryController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Search',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        onChanged: (_) => setState(() {}),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      content: SizedBox(
        width: 420,
        height: 360,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              query.isEmpty ? 'Recent' : 'Results',
              style: const TextStyle(
                color: AppThemeTokens.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching chats.',
                        style: TextStyle(color: AppThemeTokens.mutedText),
                      ),
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final session = results[index];
                        final title = widget.state.displayTitleFor(session);
                        final preview = session.preview.trim();
                        return ListTile(
                          title: Text(title),
                          subtitle: preview.isEmpty ? null : Text(preview),
                          trailing:
                              session.key == widget.state.selectedSessionKey
                              ? const Text('Current')
                              : null,
                          onTap: () => Navigator.of(context).pop(session),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<NanobotSessionSummary> _searchResults(String query) {
    final sessions = widget.state.sessions;
    if (query.isEmpty) {
      return sessions;
    }
    final terms = query.split(RegExp(r'\s+')).where((term) => term.isNotEmpty);
    return [
      for (final session in sessions)
        if (_matchesAllTerms(session, terms)) session,
    ];
  }

  bool _matchesAllTerms(NanobotSessionSummary session, Iterable<String> terms) {
    final haystack = [
      widget.state.displayTitleFor(session),
      session.title,
      session.preview,
    ].join(' ').toLowerCase();
    return terms.every(haystack.contains);
  }
}

class _RenameSessionDialog extends StatefulWidget {
  const _RenameSessionDialog({required this.initialTitle});

  final String initialTitle;

  @override
  State<_RenameSessionDialog> createState() => _RenameSessionDialogState();
}

class _RenameSessionDialogState extends State<_RenameSessionDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename chat'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 160,
        decoration: const InputDecoration(hintText: 'Chat name'),
        onSubmitted: _submit,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  void _save() {
    _submit(_controller.text);
  }

  void _submit(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) {
      return;
    }
    Navigator.of(context).pop(cleaned);
  }
}

class _ChatPane extends StatelessWidget {
  const _ChatPane({
    required this.state,
    required this.inputController,
    required this.focusNode,
    required this.onSend,
    required this.onStop,
    required this.onWorkspaceAccessMode,
    required this.onWorkspaceProjectPath,
    required this.onOpenFilePreview,
    required this.onCloseFilePreview,
    required this.onOpenSettings,
    required this.onRefresh,
    this.onOpenSessions,
  });

  final NanobotWorkspaceState state;
  final TextEditingController inputController;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final ValueChanged<String> onWorkspaceAccessMode;
  final Future<void> Function(String path, {String? projectName})
  onWorkspaceProjectPath;
  final ValueChanged<String> onOpenFilePreview;
  final VoidCallback onCloseFilePreview;
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
                ? _ChatMessageArea(
                    state: state,
                    onOpenFilePreview: onOpenFilePreview,
                    onCloseFilePreview: onCloseFilePreview,
                  )
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
              slashCommands: state.slashCommands,
              skills: state.skillItems,
              capabilityMentions: state.capabilityMentions,
              workspaceScope: state.activeWorkspaceScope,
              defaultWorkspaceScope: state.workspacesSnapshot?.defaultScope,
              workspaceError: state.workspaceError,
              canChangeProject:
                  state.workspacesSnapshot?.controls?['can_change_project'] !=
                  false,
              canUseFullAccess: state.canUseFullWorkspaceAccess,
              onSend: onSend,
              onStop: onStop,
              onWorkspaceAccessMode: onWorkspaceAccessMode,
              onWorkspaceProjectPath: onWorkspaceProjectPath,
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
      NanobotSocketStatus.reconnecting => 'reconnecting',
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

class _ChatMessageArea extends StatelessWidget {
  const _ChatMessageArea({
    required this.state,
    required this.onOpenFilePreview,
    required this.onCloseFilePreview,
  });

  final NanobotWorkspaceState state;
  final ValueChanged<String> onOpenFilePreview;
  final VoidCallback onCloseFilePreview;

  @override
  Widget build(BuildContext context) {
    final previewPath = state.filePreviewPath;
    return Stack(
      children: [
        Positioned.fill(
          child: _MessageList(
            state: state,
            onOpenFilePreview: onOpenFilePreview,
          ),
        ),
        if (previewPath != null)
          Align(
            alignment: Alignment.centerRight,
            child: _FilePreviewPanel(
              state: state,
              path: previewPath,
              onClose: onCloseFilePreview,
            ),
          ),
      ],
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.state, required this.onOpenFilePreview});

  final NanobotWorkspaceState state;
  final ValueChanged<String> onOpenFilePreview;

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
            child: _ThreadEntryBubble(
              entry: entry,
              onOpenFilePreview: onOpenFilePreview,
            ),
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
          child: _MessageBubble(
            message: message,
            onOpenFilePreview: onOpenFilePreview,
          ),
        );
      },
    );
  }
}

class _FilePreviewPanel extends StatelessWidget {
  const _FilePreviewPanel({
    required this.state,
    required this.path,
    required this.onClose,
  });

  final NanobotWorkspaceState state;
  final String path;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final panelWidth = width < 520 ? width * 0.92 : 420.0;
    final preview = state.filePreview;
    return Material(
      elevation: 18,
      color: AppThemeTokens.panel,
      child: Container(
        width: panelWidth,
        height: double.infinity,
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppThemeTokens.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Close file preview',
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'File preview',
                      style: TextStyle(
                        color: AppThemeTokens.headingText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppThemeTokens.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                preview?.displayPath ?? path,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppThemeTokens.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(height: 1, color: AppThemeTokens.border),
            Expanded(child: _FilePreviewPanelBody(state: state)),
          ],
        ),
      ),
    );
  }
}

class _FilePreviewPanelBody extends StatelessWidget {
  const _FilePreviewPanelBody({required this.state});

  final NanobotWorkspaceState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingFilePreview) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = state.filePreviewError;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          error,
          style: const TextStyle(color: AppThemeTokens.dangerText),
        ),
      );
    }
    final preview = state.filePreview;
    if (preview == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (preview.truncated)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppThemeTokens.panelMuted,
            child: const Text(
              'Preview truncated',
              style: TextStyle(
                color: AppThemeTokens.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              preview.content,
              style: const TextStyle(
                color: AppThemeTokens.text,
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ThreadEntryBubble extends StatelessWidget {
  const _ThreadEntryBubble({
    required this.entry,
    required this.onOpenFilePreview,
  });

  final NanobotThreadEntry entry;
  final ValueChanged<String> onOpenFilePreview;

  @override
  Widget build(BuildContext context) {
    return switch (entry.kind) {
      NanobotThreadEntryKind.message => _ThreadMessageBubble(
        entry: entry,
        onOpenFilePreview: onOpenFilePreview,
      ),
      NanobotThreadEntryKind.trace => _ThreadTraceBubble(entry: entry),
      NanobotThreadEntryKind.fileEdit => _ThreadFileEditBubble(
        entry: entry,
        onOpenFilePreview: onOpenFilePreview,
      ),
    };
  }
}

class _ThreadMessageBubble extends StatelessWidget {
  const _ThreadMessageBubble({
    required this.entry,
    required this.onOpenFilePreview,
  });

  final NanobotThreadEntry entry;
  final ValueChanged<String> onOpenFilePreview;

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
                _MessageContentText(
                  text: entry.content,
                  textColor: textColor,
                  onOpenFilePreview: onOpenFilePreview,
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
  const _ThreadFileEditBubble({
    required this.entry,
    required this.onOpenFilePreview,
  });

  final NanobotThreadEntry entry;
  final ValueChanged<String> onOpenFilePreview;

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
            _ThreadFileEditRow(
              edit: edit,
              onOpenFilePreview: onOpenFilePreview,
            ),
          ],
        ],
      ),
    );
  }
}

class _ThreadFileEditRow extends StatelessWidget {
  const _ThreadFileEditRow({
    required this.edit,
    required this.onOpenFilePreview,
  });

  final Map<String, Object?> edit;
  final ValueChanged<String> onOpenFilePreview;

  @override
  Widget build(BuildContext context) {
    final path = edit['path'] as String? ?? '';
    final added = edit['added'] is num ? (edit['added'] as num).toInt() : 0;
    final deleted = edit['deleted'] is num
        ? (edit['deleted'] as num).toInt()
        : 0;
    final label = path.isEmpty ? 'Pending file edit' : path;
    return InkWell(
      onTap: path.isEmpty ? null : () => onOpenFilePreview(path),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            const Icon(
              Icons.description_outlined,
              size: 16,
              color: AppThemeTokens.mutedText,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
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
              style: const TextStyle(
                color: AppThemeTokens.mutedText,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageContentText extends StatelessWidget {
  const _MessageContentText({
    required this.text,
    required this.textColor,
    required this.onOpenFilePreview,
  });

  final String text;
  final Color textColor;
  final ValueChanged<String> onOpenFilePreview;

  @override
  Widget build(BuildContext context) {
    final segments = _messageContentSegments(text);
    if (segments.length == 1 && segments.single.filePath == null) {
      return Text(text, style: TextStyle(color: textColor, height: 1.4));
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final segment in segments)
          if (segment.filePath == null)
            Text(segment.text, style: TextStyle(color: textColor, height: 1.4))
          else
            _InlineFileReferenceChip(
              label: segment.text,
              path: segment.filePath!,
              onOpenFilePreview: onOpenFilePreview,
            ),
      ],
    );
  }
}

class _InlineFileReferenceChip extends StatelessWidget {
  const _InlineFileReferenceChip({
    required this.label,
    required this.path,
    required this.onOpenFilePreview,
  });

  final String label;
  final String path;
  final ValueChanged<String> onOpenFilePreview;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onOpenFilePreview(path),
      borderRadius: BorderRadius.circular(5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insert_drive_file_outlined,
              size: 14,
              color: AppThemeTokens.brandPressed,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                color: AppThemeTokens.brandPressed,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageContentSegment {
  const _MessageContentSegment.text(this.text) : filePath = null;
  const _MessageContentSegment.file({
    required this.text,
    required this.filePath,
  });

  final String text;
  final String? filePath;
}

List<_MessageContentSegment> _messageContentSegments(String text) {
  final matches = RegExp(r'\[([^\]]+)\]\(([^)]+)\)').allMatches(text).toList();
  if (matches.isEmpty) {
    return [if (text.isNotEmpty) _MessageContentSegment.text(text)];
  }
  final segments = <_MessageContentSegment>[];
  var cursor = 0;
  for (final match in matches) {
    final href = match.group(2) ?? '';
    final filePath = _localFilePreviewPath(href);
    if (filePath == null) {
      continue;
    }
    if (match.start > cursor) {
      segments.add(
        _MessageContentSegment.text(text.substring(cursor, match.start)),
      );
    }
    final label = (match.group(1) ?? filePath).trim();
    segments.add(
      _MessageContentSegment.file(
        text: label.isEmpty ? _fileNameFromPath(filePath) : label,
        filePath: filePath,
      ),
    );
    cursor = match.end;
  }
  if (cursor == 0) {
    return [if (text.isNotEmpty) _MessageContentSegment.text(text)];
  }
  if (cursor < text.length) {
    segments.add(_MessageContentSegment.text(text.substring(cursor)));
  }
  return segments;
}

String? _localFilePreviewPath(String href) {
  final trimmed = Uri.decodeFull(href.trim());
  if (trimmed.isEmpty ||
      trimmed.startsWith('http://') ||
      trimmed.startsWith('https://') ||
      trimmed.startsWith('/api/') ||
      trimmed.contains('*')) {
    return null;
  }
  final withoutAnchor = trimmed.split('#').first.split('?').first;
  final withoutLine = withoutAnchor.replaceFirst(RegExp(r':\d+(?::\d+)?$'), '');
  if (!RegExp(r'\.[A-Za-z0-9]{1,12}$').hasMatch(withoutLine)) {
    return null;
  }
  return withoutLine;
}

String _fileNameFromPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  final parts = normalized.split('/').where((part) => part.isNotEmpty).toList();
  return parts.isEmpty ? path : parts.last;
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
  const _MessageBubble({
    required this.message,
    required this.onOpenFilePreview,
  });

  final NanobotMessage message;
  final ValueChanged<String> onOpenFilePreview;

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
              _MessageContentText(
                text: message.content,
                textColor: textColor,
                onOpenFilePreview: onOpenFilePreview,
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

class _WorkspaceScopeBar extends StatelessWidget {
  const _WorkspaceScopeBar({
    required this.scope,
    required this.defaultScope,
    required this.canChangeProject,
    required this.canUseFullAccess,
    required this.onAccessMode,
    required this.onProjectPath,
    this.error,
  });

  final NanobotWorkspaceScope scope;
  final NanobotWorkspaceScope? defaultScope;
  final bool canChangeProject;
  final bool canUseFullAccess;
  final ValueChanged<String> onAccessMode;
  final Future<void> Function(String path, {String? projectName}) onProjectPath;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final modeLabel = scope.isFullAccess ? 'Full Access' : 'Default Permission';
    final canOpenProjectPicker = canChangeProject && defaultScope != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppThemeTokens.panelMuted,
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
        border: Border.all(color: AppThemeTokens.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.folder_outlined,
            size: 18,
            color: AppThemeTokens.mutedText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppThemeTokens.radius),
              onTap: canOpenProjectPicker
                  ? () => _openProjectPicker(context, defaultScope!)
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            scope.projectLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppThemeTokens.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (canOpenProjectPicker)
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: AppThemeTokens.mutedText,
                          ),
                      ],
                    ),
                    if (error?.trim().isNotEmpty == true)
                      Text(
                        error!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppThemeTokens.dangerText,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Workspace access mode',
            onSelected: onAccessMode,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'restricted',
                child: Text('Default Permission'),
              ),
              PopupMenuItem(
                value: 'full',
                enabled: canUseFullAccess,
                child: const Text('Full Access'),
              ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  scope.isFullAccess
                      ? Icons.warning_amber_outlined
                      : Icons.pan_tool_alt_outlined,
                  size: 16,
                  color: scope.isFullAccess
                      ? AppThemeTokens.warning
                      : AppThemeTokens.mutedText,
                ),
                const SizedBox(width: 6),
                Text(
                  modeLabel,
                  style: TextStyle(
                    color: scope.isFullAccess
                        ? AppThemeTokens.warning
                        : AppThemeTokens.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openProjectPicker(
    BuildContext context,
    NanobotWorkspaceScope defaultScope,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _WorkspaceProjectPickerDialog(
        scope: scope,
        defaultScope: defaultScope,
        onProjectPath: onProjectPath,
      ),
    );
  }
}

class _WorkspaceProjectPickerDialog extends StatefulWidget {
  const _WorkspaceProjectPickerDialog({
    required this.scope,
    required this.defaultScope,
    required this.onProjectPath,
  });

  final NanobotWorkspaceScope scope;
  final NanobotWorkspaceScope defaultScope;
  final Future<void> Function(String path, {String? projectName}) onProjectPath;

  @override
  State<_WorkspaceProjectPickerDialog> createState() =>
      _WorkspaceProjectPickerDialogState();
}

class _WorkspaceProjectPickerDialogState
    extends State<_WorkspaceProjectPickerDialog> {
  late final TextEditingController _pathController;
  String? _pathError;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select project'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Default workspace'),
              subtitle: Text(
                widget.defaultScope.projectPath,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: _isApplying
                  ? null
                  : () => _applyPath(
                      widget.defaultScope.projectPath,
                      projectName: widget.defaultScope.projectName,
                    ),
            ),
            const Divider(),
            TextField(
              controller: _pathController,
              enabled: !_isApplying,
              decoration: InputDecoration(
                labelText: 'Manual path',
                hintText: '/path/to/project',
                errorText: _pathError,
              ),
              onChanged: (_) {
                if (_pathError == null) {
                  return;
                }
                setState(() => _pathError = null);
              },
              onSubmitted: (_) => _applyManualPath(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isApplying ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isApplying ? null : _applyManualPath,
          child: const Text('Use Path'),
        ),
      ],
    );
  }

  Future<void> _applyManualPath() {
    return _applyPath(_pathController.text);
  }

  Future<void> _applyPath(String projectPath, {String? projectName}) async {
    final trimmed = projectPath.trim();
    if (!_isAbsoluteWorkspacePath(trimmed)) {
      setState(() {
        _pathError = 'Enter an absolute folder path on this machine.';
      });
      return;
    }
    setState(() {
      _isApplying = true;
      _pathError = null;
    });
    await widget.onProjectPath(trimmed, projectName: projectName);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}

bool _isAbsoluteWorkspacePath(String path) {
  final trimmed = path.trim();
  return trimmed == '~' ||
      trimmed.startsWith('~/') ||
      trimmed.startsWith(r'~\') ||
      trimmed.startsWith('/') ||
      RegExp(r'^[A-Za-z]:[\\/]').hasMatch(trimmed);
}

class _InputBar extends StatefulWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.isStreaming,
    required this.slashCommands,
    required this.skills,
    required this.capabilityMentions,
    required this.workspaceScope,
    required this.defaultWorkspaceScope,
    required this.workspaceError,
    required this.canChangeProject,
    required this.canUseFullAccess,
    required this.onSend,
    required this.onStop,
    required this.onWorkspaceAccessMode,
    required this.onWorkspaceProjectPath,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final bool isStreaming;
  final List<NanobotSlashCommand> slashCommands;
  final List<NanobotCatalogItem> skills;
  final List<NanobotCapabilityMention> capabilityMentions;
  final NanobotWorkspaceScope? workspaceScope;
  final NanobotWorkspaceScope? defaultWorkspaceScope;
  final String? workspaceError;
  final bool canChangeProject;
  final bool canUseFullAccess;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final ValueChanged<String> onWorkspaceAccessMode;
  final Future<void> Function(String path, {String? projectName})
  onWorkspaceProjectPath;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  String? _dismissedSlashText;
  var _selectedPaletteIndex = 0;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.workspaceScope != null)
                    _WorkspaceScopeBar(
                      scope: widget.workspaceScope!,
                      defaultScope: widget.defaultWorkspaceScope,
                      error: widget.workspaceError,
                      canChangeProject: widget.canChangeProject,
                      canUseFullAccess: widget.canUseFullAccess,
                      onAccessMode: widget.onWorkspaceAccessMode,
                      onProjectPath: widget.onWorkspaceProjectPath,
                    ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: widget.controller,
                    builder: (context, value, _) {
                      final commands = _filteredSlashCommands(value.text);
                      if (commands.isNotEmpty &&
                          _dismissedSlashText != value.text) {
                        return _SlashCommandPalette(
                          commands: commands,
                          selectedIndex: _selectedIndex(commands.length),
                          onSelected: _chooseSlashCommand,
                        );
                      }
                      final query = _skillQuery(value);
                      final skills = _filteredSkills(query);
                      if (query != null && skills.isNotEmpty) {
                        return _SkillMentionPalette(
                          skills: skills,
                          selectedIndex: _selectedIndex(skills.length),
                          onSelected: (skill) => _chooseSkill(skill, query),
                        );
                      }
                      final mentionQuery = _capabilityMentionQuery(value);
                      final mentions = _filteredCapabilityMentions(
                        mentionQuery,
                      );
                      if (mentionQuery != null && mentions.isNotEmpty) {
                        return _CapabilityMentionPalette(
                          mentions: mentions,
                          selectedIndex: _selectedIndex(mentions.length),
                          onSelected: (mention) =>
                              _chooseCapabilityMention(mention, mentionQuery),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Focus(
                    onKeyEvent: _handleKeyEvent,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
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
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: widget.isStreaming ? 'Stop' : 'Send',
              onPressed: widget.isStreaming
                  ? widget.onStop
                  : widget.canSend
                  ? widget.onSend
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
              icon: Icon(widget.isStreaming ? Icons.stop : Icons.arrow_upward),
            ),
          ],
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final active = _activePalette(widget.controller.value);
    if (active.length == 0) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedPaletteIndex =
            (_selectedIndex(active.length) + 1) % active.length;
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedPaletteIndex =
            (_selectedIndex(active.length) - 1 + active.length) % active.length;
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab || key == LogicalKeyboardKey.enter) {
      _chooseActivePaletteItem(active);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  int _selectedIndex(int length) {
    if (length <= 0) {
      return 0;
    }
    return _selectedPaletteIndex.clamp(0, length - 1);
  }

  _ActivePalette _activePalette(TextEditingValue value) {
    final commands = _filteredSlashCommands(value.text);
    if (commands.isNotEmpty && _dismissedSlashText != value.text) {
      return _ActivePalette.slash(commands);
    }
    final skillQuery = _skillQuery(value);
    final skills = _filteredSkills(skillQuery);
    if (skillQuery != null && skills.isNotEmpty) {
      return _ActivePalette.skills(skills, skillQuery);
    }
    final capabilityQuery = _capabilityMentionQuery(value);
    final mentions = _filteredCapabilityMentions(capabilityQuery);
    if (capabilityQuery != null && mentions.isNotEmpty) {
      return _ActivePalette.capabilities(mentions, capabilityQuery);
    }
    return const _ActivePalette.none();
  }

  void _chooseActivePaletteItem(_ActivePalette active) {
    final index = _selectedIndex(active.length);
    switch (active.kind) {
      case _ActivePaletteKind.none:
        return;
      case _ActivePaletteKind.slash:
        _chooseSlashCommand(active.slashCommands[index]);
      case _ActivePaletteKind.skills:
        _chooseSkill(active.skills[index], active.skillQuery!);
      case _ActivePaletteKind.capabilities:
        _chooseCapabilityMention(
          active.capabilityMentions[index],
          active.capabilityQuery!,
        );
    }
  }

  List<NanobotSlashCommand> _filteredSlashCommands(String text) {
    final query = _slashQuery(text);
    if (query == null) {
      return const [];
    }
    return widget.slashCommands
        .where((command) {
          if (query.isEmpty) {
            return true;
          }
          final haystack = [
            command.command,
            command.title,
            command.description,
            command.argHint,
          ].join(' ').toLowerCase();
          return haystack.contains(query);
        })
        .take(8)
        .toList();
  }

  String? _slashQuery(String text) {
    if (!text.startsWith('/')) {
      return null;
    }
    final token = text.substring(1);
    if (RegExp(r'\s').hasMatch(token)) {
      return null;
    }
    return token.toLowerCase();
  }

  void _chooseSlashCommand(NanobotSlashCommand command) {
    final inserted = command.argHint.trim().isEmpty
        ? command.command
        : '${command.command} ';
    setState(() {
      _dismissedSlashText = inserted;
      _selectedPaletteIndex = 0;
      widget.controller.value = TextEditingValue(
        text: inserted,
        selection: TextSelection.collapsed(offset: inserted.length),
      );
    });
    widget.focusNode.requestFocus();
  }

  _SkillMentionQuery? _skillQuery(TextEditingValue value) {
    final caret = value.selection.isValid
        ? value.selection.baseOffset.clamp(0, value.text.length)
        : value.text.length;
    final beforeCaret = value.text.substring(0, caret);
    final match = RegExp(r'\$([A-Za-z0-9_-]*)$').firstMatch(beforeCaret);
    if (match == null) {
      return null;
    }
    return _SkillMentionQuery(
      start: match.start,
      end: caret,
      text: match.group(1)!.toLowerCase(),
    );
  }

  List<NanobotCatalogItem> _filteredSkills(_SkillMentionQuery? query) {
    if (query == null) {
      return const [];
    }
    return widget.skills
        .where((skill) => skill.status != 'unavailable')
        .where((skill) {
          if (query.text.isEmpty) {
            return true;
          }
          final haystack = [
            skill.id,
            skill.title,
            skill.subtitle,
          ].join(' ').toLowerCase();
          return haystack.contains(query.text);
        })
        .take(8)
        .toList();
  }

  void _chooseSkill(NanobotCatalogItem skill, _SkillMentionQuery query) {
    final value = widget.controller.value;
    final suffix = value.text.substring(query.end);
    final name = skill.id.trim().isNotEmpty ? skill.id : skill.title;
    final mention = '\$$name${suffix.startsWith(' ') ? '' : ' '}';
    final next = '${value.text.substring(0, query.start)}$mention$suffix';
    final cursor = query.start + mention.length;
    widget.controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: cursor),
    );
    _selectedPaletteIndex = 0;
    widget.focusNode.requestFocus();
  }

  _CapabilityMentionQuery? _capabilityMentionQuery(TextEditingValue value) {
    final caret = value.selection.isValid
        ? value.selection.baseOffset.clamp(0, value.text.length)
        : value.text.length;
    final beforeCaret = value.text.substring(0, caret);
    final match = RegExp(r'(?:^|\s)@([A-Za-z0-9_-]*)$').firstMatch(beforeCaret);
    if (match == null) {
      return null;
    }
    return _CapabilityMentionQuery(
      start: caret - match.group(1)!.length - 1,
      end: caret,
      text: match.group(1)!.toLowerCase(),
    );
  }

  List<NanobotCapabilityMention> _filteredCapabilityMentions(
    _CapabilityMentionQuery? query,
  ) {
    if (query == null) {
      return const [];
    }
    return widget.capabilityMentions
        .where((mention) => mention.canMention)
        .where((mention) {
          if (query.text.isEmpty) {
            return true;
          }
          final haystack = [
            mention.name,
            mention.displayName,
            mention.category,
            mention.description,
            mention.entryPoint,
            mention.transport,
          ].whereType<String>().join(' ').toLowerCase();
          return haystack.contains(query.text);
        })
        .take(8)
        .toList();
  }

  void _chooseCapabilityMention(
    NanobotCapabilityMention mention,
    _CapabilityMentionQuery query,
  ) {
    final value = widget.controller.value;
    final suffix = value.text.substring(query.end);
    final token = '@${mention.name}${suffix.startsWith(' ') ? '' : ' '}';
    final next = '${value.text.substring(0, query.start)}$token$suffix';
    final cursor = query.start + token.length;
    widget.controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: cursor),
    );
    _selectedPaletteIndex = 0;
    widget.focusNode.requestFocus();
  }
}

enum _ActivePaletteKind { none, slash, skills, capabilities }

class _ActivePalette {
  const _ActivePalette.none()
    : kind = _ActivePaletteKind.none,
      slashCommands = const [],
      skills = const [],
      capabilityMentions = const [],
      skillQuery = null,
      capabilityQuery = null;

  const _ActivePalette.slash(this.slashCommands)
    : kind = _ActivePaletteKind.slash,
      skills = const [],
      capabilityMentions = const [],
      skillQuery = null,
      capabilityQuery = null;

  const _ActivePalette.skills(this.skills, this.skillQuery)
    : kind = _ActivePaletteKind.skills,
      slashCommands = const [],
      capabilityMentions = const [],
      capabilityQuery = null;

  const _ActivePalette.capabilities(
    this.capabilityMentions,
    this.capabilityQuery,
  ) : kind = _ActivePaletteKind.capabilities,
      slashCommands = const [],
      skills = const [],
      skillQuery = null;

  final _ActivePaletteKind kind;
  final List<NanobotSlashCommand> slashCommands;
  final List<NanobotCatalogItem> skills;
  final List<NanobotCapabilityMention> capabilityMentions;
  final _SkillMentionQuery? skillQuery;
  final _CapabilityMentionQuery? capabilityQuery;

  int get length {
    return switch (kind) {
      _ActivePaletteKind.none => 0,
      _ActivePaletteKind.slash => slashCommands.length,
      _ActivePaletteKind.skills => skills.length,
      _ActivePaletteKind.capabilities => capabilityMentions.length,
    };
  }
}

class _SkillMentionQuery {
  const _SkillMentionQuery({
    required this.start,
    required this.end,
    required this.text,
  });

  final int start;
  final int end;
  final String text;
}

class _CapabilityMentionQuery {
  const _CapabilityMentionQuery({
    required this.start,
    required this.end,
    required this.text,
  });

  final int start;
  final int end;
  final String text;
}

class _CapabilityMentionPalette extends StatelessWidget {
  const _CapabilityMentionPalette({
    required this.mentions,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<NanobotCapabilityMention> mentions;
  final int selectedIndex;
  final ValueChanged<NanobotCapabilityMention> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: AppThemeTokens.workspaceAlt,
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
        border: Border.all(color: AppThemeTokens.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: mentions.length,
        itemBuilder: (context, index) {
          final mention = mentions[index];
          final selected = index == selectedIndex;
          final badge = mention.kind == NanobotCapabilityMentionKind.cli
              ? 'CLI'
              : 'MCP';
          return InkWell(
            onTap: () => onSelected(mention),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppThemeTokens.panelMuted : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _CapabilityMentionBadge(mention: mention),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mention.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppThemeTokens.headingText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (mention.description.trim().isNotEmpty)
                          Text(
                            mention.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppThemeTokens.mutedText,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '@${mention.name}',
                    style: const TextStyle(
                      color: AppThemeTokens.mutedText,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: mention.kind == NanobotCapabilityMentionKind.cli
                          ? const Color(0x1AFF8A00)
                          : const Color(0x1A0EA5E9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: mention.kind == NanobotCapabilityMentionKind.cli
                            ? const Color(0xFFC45A00)
                            : const Color(0xFF0284C7),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CapabilityMentionBadge extends StatelessWidget {
  const _CapabilityMentionBadge({required this.mention});

  final NanobotCapabilityMention mention;

  @override
  Widget build(BuildContext context) {
    final color = _capabilityColor(mention.brandColor);
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        _capabilityInitials(mention),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Color _capabilityColor(String? value) {
  final raw = value?.trim();
  if (raw != null && RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(raw)) {
    return Color(int.parse('FF${raw.substring(1)}', radix: 16));
  }
  return AppThemeTokens.accent;
}

String _capabilityInitials(NanobotCapabilityMention mention) {
  final source = mention.displayName.trim().isNotEmpty
      ? mention.displayName
      : mention.name;
  final parts = source
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();
  final initials = parts.map((part) => part[0].toUpperCase()).join();
  return initials.isNotEmpty
      ? initials
      : mention.name
            .substring(0, mention.name.length.clamp(0, 2))
            .toUpperCase();
}

class _SkillMentionPalette extends StatelessWidget {
  const _SkillMentionPalette({
    required this.skills,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<NanobotCatalogItem> skills;
  final int selectedIndex;
  final ValueChanged<NanobotCatalogItem> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: AppThemeTokens.workspaceAlt,
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
        border: Border.all(color: AppThemeTokens.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: skills.length,
        itemBuilder: (context, index) {
          final skill = skills[index];
          final selected = index == selectedIndex;
          final name = skill.id.trim().isNotEmpty ? skill.id : skill.title;
          return InkWell(
            onTap: () => onSelected(skill),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppThemeTokens.panelMuted : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.psychology_outlined,
                    size: 18,
                    color: AppThemeTokens.mutedText,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          skill.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppThemeTokens.headingText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (skill.subtitle.trim().isNotEmpty)
                          Text(
                            skill.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppThemeTokens.mutedText,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '\$$name',
                    style: const TextStyle(
                      color: AppThemeTokens.mutedText,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SlashCommandPalette extends StatelessWidget {
  const _SlashCommandPalette({
    required this.commands,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<NanobotSlashCommand> commands;
  final int selectedIndex;
  final ValueChanged<NanobotSlashCommand> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: AppThemeTokens.workspaceAlt,
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
        border: Border.all(color: AppThemeTokens.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: commands.length,
        itemBuilder: (context, index) {
          final command = commands[index];
          final selected = index == selectedIndex;
          return InkWell(
            onTap: () => onSelected(command),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppThemeTokens.panelMuted : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _iconForSlashCommand(command.icon),
                    size: 18,
                    color: AppThemeTokens.mutedText,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          command.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppThemeTokens.headingText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          command.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppThemeTokens.mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    command.argHint.trim().isEmpty
                        ? command.command
                        : '${command.command} ${command.argHint}',
                    style: const TextStyle(
                      color: AppThemeTokens.mutedText,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

IconData _iconForSlashCommand(String icon) {
  return switch (icon) {
    'activity' => Icons.monitor_heart_outlined,
    'brain' => Icons.psychology_outlined,
    'history' => Icons.history,
    'rotate-cw' => Icons.sync,
    'sparkles' => Icons.auto_awesome,
    'square' => Icons.stop,
    'square-pen' => Icons.edit_square,
    'shield' => Icons.shield_outlined,
    'wrench' => Icons.build_outlined,
    _ => Icons.help_outline,
  };
}
