import 'dart:async';
import 'dart:convert';

import 'package:agent_client/features/nanobot/application/nanobot_image_attachment_picker.dart';
import 'package:agent_client/features/nanobot/application/nanobot_voice_input_recorder.dart';
import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:agent_client/features/nanobot/application/nanobot_workspace_controller.dart';
import 'package:agent_client/features/nanobot/application/nanobot_workspace_state.dart';
import 'package:agent_client/features/nanobot/data/nanobot_providers.dart';
import 'package:agent_client/features/nanobot/data/nanobot_ws_client.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_media_attachment.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_message.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_shell_models.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_thread_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class NanobotWorkspacePage extends ConsumerStatefulWidget {
  const NanobotWorkspacePage({super.key});

  @override
  ConsumerState<NanobotWorkspacePage> createState() =>
      _NanobotWorkspacePageState();
}

class _NanobotWorkspacePageState extends ConsumerState<NanobotWorkspacePage> {
  static const _maxImageAttachments = 4;

  final _inputController = TextEditingController();
  final _focusNode = FocusNode();
  final _attachedImages = <NanobotSendMedia>[];
  final _queuedPrompts = <_QueuedPrompt>[];
  var _isPickingImages = false;
  var _isTranscribingVoice = false;
  var _isSearchDialogOpen = false;
  var _queuedPromptCounter = 0;
  String? _composerInlineError;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nanobotWorkspaceControllerProvider);
    final controller = ref.read(nanobotWorkspaceControllerProvider.notifier);
    final voiceRecorder = ref.watch(nanobotVoiceInputRecorderProvider);

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
              attachedImages: _attachedImages,
              queuedPrompts: _queuedPrompts,
              isPickingImages: _isPickingImages,
              isTranscribingVoice: _isTranscribingVoice,
              composerInlineError: _composerInlineError,
              onSend: () => _send(controller),
              onStop: controller.stopActiveTurn,
              onQueueGuidance: _queueGuidance,
              onFlushQueuedPrompt: () => _flushNextQueuedPrompt(controller),
              onSendQueuedPrompt: (prompt) =>
                  _sendQueuedPrompt(controller, prompt),
              onEditQueuedPrompt: _editQueuedPrompt,
              onDeleteQueuedPrompt: _deleteQueuedPrompt,
              onReorderQueuedPrompts: _reorderQueuedPrompts,
              onTranscribeVoice: voiceRecorder == null
                  ? null
                  : () => _transcribeVoice(controller),
              onAttachImages: _pickImageAttachments,
              onRemoveAttachedImage: _removeImageAttachment,
              onWorkspaceAccessMode: controller.applyWorkspaceAccessMode,
              onWorkspaceProjectPath: controller.applyWorkspaceProjectPath,
              onOpenFilePreview: controller.openFilePreview,
              onCloseFilePreview: controller.closeFilePreview,
              onDismissStreamError: controller.dismissStreamError,
              onForkFromMessage: controller.forkFromMessage,
              onOpenSkillDetail: controller.openSkillDetail,
              onCloseSkillDetail: controller.closeSkillDetail,
              onAutomationAction: controller.runAutomationAction,
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

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (!mounted || event is! KeyDownEvent) {
      return false;
    }
    final keyboard = HardwareKeyboard.instance;
    final commandOrControl =
        keyboard.isMetaPressed || keyboard.isControlPressed;
    if (!commandOrControl || keyboard.isAltPressed) {
      return false;
    }
    final controller = ref.read(nanobotWorkspaceControllerProvider.notifier);
    if (keyboard.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.keyO) {
      _closeTopRouteIfPresent();
      unawaited(controller.startNewSession());
      return true;
    }
    if (!keyboard.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.keyK) {
      final state = ref.read(nanobotWorkspaceControllerProvider);
      unawaited(_openSessionSearch(state, controller));
      return true;
    }
    return false;
  }

  void _closeTopRouteIfPresent() {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _openSessionSearch(
    NanobotWorkspaceState state,
    NanobotWorkspaceController controller,
  ) async {
    if (_isSearchDialogOpen) {
      return;
    }
    _isSearchDialogOpen = true;
    try {
      final selected = await showDialog<NanobotSessionSummary>(
        context: context,
        builder: (context) => _SessionSearchDialog(state: state),
      );
      if (!mounted || selected == null) {
        return;
      }
      controller.selectSession(selected);
    } finally {
      _isSearchDialogOpen = false;
    }
  }

  void _send(NanobotWorkspaceController controller) {
    final input = _inputController.text;
    if (input.trim().isEmpty && _attachedImages.isEmpty) {
      return;
    }
    final media = List<NanobotSendMedia>.unmodifiable(_attachedImages);
    _inputController.clear();
    setState(() {
      _attachedImages.clear();
      _composerInlineError = null;
    });
    unawaited(controller.sendMessage(input, media: media));
    _focusNode.requestFocus();
  }

  void _queueGuidance() {
    final text = _inputController.text.trim();
    if ((text.isEmpty && _attachedImages.isEmpty) ||
        text.trimLeft().startsWith('/')) {
      return;
    }
    final media = List<NanobotSendMedia>.unmodifiable(_attachedImages);
    setState(() {
      _queuedPromptCounter += 1;
      _queuedPrompts.add(
        _QueuedPrompt(
          id: 'queued-prompt-$_queuedPromptCounter',
          text: text,
          media: media,
        ),
      );
      _attachedImages.clear();
      _composerInlineError = null;
    });
    _inputController.clear();
    _focusNode.requestFocus();
  }

  void _flushNextQueuedPrompt(NanobotWorkspaceController controller) {
    if (_queuedPrompts.isEmpty) {
      return;
    }
    final next = _queuedPrompts.firstWhere(
      (prompt) => prompt.text.trim().isNotEmpty || prompt.media.isNotEmpty,
      orElse: () => _queuedPrompts.first,
    );
    _sendQueuedPrompt(controller, next);
  }

  void _sendQueuedPrompt(
    NanobotWorkspaceController controller,
    _QueuedPrompt prompt,
  ) {
    setState(() {
      _queuedPrompts.removeWhere((item) => item.id == prompt.id);
    });
    if (prompt.text.trim().isEmpty && prompt.media.isEmpty) {
      return;
    }
    unawaited(controller.sendMessage(prompt.text, media: prompt.media));
    _focusNode.requestFocus();
  }

  void _editQueuedPrompt(_QueuedPrompt prompt) {
    setState(() {
      _queuedPrompts.removeWhere((item) => item.id == prompt.id);
      _attachedImages
        ..clear()
        ..addAll(prompt.media);
      _composerInlineError = null;
    });
    _inputController.text = prompt.text;
    _inputController.selection = TextSelection.collapsed(
      offset: _inputController.text.length,
    );
    _focusNode.requestFocus();
  }

  void _deleteQueuedPrompt(String id) {
    setState(() {
      _queuedPrompts.removeWhere((prompt) => prompt.id == id);
    });
    _focusNode.requestFocus();
  }

  void _reorderQueuedPrompts(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _queuedPrompts.length) {
      return;
    }
    setState(() {
      final targetIndex = newIndex.clamp(0, _queuedPrompts.length - 1);
      final prompt = _queuedPrompts.removeAt(oldIndex);
      _queuedPrompts.insert(targetIndex, prompt);
    });
  }

  Future<void> _transcribeVoice(NanobotWorkspaceController controller) async {
    if (_isTranscribingVoice) {
      return;
    }
    final recorder = ref.read(nanobotVoiceInputRecorderProvider);
    if (recorder == null) {
      return;
    }
    setState(() {
      _isTranscribingVoice = true;
      _composerInlineError = null;
    });
    try {
      final recorded = await recorder.record(context);
      if (recorded == null) {
        return;
      }
      final transcript = (await controller.transcribeAudio(
        recorded.dataUrl,
        durationMs: recorded.durationMs,
      )).trim();
      if (transcript.isEmpty) {
        return;
      }
      final current = _inputController.text;
      final separator =
          current.trim().isEmpty || RegExp(r'[\s\n]$').hasMatch(current)
          ? ''
          : ' ';
      _inputController.text = '$current$separator$transcript';
      _inputController.selection = TextSelection.collapsed(
        offset: _inputController.text.length,
      );
    } on Object catch (error) {
      if (mounted) {
        setState(() => _composerInlineError = _voiceInputErrorMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isTranscribingVoice = false);
        _focusNode.requestFocus();
      }
    }
  }

  Future<void> _pickImageAttachments() async {
    if (_isPickingImages || _attachedImages.length >= _maxImageAttachments) {
      return;
    }
    setState(() => _isPickingImages = true);
    try {
      final picked = await ref
          .read(nanobotImageAttachmentPickerProvider)
          .pickImages();
      if (!mounted || picked.isEmpty) {
        return;
      }
      setState(() {
        final remaining = _maxImageAttachments - _attachedImages.length;
        final accepted = <NanobotSendMedia>[];
        String? rejection;
        for (final media in picked) {
          if (!_isSupportedComposerImage(media.dataUrl)) {
            rejection ??= 'Unsupported file type';
            continue;
          }
          if (accepted.length >= remaining) {
            rejection ??= 'Max $_maxImageAttachments images per message';
            continue;
          }
          accepted.add(media);
        }
        _composerInlineError = rejection;
        _attachedImages.addAll(accepted);
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to attach image: $error')));
    } finally {
      if (mounted) {
        setState(() => _isPickingImages = false);
      }
    }
  }

  void _removeImageAttachment(int index) {
    if (index < 0 || index >= _attachedImages.length) {
      return;
    }
    setState(() {
      _attachedImages.removeAt(index);
      _composerInlineError = null;
    });
  }
}

class _QueuedPrompt {
  const _QueuedPrompt({
    required this.id,
    required this.text,
    required this.media,
  });

  final String id;
  final String text;
  final List<NanobotSendMedia> media;
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
                  label: 'Skills',
                  icon: Icons.extension_outlined,
                  selected: state.activeView == NanobotShellView.skills,
                  onTap: onOpenSkills,
                ),
                _ShellNavTile(
                  label: 'Automations',
                  icon: Icons.schedule_outlined,
                  selected: state.activeView == NanobotShellView.automations,
                  onTap: onOpenAutomations,
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
                        'No sessions yet.',
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
                        showPreview: state.sidebarState.showPreviews,
                        showTimestamp: state.sidebarState.showTimestamps,
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
    required this.showPreview,
    required this.showTimestamp,
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
  final bool showPreview;
  final bool showTimestamp;
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
                if (showPreview &&
                    session.preview.trim().isNotEmpty &&
                    session.preview.trim().toLowerCase() !=
                        title.trim().toLowerCase()) ...[
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
                if (showTimestamp) ...[
                  const SizedBox(height: 4),
                  Text(
                    _relativeTimeLabel(session.updatedAt ?? session.createdAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
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

  static String _relativeTimeLabel(DateTime? value) {
    if (value == null) {
      return '';
    }
    final difference = DateTime.now().difference(value);
    final abs = difference.abs();
    final suffix = difference.isNegative ? 'from now' : 'ago';
    if (abs.inMinutes < 1) {
      return '${abs.inSeconds}s $suffix';
    }
    if (abs.inHours < 1) {
      return '${abs.inMinutes}m $suffix';
    }
    if (abs.inDays < 1) {
      return '${abs.inHours}h $suffix';
    }
    if (abs.inDays < 7) {
      return '${abs.inDays}d $suffix';
    }
    if (abs.inDays < 30) {
      return '${abs.inDays ~/ 7}w $suffix';
    }
    if (abs.inDays < 365) {
      return '${abs.inDays ~/ 30}mo $suffix';
    }
    return '${abs.inDays ~/ 365}y $suffix';
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
  static const _estimatedResultTileExtent = 72.0;

  final _queryController = TextEditingController();
  final _scrollController = ScrollController();
  var _highlightedIndex = 0;

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryController.text.trim().toLowerCase();
    final results = _searchResults(query);
    final emptyLabel = query.isEmpty
        ? 'No sessions yet.'
        : 'No matching chats.';
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: Focus(
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) {
            return KeyEventResult.ignored;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _moveHighlight(1);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _moveHighlight(-1);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _selectHighlightedResult();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: _queryController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
          onChanged: (_) => setState(() => _highlightedIndex = 0),
          onSubmitted: (_) => _selectHighlightedResult(),
        ),
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
                  ? Center(
                      child: Text(
                        emptyLabel,
                        style: const TextStyle(color: AppThemeTokens.mutedText),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final session = results[index];
                        final title = widget.state.displayTitleFor(session);
                        final preview = session.preview.trim();
                        final showPreview =
                            preview.isNotEmpty &&
                            preview.toLowerCase() != title.trim().toLowerCase();
                        return MouseRegion(
                          onEnter: (_) =>
                              setState(() => _highlightedIndex = index),
                          child: ListTile(
                            selected:
                                index == _clampedHighlightedIndex(results),
                            title: Text(title),
                            subtitle: showPreview ? Text(preview) : null,
                            trailing:
                                session.key == widget.state.selectedSessionKey
                                ? const Text('Current')
                                : null,
                            onTap: () => Navigator.of(context).pop(session),
                          ),
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

  int _clampedHighlightedIndex(List<NanobotSessionSummary> results) {
    if (results.isEmpty) {
      return 0;
    }
    if (_highlightedIndex < 0) {
      return 0;
    }
    if (_highlightedIndex >= results.length) {
      return results.length - 1;
    }
    return _highlightedIndex;
  }

  void _moveHighlight(int delta) {
    final query = _queryController.text.trim().toLowerCase();
    final results = _searchResults(query);
    if (results.isEmpty) {
      return;
    }
    setState(() {
      final current = _clampedHighlightedIndex(results);
      _highlightedIndex = (current + delta + results.length) % results.length;
    });
    _scrollHighlightedResultIntoView(results);
  }

  void _selectHighlightedResult() {
    final query = _queryController.text.trim().toLowerCase();
    final results = _searchResults(query);
    if (results.isEmpty) {
      return;
    }
    Navigator.of(context).pop(results[_clampedHighlightedIndex(results)]);
  }

  void _scrollHighlightedResultIntoView(List<NanobotSessionSummary> results) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients || results.isEmpty) {
        return;
      }
      final position = _scrollController.position;
      final currentOffset = position.pixels;
      final itemTop =
          _clampedHighlightedIndex(results) * _estimatedResultTileExtent;
      final itemBottom = itemTop + _estimatedResultTileExtent;
      final viewportTop = currentOffset;
      final viewportBottom = currentOffset + position.viewportDimension;
      var targetOffset = currentOffset;
      if (itemTop < viewportTop) {
        targetOffset = itemTop;
      } else if (itemBottom > viewportBottom) {
        targetOffset = itemBottom - position.viewportDimension;
      }
      if (targetOffset == currentOffset) {
        return;
      }
      _scrollController.jumpTo(
        targetOffset.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    });
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
    required this.attachedImages,
    required this.queuedPrompts,
    required this.isPickingImages,
    required this.isTranscribingVoice,
    required this.composerInlineError,
    required this.onSend,
    required this.onStop,
    required this.onQueueGuidance,
    required this.onFlushQueuedPrompt,
    required this.onSendQueuedPrompt,
    required this.onEditQueuedPrompt,
    required this.onDeleteQueuedPrompt,
    required this.onReorderQueuedPrompts,
    required this.onTranscribeVoice,
    required this.onAttachImages,
    required this.onRemoveAttachedImage,
    required this.onWorkspaceAccessMode,
    required this.onWorkspaceProjectPath,
    required this.onOpenFilePreview,
    required this.onCloseFilePreview,
    required this.onDismissStreamError,
    required this.onForkFromMessage,
    required this.onOpenSkillDetail,
    required this.onCloseSkillDetail,
    required this.onAutomationAction,
    required this.onOpenSettings,
    required this.onRefresh,
    this.onOpenSessions,
  });

  final NanobotWorkspaceState state;
  final TextEditingController inputController;
  final FocusNode focusNode;
  final List<NanobotSendMedia> attachedImages;
  final List<_QueuedPrompt> queuedPrompts;
  final bool isPickingImages;
  final bool isTranscribingVoice;
  final String? composerInlineError;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final VoidCallback onQueueGuidance;
  final VoidCallback onFlushQueuedPrompt;
  final ValueChanged<_QueuedPrompt> onSendQueuedPrompt;
  final ValueChanged<_QueuedPrompt> onEditQueuedPrompt;
  final ValueChanged<String> onDeleteQueuedPrompt;
  final void Function(int oldIndex, int newIndex) onReorderQueuedPrompts;
  final VoidCallback? onTranscribeVoice;
  final VoidCallback onAttachImages;
  final ValueChanged<int> onRemoveAttachedImage;
  final ValueChanged<String> onWorkspaceAccessMode;
  final Future<void> Function(String path, {String? projectName})
  onWorkspaceProjectPath;
  final ValueChanged<String> onOpenFilePreview;
  final VoidCallback onCloseFilePreview;
  final VoidCallback onDismissStreamError;
  final Future<void> Function(int beforeUserIndex) onForkFromMessage;
  final Future<void> Function(NanobotCatalogItem item) onOpenSkillDetail;
  final VoidCallback onCloseSkillDetail;
  final Future<void> Function(
    NanobotAutomationAction action,
    NanobotCatalogItem item,
  )
  onAutomationAction;
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
                    onForkFromMessage: onForkFromMessage,
                  )
                : _SecondarySurface(
                    state: state,
                    onOpenSkillDetail: onOpenSkillDetail,
                    onCloseSkillDetail: onCloseSkillDetail,
                    onAutomationAction: onAutomationAction,
                  ),
          ),
          if (state.errorMessage != null)
            _InlineError(text: state.errorMessage!, onRetry: onRefresh),
          if (state.activeView == NanobotShellView.chat &&
              state.streamError != null)
            _StreamErrorNotice(
              error: state.streamError!,
              onDismiss: onDismissStreamError,
            ),
          if (state.activeView == NanobotShellView.chat)
            _InputBar(
              controller: inputController,
              focusNode: focusNode,
              canSend: state.canSend,
              isStreaming: state.isStreaming,
              runStartedAt: state.threadState?.runStartedAt,
              goalState: state.threadState?.goalState,
              attachedImages: attachedImages,
              queuedPrompts: queuedPrompts,
              isPickingImages: isPickingImages,
              isTranscribingVoice: isTranscribingVoice,
              inlineError: composerInlineError,
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
              onQueueGuidance: onQueueGuidance,
              onFlushQueuedPrompt: onFlushQueuedPrompt,
              onSendQueuedPrompt: onSendQueuedPrompt,
              onEditQueuedPrompt: onEditQueuedPrompt,
              onDeleteQueuedPrompt: onDeleteQueuedPrompt,
              onReorderQueuedPrompts: onReorderQueuedPrompts,
              onTranscribeVoice: onTranscribeVoice,
              onAttachImages: onAttachImages,
              onRemoveAttachedImage: onRemoveAttachedImage,
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
  const _SecondarySurface({
    required this.state,
    required this.onOpenSkillDetail,
    required this.onCloseSkillDetail,
    required this.onAutomationAction,
  });

  final NanobotWorkspaceState state;
  final Future<void> Function(NanobotCatalogItem item) onOpenSkillDetail;
  final VoidCallback onCloseSkillDetail;
  final Future<void> Function(
    NanobotAutomationAction action,
    NanobotCatalogItem item,
  )
  onAutomationAction;

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
          emptyText: 'No apps match this filter.',
          items: state.appItems,
        ),
        NanobotShellView.automations => _CatalogSurface(
          title: 'Automations',
          emptyText: 'No automations yet.',
          items: state.automationItems,
          searchable: true,
          searchPlaceholder: 'Search task, message, linked chat, or schedule',
          noMatchesText: 'No automations match this view.',
          onAutomationAction: onAutomationAction,
        ),
        NanobotShellView.skills => _CatalogSurface(
          title: 'Skills',
          emptyText: 'No skills are available.',
          items: state.skillItems,
          onItemSelected: (item) => _showSkillDetail(context, item),
        ),
        NanobotShellView.chat => const SizedBox.shrink(),
      },
    );
  }

  Future<void> _showSkillDetail(BuildContext context, NanobotCatalogItem item) {
    unawaited(onOpenSkillDetail(item));
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(nanobotWorkspaceControllerProvider);
              return _SkillDetailSheet(
                summary: state.selectedSkillItem ?? item,
                detail: state.selectedSkillDetail,
                isLoading: state.isLoadingSkillDetail,
                error: state.skillDetailError,
              );
            },
          ),
        );
      },
    ).whenComplete(onCloseSkillDetail);
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

class _SkillDetailSheet extends StatelessWidget {
  const _SkillDetailSheet({
    required this.summary,
    required this.detail,
    required this.isLoading,
    required this.error,
  });

  final NanobotCatalogItem summary;
  final NanobotSkillDetail? detail;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final activeDetail = detail;
    final title = activeDetail?.name ?? summary.title;
    final description = activeDetail?.description ?? summary.subtitle;
    final source = _skillSourceLabel(activeDetail?.source ?? '');
    final status = activeDetail == null
        ? summary.status
        : activeDetail.available
        ? 'Available'
        : 'Unavailable';
    final unavailableReason =
        activeDetail?.unavailableReason ?? _skillUnavailableReason(summary);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppThemeTokens.headingText,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isLoading) ...[
            const SizedBox(height: 20),
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text(
                  'Loading skill details...',
                  style: TextStyle(color: AppThemeTokens.mutedText),
                ),
              ],
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 20),
            _InlineError(text: error!, onRetry: () {}),
          ],
          const SizedBox(height: 20),
          const _DetailHeading('Description'),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppThemeTokens.mutedText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SkillMetaItem(label: 'Source', value: source),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SkillMetaItem(label: 'Status', value: status),
              ),
            ],
          ),
          if (unavailableReason != null) ...[
            const SizedBox(height: 20),
            const _DetailHeading('Unavailable reason'),
            const SizedBox(height: 8),
            Text(
              unavailableReason,
              style: const TextStyle(
                color: AppThemeTokens.brandPressed,
                height: 1.4,
              ),
            ),
          ],
          if (activeDetail != null) ...[
            const SizedBox(height: 20),
            _SkillRequirements(detail: activeDetail),
            const SizedBox(height: 20),
            _RawSkillMarkdown(markdown: activeDetail.rawMarkdown),
          ],
        ],
      ),
    );
  }

  static String _skillSourceLabel(String source) {
    return switch (source) {
      'workspace' => 'Custom',
      'builtin' => 'Built-in',
      '' => 'unknown',
      _ => source,
    };
  }

  static String? _skillUnavailableReason(NanobotCatalogItem item) {
    const prefix = 'Missing: ';
    final status = item.status.trim();
    if (!status.startsWith(prefix)) {
      return null;
    }
    final reason = status.substring(prefix.length).trim();
    return reason.isEmpty ? null : reason;
  }
}

class _SkillMetaItem extends StatelessWidget {
  const _SkillMetaItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppThemeTokens.workspaceAlt,
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppThemeTokens.mutedText,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppThemeTokens.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillRequirements extends StatelessWidget {
  const _SkillRequirements({required this.detail});

  final NanobotSkillDetail detail;

  @override
  Widget build(BuildContext context) {
    final hasRequirements = detail.bins.isNotEmpty || detail.env.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DetailHeading('Requirements'),
        const SizedBox(height: 10),
        if (!hasRequirements)
          const Text(
            'No explicit requirements.',
            style: TextStyle(color: AppThemeTokens.mutedText, fontSize: 13),
          )
        else ...[
          if (detail.missingBins.isNotEmpty)
            _RequirementLine(
              title: 'Missing CLI',
              values: detail.missingBins,
              danger: true,
            ),
          if (detail.missingEnv.isNotEmpty)
            _RequirementLine(
              title: 'Missing ENV',
              values: detail.missingEnv,
              danger: true,
            ),
          if (detail.bins.isNotEmpty)
            _RequirementLine(title: 'Commands', values: detail.bins),
          if (detail.env.isNotEmpty)
            _RequirementLine(
              title: 'Environment variables',
              values: detail.env,
            ),
        ],
      ],
    );
  }
}

class _RequirementLine extends StatelessWidget {
  const _RequirementLine({
    required this.title,
    required this.values,
    this.danger = false,
  });

  final String title;
  final List<String> values;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: danger
                  ? AppThemeTokens.brandPressed
                  : AppThemeTokens.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final value in values) _SkillPill(value)],
          ),
        ],
      ),
    );
  }
}

class _SkillPill extends StatelessWidget {
  const _SkillPill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppThemeTokens.workspaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: AppThemeTokens.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _RawSkillMarkdown extends StatelessWidget {
  const _RawSkillMarkdown({required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final content = markdown.trim().isEmpty ? 'No raw instructions.' : markdown;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppThemeTokens.border),
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: const Text(
          'Raw SKILL.md',
          style: TextStyle(
            color: AppThemeTokens.headingText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(
              content,
              style: const TextStyle(
                color: AppThemeTokens.mutedText,
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogSurface extends StatelessWidget {
  const _CatalogSurface({
    required this.title,
    required this.emptyText,
    required this.items,
    this.searchable = false,
    this.searchPlaceholder = '',
    this.noMatchesText,
    this.onItemSelected,
    this.onAutomationAction,
  });

  final String title;
  final String emptyText;
  final List<NanobotCatalogItem> items;
  final bool searchable;
  final String searchPlaceholder;
  final String? noMatchesText;
  final ValueChanged<NanobotCatalogItem>? onItemSelected;
  final Future<void> Function(
    NanobotAutomationAction action,
    NanobotCatalogItem item,
  )?
  onAutomationAction;

  @override
  Widget build(BuildContext context) {
    if (searchable) {
      return _SearchableCatalogSurface(
        title: title,
        emptyText: emptyText,
        items: items,
        searchPlaceholder: searchPlaceholder,
        noMatchesText: noMatchesText ?? emptyText,
        onItemSelected: onItemSelected,
        onAutomationAction: onAutomationAction,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SurfaceTitle(title),
        const SizedBox(height: 16),
        if (items.isEmpty)
          _EmptySurface(text: emptyText)
        else
          for (final item in items)
            _CatalogRow(
              key: ValueKey(item.id),
              item: item,
              onSelected: onItemSelected,
              onAutomationAction: onAutomationAction,
            ),
      ],
    );
  }
}

class _SearchableCatalogSurface extends StatefulWidget {
  const _SearchableCatalogSurface({
    required this.title,
    required this.emptyText,
    required this.items,
    required this.searchPlaceholder,
    required this.noMatchesText,
    required this.onItemSelected,
    required this.onAutomationAction,
  });

  final String title;
  final String emptyText;
  final List<NanobotCatalogItem> items;
  final String searchPlaceholder;
  final String noMatchesText;
  final ValueChanged<NanobotCatalogItem>? onItemSelected;
  final Future<void> Function(
    NanobotAutomationAction action,
    NanobotCatalogItem item,
  )?
  onAutomationAction;

  @override
  State<_SearchableCatalogSurface> createState() =>
      _SearchableCatalogSurfaceState();
}

class _SearchableCatalogSurfaceState extends State<_SearchableCatalogSurface> {
  final _queryController = TextEditingController();
  var _activeFilter = 'all';
  var _activeSort = 'next';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryController.text.trim();
    final sortedItems = _sortItems(widget.items, _activeSort);
    final visibleItems = [
      for (final item in sortedItems)
        if (_matchesFilter(item, _activeFilter) &&
            (query.isEmpty || _matches(item, query)))
          item,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SurfaceTitle(widget.title),
        const SizedBox(height: 16),
        _AutomationFilterChips(
          items: widget.items,
          selected: _activeFilter,
          onSelected: (filter) => setState(() => _activeFilter = filter),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: PopupMenuButton<String>(
            initialValue: _activeSort,
            position: PopupMenuPosition.under,
            onSelected: (sort) => setState(() => _activeSort = sort),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'next', child: Text('Next run')),
              PopupMenuItem(value: 'last', child: Text('Last run')),
              PopupMenuItem(value: 'updated', child: Text('Updated')),
              PopupMenuItem(value: 'name', child: Text('Name')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppThemeTokens.border),
                borderRadius: BorderRadius.circular(AppThemeTokens.radius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort, size: 18),
                  const SizedBox(width: 8),
                  Text(_sortLabel(_activeSort)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _queryController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: widget.searchPlaceholder,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppThemeTokens.radius),
              borderSide: const BorderSide(color: AppThemeTokens.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppThemeTokens.radius),
              borderSide: const BorderSide(color: AppThemeTokens.border),
            ),
            isDense: true,
          ),
        ),
        const SizedBox(height: 16),
        if (widget.items.isEmpty)
          _EmptySurface(text: widget.emptyText)
        else if (visibleItems.isEmpty)
          _EmptySurface(text: widget.noMatchesText)
        else
          for (final item in visibleItems)
            _CatalogRow(
              key: ValueKey(item.id),
              item: item,
              onSelected: widget.onItemSelected,
              onAutomationAction: widget.onAutomationAction,
            ),
      ],
    );
  }

  bool _matchesFilter(NanobotCatalogItem item, String filter) {
    if (filter == 'all') {
      return true;
    }
    if (item.filterKeys.isEmpty && filter == 'active') {
      return true;
    }
    return item.filterKeys.contains(filter);
  }

  bool _matches(NanobotCatalogItem item, String query) {
    final haystack = [
      item.title,
      item.subtitle,
      item.details,
      item.status,
    ].join('\n').toLowerCase();
    final tokens = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty);
    return tokens.every(haystack.contains);
  }

  List<NanobotCatalogItem> _sortItems(
    List<NanobotCatalogItem> items,
    String sort,
  ) {
    final sorted = [...items];
    sorted.sort((left, right) {
      final bySort = switch (sort) {
        'last' => _compareNullableIntDesc(left.lastRunAtMs, right.lastRunAtMs),
        'updated' => _compareNullableIntDesc(
          left.updatedAtMs,
          right.updatedAtMs,
        ),
        'name' => 0,
        _ => _compareNullableIntAsc(left.nextRunAtMs, right.nextRunAtMs),
      };
      if (bySort != 0) {
        return bySort;
      }
      return _compareByName(left, right);
    });
    return sorted;
  }

  int _compareNullableIntAsc(int? left, int? right) {
    if (left == null && right == null) {
      return 0;
    }
    if (left == null) {
      return 1;
    }
    if (right == null) {
      return -1;
    }
    return left.compareTo(right);
  }

  int _compareNullableIntDesc(int? left, int? right) {
    if (left == null && right == null) {
      return 0;
    }
    if (left == null) {
      return 1;
    }
    if (right == null) {
      return -1;
    }
    return right.compareTo(left);
  }

  int _compareByName(NanobotCatalogItem left, NanobotCatalogItem right) {
    final leftName = (left.title.trim().isEmpty ? left.id : left.title)
        .toLowerCase();
    final rightName = (right.title.trim().isEmpty ? right.id : right.title)
        .toLowerCase();
    return leftName.compareTo(rightName);
  }

  String _sortLabel(String sort) {
    return switch (sort) {
      'last' => 'Last run',
      'updated' => 'Updated',
      'name' => 'Name',
      _ => 'Next run',
    };
  }
}

class _AutomationFilterChips extends StatelessWidget {
  const _AutomationFilterChips({
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final List<NanobotCatalogItem> items;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = [
      _AutomationFilterOption('all', 'All', items.length),
      _AutomationFilterOption('active', 'Active', _count('active')),
      _AutomationFilterOption('paused', 'Paused', _count('paused')),
      _AutomationFilterOption('failed', 'Needs attention', _count('failed')),
      _AutomationFilterOption('system', 'System', _count('system')),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text('${option.label} ${option.count}'),
            selected: selected == option.key,
            onSelected: (_) => onSelected(option.key),
          ),
      ],
    );
  }

  int _count(String key) {
    return items
        .where(
          (item) =>
              item.filterKeys.contains(key) ||
              (key == 'active' && item.filterKeys.isEmpty),
        )
        .length;
  }
}

class _AutomationFilterOption {
  const _AutomationFilterOption(this.key, this.label, this.count);

  final String key;
  final String label;
  final int count;
}

class _CatalogRow extends StatelessWidget {
  const _CatalogRow({
    super.key,
    required this.item,
    this.onSelected,
    this.onAutomationAction,
  });

  final NanobotCatalogItem item;
  final ValueChanged<NanobotCatalogItem>? onSelected;
  final Future<void> Function(
    NanobotAutomationAction action,
    NanobotCatalogItem item,
  )?
  onAutomationAction;

  @override
  Widget build(BuildContext context) {
    final content = Container(
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
                  _ExpandableCatalogText(
                    text: item.subtitle,
                    collapsedLabel: 'Show full message',
                    expandedLabel: 'Show less',
                  ),
                ],
                if (item.details.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppThemeTokens.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
          if (onAutomationAction != null) ...[
            const SizedBox(width: 8),
            _AutomationActionButtons(item: item, onAction: onAutomationAction!),
          ],
        ],
      ),
    );
    final onTap = onSelected;
    if (onTap == null) {
      return content;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
        onTap: () => onTap(item),
        child: content,
      ),
    );
  }
}

class _AutomationActionButtons extends StatelessWidget {
  const _AutomationActionButtons({required this.item, required this.onAction});

  final NanobotCatalogItem item;
  final Future<void> Function(
    NanobotAutomationAction action,
    NanobotCatalogItem item,
  )
  onAction;

  @override
  Widget build(BuildContext context) {
    if (item.filterKeys.contains('system')) {
      return const Text(
        'Protected',
        style: TextStyle(color: AppThemeTokens.mutedText, fontSize: 12),
      );
    }
    final paused =
        item.filterKeys.contains('paused') ||
        item.status.toLowerCase() == 'disabled';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: paused ? 'Resume' : 'Pause',
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onPressed: () => onAction(
            paused
                ? NanobotAutomationAction.enable
                : NanobotAutomationAction.disable,
            item,
          ),
          icon: Icon(
            paused ? Icons.play_circle_outline : Icons.pause_circle_outline,
          ),
        ),
        PopupMenuButton<NanobotAutomationAction>(
          tooltip: 'Automation actions',
          position: PopupMenuPosition.under,
          onSelected: (action) => onAction(action, item),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: NanobotAutomationAction.run,
              enabled: !paused,
              child: const Text('Run now'),
            ),
            const PopupMenuItem(
              value: NanobotAutomationAction.delete,
              child: Text('Delete'),
            ),
          ],
          child: const SizedBox.square(
            dimension: 36,
            child: Icon(Icons.more_horiz),
          ),
        ),
      ],
    );
  }
}

class _ExpandableCatalogText extends StatefulWidget {
  const _ExpandableCatalogText({
    required this.text,
    required this.collapsedLabel,
    required this.expandedLabel,
  });

  final String text;
  final String collapsedLabel;
  final String expandedLabel;

  @override
  State<_ExpandableCatalogText> createState() => _ExpandableCatalogTextState();
}

class _ExpandableCatalogTextState extends State<_ExpandableCatalogText> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final canExpand =
        widget.text.contains('\n') || widget.text.trim().length > 180;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: canExpand && !_expanded ? 6 : null,
          overflow: canExpand && !_expanded
              ? TextOverflow.ellipsis
              : TextOverflow.visible,
          style: const TextStyle(
            color: AppThemeTokens.mutedText,
            fontSize: 12,
            height: 1.35,
          ),
        ),
        if (canExpand) ...[
          const SizedBox(height: 4),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? widget.expandedLabel : widget.collapsedLabel,
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailHeading extends StatelessWidget {
  const _DetailHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppThemeTokens.headingText,
        fontSize: 13,
        fontWeight: FontWeight.w700,
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
    required this.onForkFromMessage,
  });

  final NanobotWorkspaceState state;
  final ValueChanged<String> onOpenFilePreview;
  final VoidCallback onCloseFilePreview;
  final Future<void> Function(int beforeUserIndex) onForkFromMessage;

  @override
  Widget build(BuildContext context) {
    final previewPath = state.filePreviewPath;
    return Stack(
      children: [
        Positioned.fill(
          child: _MessageList(
            state: state,
            onOpenFilePreview: onOpenFilePreview,
            onForkFromMessage: onForkFromMessage,
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
  const _MessageList({
    required this.state,
    required this.onOpenFilePreview,
    required this.onForkFromMessage,
  });

  final NanobotWorkspaceState state;
  final ValueChanged<String> onOpenFilePreview;
  final Future<void> Function(int beforeUserIndex) onForkFromMessage;

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
          final entryIndex = threadEntries.length - 1 - index;
          final entry = threadEntries[entryIndex];
          final forkIndex = _assistantActionsVisible(threadEntries, entryIndex)
              ? state.threadState!.userMessageOffset +
                    _userCountBeforeThreadEntry(threadEntries, entryIndex)
              : null;
          return RepaintBoundary(
            key: ValueKey(entry.id),
            child: _ThreadEntryBubble(
              entry: entry,
              onOpenFilePreview: onOpenFilePreview,
              onForkFromHere: forkIndex == null
                  ? null
                  : () => onForkFromMessage(forkIndex),
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
        final forkIndex =
            _assistantMessageActionsVisible(state.messages, messageIndex)
            ? _userCountBeforeMessage(state.messages, messageIndex)
            : null;
        return RepaintBoundary(
          key: ValueKey(message.id),
          child: _MessageBubble(
            message: message,
            onOpenFilePreview: onOpenFilePreview,
            onForkFromHere: forkIndex == null
                ? null
                : () => onForkFromMessage(forkIndex),
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

bool _assistantActionsVisible(List<NanobotThreadEntry> entries, int index) {
  final entry = entries[index];
  if (!_showsAssistantActions(
    role: entry.role,
    isStreaming: entry.isStreaming,
    content: entry.content,
  )) {
    return false;
  }
  if (index + 1 >= entries.length) {
    return true;
  }
  return entries[index + 1].role == NanobotThreadRole.user;
}

int _userCountBeforeThreadEntry(List<NanobotThreadEntry> entries, int index) {
  var count = 0;
  for (var i = 0; i < index; i += 1) {
    if (entries[i].role == NanobotThreadRole.user) {
      count += 1;
    }
  }
  return count;
}

bool _assistantMessageActionsVisible(List<NanobotMessage> messages, int index) {
  final message = messages[index];
  if (!_showsAssistantActions(
    role: message.role,
    isStreaming: message.status == NanobotMessageStatus.streaming,
    content: message.content,
  )) {
    return false;
  }
  if (index + 1 >= messages.length) {
    return true;
  }
  return messages[index + 1].role == NanobotMessageRole.user;
}

int _userCountBeforeMessage(List<NanobotMessage> messages, int index) {
  var count = 0;
  for (var i = 0; i < index; i += 1) {
    if (messages[i].role == NanobotMessageRole.user) {
      count += 1;
    }
  }
  return count;
}

bool _showsAssistantActions({
  required Object role,
  required bool isStreaming,
  required String content,
}) {
  final isAssistant =
      role == NanobotThreadRole.assistant ||
      role == NanobotMessageRole.assistant;
  return isAssistant && !isStreaming && content.trim().isNotEmpty;
}

class _ThreadEntryBubble extends StatelessWidget {
  const _ThreadEntryBubble({
    required this.entry,
    required this.onOpenFilePreview,
    this.onForkFromHere,
  });

  final NanobotThreadEntry entry;
  final ValueChanged<String> onOpenFilePreview;
  final Future<void> Function()? onForkFromHere;

  @override
  Widget build(BuildContext context) {
    return switch (entry.kind) {
      NanobotThreadEntryKind.message => _ThreadMessageBubble(
        entry: entry,
        onOpenFilePreview: onOpenFilePreview,
        onForkFromHere: onForkFromHere,
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
    this.onForkFromHere,
  });

  final NanobotThreadEntry entry;
  final ValueChanged<String> onOpenFilePreview;
  final Future<void> Function()? onForkFromHere;

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
              if (entry.media.isNotEmpty) ...[
                if (entry.content.trim().isNotEmpty ||
                    entry.reasoning?.trim().isNotEmpty == true)
                  const SizedBox(height: 8),
                _MessageMediaRow(media: entry.media),
              ],
              if (_showsAssistantActions(
                role: entry.role,
                isStreaming: entry.isStreaming,
                content: entry.content,
              )) ...[
                const SizedBox(height: 8),
                _AssistantMessageActions(
                  content: entry.content,
                  onForkFromHere: onForkFromHere,
                ),
              ],
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

class _MessageContentText extends ConsumerWidget {
  const _MessageContentText({
    required this.text,
    required this.textColor,
    required this.onOpenFilePreview,
  });

  final String text;
  final Color textColor;
  final ValueChanged<String> onOpenFilePreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocks = _messageContentBlocks(text);
    if (blocks.length == 1 &&
        blocks.single.code == null &&
        blocks.single.heading == null &&
        blocks.single.quote == null &&
        blocks.single.table == null &&
        blocks.single.details == null &&
        blocks.single.math == null &&
        !blocks.single.horizontalRule) {
      return _buildInlineContent(text, ref);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final block in blocks) ...[
          _buildContentBlock(block, ref),
          if (block != blocks.last) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildContentBlock(_MessageContentBlock block, WidgetRef ref) {
    if (block.heading != null) {
      return _MessageHeading(text: block.heading!, level: block.headingLevel);
    }
    if (block.table != null) {
      return _MessageTableBlock(
        table: block.table!,
        cellBuilder: (cell) => _buildInlineSegments(cell, ref),
      );
    }
    if (block.horizontalRule) {
      return const Divider(
        key: ValueKey('nanobot-markdown-horizontal-rule'),
        color: AppThemeTokens.border,
        height: 18,
      );
    }
    if (block.quote != null) {
      return _MessageQuoteBlock(
        quote: block.quote!,
        itemBuilder: (line) => _buildInlineSegments(line, ref),
      );
    }
    if (block.details != null) {
      return _MessageDetailsBlock(
        details: block.details!,
        itemBuilder: (nestedBlock) => _buildContentBlock(nestedBlock, ref),
      );
    }
    if (block.math != null) {
      return _MessageMathBlock(math: block.math!);
    }
    if (block.code != null) {
      return _MessageCodeBlock(
        language: block.language,
        code: block.code!,
        textColor: textColor,
      );
    }
    return _buildInlineContent(block.text, ref);
  }

  Widget _buildInlineContent(String value, WidgetRef ref) {
    final list = _markdownBulletList(value);
    if (list != null) {
      return _MessageBulletList(
        prefix: list.prefix,
        markers: list.markers,
        checks: list.checks,
        items: list.items,
        isStandaloneItem: (item) => _compactLinkPreview(item) != null,
        itemBuilder: (item) => _buildListItem(item, ref),
      );
    }
    return _buildInlineSegments(value, ref);
  }

  Widget _buildListItem(String value, WidgetRef ref) {
    final preview = _compactLinkPreview(value);
    if (preview != null) {
      return _CompactLinkPreviewRow(preview: preview);
    }
    return _buildInlineSegments(value, ref);
  }

  Widget _buildInlineSegments(String value, WidgetRef ref) {
    final mathParts = _inlineMathParts(value);
    if (mathParts != null) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final part in mathParts)
            if (part.math != null)
              _InlineMath(expression: part.math!)
            else if (part.text.isNotEmpty)
              _InlineFormattedText(text: part.text, color: textColor),
        ],
      );
    }

    final segments = _messageContentSegments(value);
    if (segments.length == 1 && segments.single.isPlainText) {
      return _InlineFormattedText(text: value, color: textColor);
    }
    final mediaBaseUrl = ref.watch(nanobotConfigProvider).baseUrl;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final segment in segments)
          if (segment.attachment != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _MediaAttachmentTile(
                attachment: segment.attachment!,
                mediaBaseUrl: mediaBaseUrl,
              ),
            )
          else if (segment.filePath != null)
            _InlineFileReferenceChip(
              label: segment.text,
              path: segment.filePath!,
              onOpenFilePreview: onOpenFilePreview,
            )
          else if (segment.href != null)
            _InlineMarkdownLink(label: segment.text, href: segment.href!)
          else
            _InlineFormattedText(text: segment.text, color: textColor),
      ],
    );
  }
}

class _MessageMathBlock extends StatelessWidget {
  const _MessageMathBlock({required this.math});

  final _MarkdownMath math;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('nanobot-markdown-display-math'),
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Math.tex(
          math.expression,
          mathStyle: MathStyle.display,
          textStyle: const TextStyle(color: AppThemeTokens.text, fontSize: 16),
          onErrorFallback: (error) => Text(
            math.expression,
            style: const TextStyle(color: AppThemeTokens.text, height: 1.4),
          ),
        ),
      ),
    );
  }
}

class _MessageDetailsBlock extends StatelessWidget {
  const _MessageDetailsBlock({
    required this.details,
    required this.itemBuilder,
  });

  final _MarkdownDetails details;
  final Widget Function(_MessageContentBlock block) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final bodyBlocks = _messageContentBlocks(details.body);
    return Material(
      key: const ValueKey('nanobot-markdown-details'),
      clipBehavior: Clip.antiAlias,
      color: AppThemeTokens.panelMuted.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppThemeTokens.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          iconColor: AppThemeTokens.mutedText,
          collapsedIconColor: AppThemeTokens.mutedText,
          title: Text(
            details.summary,
            style: const TextStyle(
              color: AppThemeTokens.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final block in bodyBlocks) ...[
                  itemBuilder(block),
                  if (block != bodyBlocks.last) const SizedBox(height: 8),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageTableBlock extends StatelessWidget {
  const _MessageTableBlock({required this.table, required this.cellBuilder});

  final _MarkdownTable table;
  final Widget Function(String cell) cellBuilder;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(color: AppThemeTokens.border),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppThemeTokens.panelMuted),
            children: [
              for (final header in table.headers)
                _MessageTableCell(
                  child: Text(
                    header,
                    style: const TextStyle(
                      color: AppThemeTokens.text,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
            ],
          ),
          for (final row in table.rows)
            TableRow(
              children: [
                for (final cell in row)
                  _MessageTableCell(child: cellBuilder(cell)),
              ],
            ),
        ],
      ),
    );
  }
}

class _MessageTableCell extends StatelessWidget {
  const _MessageTableCell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: child,
    );
  }
}

class _MessageHeading extends StatelessWidget {
  const _MessageHeading({required this.text, required this.level});

  final String text;
  final int level;

  @override
  Widget build(BuildContext context) {
    final fontSize = switch (level) {
      1 => 18.0,
      2 => 16.0,
      _ => 14.5,
    };
    return Text(
      text,
      style: TextStyle(
        color: AppThemeTokens.text,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
    );
  }
}

class _MessageQuoteBlock extends StatelessWidget {
  const _MessageQuoteBlock({required this.quote, required this.itemBuilder});

  final String quote;
  final Widget Function(String line) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final lines = quote.split('\n').where((line) => line.isNotEmpty).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppThemeTokens.strongBorder, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final line in lines) ...[
            itemBuilder(line),
            if (line != lines.last) const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _MessageBulletList extends StatelessWidget {
  const _MessageBulletList({
    required this.prefix,
    required this.markers,
    required this.checks,
    required this.items,
    required this.isStandaloneItem,
    required this.itemBuilder,
  });

  final String prefix;
  final List<String> markers;
  final List<bool?> checks;
  final List<String> items;
  final bool Function(String item) isStandaloneItem;
  final Widget Function(String item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefix.trim().isNotEmpty) ...[
          itemBuilder(prefix),
          const SizedBox(height: 6),
        ],
        for (var index = 0; index < items.length; index += 1)
          Padding(
            padding: const EdgeInsets.only(top: 3, bottom: 3),
            child: isStandaloneItem(items[index])
                ? itemBuilder(items[index])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (checks[index] == null)
                        SizedBox(
                          width: 24,
                          child: Text(
                            markers[index],
                            style: const TextStyle(
                              color: AppThemeTokens.mutedText,
                              height: 1.4,
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: 24,
                          height: 22,
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: _MessageTaskStatusMark(
                              checked: checks[index] ?? false,
                            ),
                          ),
                        ),
                      Expanded(child: itemBuilder(items[index])),
                    ],
                  ),
          ),
      ],
    );
  }
}

class _MessageTaskStatusMark extends StatelessWidget {
  const _MessageTaskStatusMark({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: checked ? 'Task complete' : 'Task incomplete',
      container: true,
      child: Container(
        key: const ValueKey('nanobot-markdown-task-mark'),
        width: 16,
        height: 16,
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          color: checked ? AppThemeTokens.brand : Colors.transparent,
          border: Border.all(
            color: checked ? AppThemeTokens.brand : AppThemeTokens.strongBorder,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: checked
            ? const Icon(Icons.check, color: Colors.white, size: 12)
            : null,
      ),
    );
  }
}

class _CompactLinkPreviewRow extends StatelessWidget {
  const _CompactLinkPreviewRow({required this.preview});

  final _CompactLinkPreview preview;

  @override
  Widget build(BuildContext context) {
    final label = preview.prefix == null
        ? preview.title
        : '${preview.prefix} — ${preview.title}';
    final host = Uri.parse(preview.href).host;
    return Semantics(
      label: 'Open link: $label',
      link: true,
      container: true,
      onTap: () => _launchExternalUrl(preview.href),
      child: Tooltip(
        message: preview.href,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _launchExternalUrl(preview.href),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppThemeTokens.workspace,
                    border: Border.all(color: AppThemeTokens.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _CompactLinkFavicon(
                    key: ValueKey(
                      'nanobot-compact-link-favicon:${_faviconUrls(host).first}',
                    ),
                    host: host,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppThemeTokens.brandPressed,
                      height: 1.4,
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

class _InlineMath extends StatelessWidget {
  const _InlineMath({required this.expression});

  final String expression;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('nanobot-markdown-inline-math'),
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Math.tex(
        expression,
        mathStyle: MathStyle.text,
        textStyle: const TextStyle(color: AppThemeTokens.text, fontSize: 14),
        onErrorFallback: (error) => Text(
          expression,
          style: const TextStyle(color: AppThemeTokens.text, height: 1.4),
        ),
      ),
    );
  }
}

class _CompactLinkFavicon extends StatefulWidget {
  const _CompactLinkFavicon({super.key, required this.host});

  final String host;

  @override
  State<_CompactLinkFavicon> createState() => _CompactLinkFaviconState();
}

class _CompactLinkFaviconState extends State<_CompactLinkFavicon> {
  var _candidateIndex = 0;

  @override
  void didUpdateWidget(_CompactLinkFavicon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.host != widget.host) {
      _candidateIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidates = _faviconUrls(widget.host);
    if (_candidateIndex >= candidates.length) {
      return const Icon(
        Icons.public,
        size: 12,
        color: AppThemeTokens.mutedText,
      );
    }
    return Image.network(
      candidates[_candidateIndex],
      width: 12,
      height: 12,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) {
        Future<void>.microtask(() {
          if (mounted) {
            setState(() {
              _candidateIndex += 1;
            });
          }
        });
        return const SizedBox(width: 12, height: 12);
      },
    );
  }
}

List<String> _faviconUrls(String host) {
  final faviconHost = host.split('/').first.trim();
  return [
    'https://$faviconHost/favicon.ico',
    'https://icons.duckduckgo.com/ip3/${Uri.encodeComponent(faviconHost)}.ico',
    'https://www.google.com/s2/favicons?domain=${Uri.encodeComponent(host)}&sz=64',
  ];
}

class _InlineFormattedText extends StatelessWidget {
  const _InlineFormattedText({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final spans = _inlineMarkdownSpans(text, color);
    if (spans == null) {
      return Text(text, style: TextStyle(color: color, height: 1.4));
    }
    return Text.rich(
      TextSpan(children: spans),
      style: TextStyle(color: color, height: 1.4),
    );
  }
}

class _MessageCodeBlock extends StatelessWidget {
  const _MessageCodeBlock({
    required this.language,
    required this.code,
    required this.textColor,
  });

  final String? language;
  final String code;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final label = language?.trim().isNotEmpty == true
        ? language!.trim()
        : 'text';
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppThemeTokens.workspace,
        border: Border.all(color: AppThemeTokens.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
            color: AppThemeTokens.panelMuted,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppThemeTokens.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy code',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                  },
                  icon: const Icon(Icons.copy, size: 16),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(10),
            child: Text(
              code,
              style: TextStyle(
                color: textColor,
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMarkdownLink extends StatelessWidget {
  const _InlineMarkdownLink({required this.label, required this.href});

  final String label;
  final String href;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: label,
      onTap: () => _launchExternalUrl(href),
      child: Tooltip(
        message: href,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _launchExternalUrl(href),
            child: Text(
              label,
              style: const TextStyle(
                color: AppThemeTokens.brandPressed,
                decoration: TextDecoration.underline,
                decorationColor: AppThemeTokens.brandPressed,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _launchExternalUrl(String href) async {
  final uri = Uri.tryParse(href);
  if (uri == null) {
    return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
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
  const _MessageContentSegment.text(this.text)
    : filePath = null,
      href = null,
      attachment = null;
  const _MessageContentSegment.link({required this.text, required this.href})
    : filePath = null,
      attachment = null;
  const _MessageContentSegment.file({
    required this.text,
    required this.filePath,
  }) : href = null,
       attachment = null;
  const _MessageContentSegment.media({required this.attachment})
    : text = '',
      filePath = null,
      href = null;

  final String text;
  final String? filePath;
  final String? href;
  final NanobotMediaAttachment? attachment;

  bool get isPlainText =>
      filePath == null && href == null && attachment == null;
}

class _MessageContentBlock {
  const _MessageContentBlock.text(this.text)
    : language = null,
      code = null,
      heading = null,
      headingLevel = 0,
      quote = null,
      table = null,
      details = null,
      math = null,
      horizontalRule = false;
  const _MessageContentBlock.code({required this.language, required this.code})
    : text = '',
      heading = null,
      headingLevel = 0,
      quote = null,
      table = null,
      details = null,
      math = null,
      horizontalRule = false;
  const _MessageContentBlock.heading({
    required this.heading,
    required this.headingLevel,
  }) : text = '',
       language = null,
       code = null,
       quote = null,
       table = null,
       details = null,
       math = null,
       horizontalRule = false;
  const _MessageContentBlock.quote({required this.quote})
    : text = '',
      language = null,
      code = null,
      heading = null,
      headingLevel = 0,
      table = null,
      details = null,
      math = null,
      horizontalRule = false;
  const _MessageContentBlock.table({required this.table})
    : text = '',
      language = null,
      code = null,
      heading = null,
      headingLevel = 0,
      quote = null,
      details = null,
      math = null,
      horizontalRule = false;
  const _MessageContentBlock.details({required this.details})
    : text = '',
      language = null,
      code = null,
      heading = null,
      headingLevel = 0,
      quote = null,
      table = null,
      math = null,
      horizontalRule = false;
  const _MessageContentBlock.math({required this.math})
    : text = '',
      language = null,
      code = null,
      heading = null,
      headingLevel = 0,
      quote = null,
      table = null,
      details = null,
      horizontalRule = false;
  const _MessageContentBlock.horizontalRule()
    : text = '',
      language = null,
      code = null,
      heading = null,
      headingLevel = 0,
      quote = null,
      table = null,
      details = null,
      math = null,
      horizontalRule = true;

  final String text;
  final String? language;
  final String? code;
  final String? heading;
  final int headingLevel;
  final String? quote;
  final _MarkdownTable? table;
  final _MarkdownDetails? details;
  final _MarkdownMath? math;
  final bool horizontalRule;
}

class _MarkdownDetails {
  const _MarkdownDetails({required this.summary, required this.body});

  final String summary;
  final String body;
}

class _MarkdownMath {
  const _MarkdownMath({required this.expression});

  final String expression;
}

class _MarkdownTable {
  const _MarkdownTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;
}

class _MarkdownBulletList {
  const _MarkdownBulletList({
    required this.prefix,
    required this.markers,
    required this.checks,
    required this.items,
  });

  final String prefix;
  final List<String> markers;
  final List<bool?> checks;
  final List<String> items;
}

class _CompactLinkPreview {
  const _CompactLinkPreview({
    required this.href,
    required this.title,
    this.prefix,
  });

  final String href;
  final String title;
  final String? prefix;
}

List<_MessageContentBlock> _messageContentBlocks(String text) {
  final matches = RegExp(
    r'```([^\n`]*)\n([\s\S]*?)(?:\n```|$)',
    multiLine: true,
  ).allMatches(text).toList();
  if (matches.isEmpty) {
    return _markdownTextBlocks(text);
  }

  final blocks = <_MessageContentBlock>[];
  var cursor = 0;
  for (final match in matches) {
    final prefix = _trimBlockText(text.substring(cursor, match.start));
    if (prefix.isNotEmpty) {
      blocks.addAll(_markdownTextBlocks(prefix));
    }
    blocks.add(
      _MessageContentBlock.code(
        language: (match.group(1) ?? '').trim(),
        code: match.group(2) ?? '',
      ),
    );
    cursor = match.end;
  }
  final suffix = _trimBlockText(text.substring(cursor));
  if (suffix.isNotEmpty) {
    blocks.addAll(_markdownTextBlocks(suffix));
  }
  return blocks.isEmpty ? [_MessageContentBlock.text(text)] : blocks;
}

List<_MessageContentBlock> _markdownTextBlocks(String text) {
  final lines = text.split('\n');
  final blocks = <_MessageContentBlock>[];
  final buffer = <String>[];

  void flushBuffer() {
    final value = _trimBlockText(buffer.join('\n'));
    if (value.isNotEmpty) {
      blocks.add(_MessageContentBlock.text(value));
    }
    buffer.clear();
  }

  var index = 0;
  while (index < lines.length) {
    final line = lines[index];
    final math = _markdownDisplayMathAt(lines, index);
    if (math != null) {
      flushBuffer();
      blocks.add(_MessageContentBlock.math(math: math.math));
      index = math.nextIndex;
      continue;
    }

    final details = _markdownDetailsAt(lines, index);
    if (details != null) {
      flushBuffer();
      blocks.add(_MessageContentBlock.details(details: details.details));
      index = details.nextIndex;
      continue;
    }

    if (_isMarkdownHorizontalRule(line)) {
      flushBuffer();
      blocks.add(const _MessageContentBlock.horizontalRule());
      index += 1;
      continue;
    }

    final table = _markdownTableAt(lines, index);
    if (table != null) {
      flushBuffer();
      blocks.add(_MessageContentBlock.table(table: table.table));
      index = table.nextIndex;
      continue;
    }

    final heading = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(line.trimRight());
    if (heading != null) {
      flushBuffer();
      blocks.add(
        _MessageContentBlock.heading(
          heading: heading.group(2)!.trim(),
          headingLevel: heading.group(1)!.length,
        ),
      );
      index += 1;
      continue;
    }

    if (_isMarkdownQuoteLine(line)) {
      flushBuffer();
      final quoteLines = <String>[];
      while (index < lines.length && _isMarkdownQuoteLine(lines[index])) {
        quoteLines.add(_quoteLineText(lines[index]));
        index += 1;
      }
      blocks.add(_MessageContentBlock.quote(quote: quoteLines.join('\n')));
      continue;
    }

    buffer.add(line);
    index += 1;
  }
  flushBuffer();
  return blocks.isEmpty ? [_MessageContentBlock.text(text)] : blocks;
}

({_MarkdownMath math, int nextIndex})? _markdownDisplayMathAt(
  List<String> lines,
  int index,
) {
  final line = lines[index].trim();
  final texBracket = RegExp(r'^\\\[([\s\S]+)\\\]$').firstMatch(line);
  if (texBracket != null) {
    return (
      math: _MarkdownMath(expression: texBracket.group(1)!.trim()),
      nextIndex: index + 1,
    );
  }
  final dollarBlock = RegExp(r'^\$\$([\s\S]+)\$\$$').firstMatch(line);
  if (dollarBlock != null) {
    return (
      math: _MarkdownMath(expression: dollarBlock.group(1)!.trim()),
      nextIndex: index + 1,
    );
  }
  if (line == r'\[') {
    final body = <String>[];
    var cursor = index + 1;
    while (cursor < lines.length) {
      if (lines[cursor].trim() == r'\]') {
        return (
          math: _MarkdownMath(expression: _trimBlockText(body.join('\n'))),
          nextIndex: cursor + 1,
        );
      }
      body.add(lines[cursor]);
      cursor += 1;
    }
  }
  if (line == r'$$') {
    final body = <String>[];
    var cursor = index + 1;
    while (cursor < lines.length) {
      if (lines[cursor].trim() == r'$$') {
        return (
          math: _MarkdownMath(expression: _trimBlockText(body.join('\n'))),
          nextIndex: cursor + 1,
        );
      }
      body.add(lines[cursor]);
      cursor += 1;
    }
  }
  return null;
}

({_MarkdownDetails details, int nextIndex})? _markdownDetailsAt(
  List<String> lines,
  int index,
) {
  final open = _markdownDetailsOpen(lines[index]);
  if (open == null) {
    return null;
  }
  final body = <String>[];
  var cursor = index + 1;
  while (cursor < lines.length) {
    if (_isMarkdownDetailsClose(lines[cursor])) {
      return (
        details: _MarkdownDetails(
          summary: open.summary,
          body: _trimBlockText(body.join('\n')),
        ),
        nextIndex: cursor + 1,
      );
    }
    body.add(lines[cursor]);
    cursor += 1;
  }
  return null;
}

({String summary})? _markdownDetailsOpen(String line) {
  final value = line.trim();
  final withSummary = RegExp(
    r'^<\s*details\s*>\s*<\s*summary\s*>([\s\S]*?)<\s*/\s*summary\s*>$',
    caseSensitive: false,
  ).firstMatch(value);
  if (withSummary != null) {
    final summary = withSummary.group(1)!.trim();
    return (summary: summary.isEmpty ? 'Details' : summary);
  }
  if (RegExp(r'^<\s*details\s*>$', caseSensitive: false).hasMatch(value)) {
    return (summary: 'Details');
  }
  return null;
}

bool _isMarkdownDetailsClose(String line) {
  return RegExp(
    r'^<\s*/\s*details\s*>$',
    caseSensitive: false,
  ).hasMatch(line.trim());
}

bool _isMarkdownHorizontalRule(String line) {
  final compact = line.trim().replaceAll(' ', '');
  return compact.length >= 3 &&
      (compact.split('').every((char) => char == '-') ||
          compact.split('').every((char) => char == '*') ||
          compact.split('').every((char) => char == '_'));
}

({_MarkdownTable table, int nextIndex})? _markdownTableAt(
  List<String> lines,
  int index,
) {
  if (index + 1 >= lines.length) {
    return null;
  }
  final headers = _pipeTableCells(lines[index]);
  final separator = _pipeTableCells(lines[index + 1]);
  if (headers == null ||
      separator == null ||
      headers.isEmpty ||
      separator.length != headers.length ||
      !separator.every(_isPipeTableSeparatorCell)) {
    return null;
  }

  final rows = <List<String>>[];
  var cursor = index + 2;
  while (cursor < lines.length) {
    final cells = _pipeTableCells(lines[cursor]);
    if (cells == null || cells.isEmpty) {
      break;
    }
    rows.add(_normalizeTableRow(cells, headers.length));
    cursor += 1;
  }
  if (rows.isEmpty) {
    return null;
  }
  return (
    table: _MarkdownTable(headers: headers, rows: rows),
    nextIndex: cursor,
  );
}

List<String>? _pipeTableCells(String line) {
  final trimmed = line.trim();
  if (!trimmed.contains('|')) {
    return null;
  }
  final parts = trimmed.split('|').map((part) => part.trim()).toList();
  if (parts.isNotEmpty && parts.first.isEmpty) {
    parts.removeAt(0);
  }
  if (parts.isNotEmpty && parts.last.isEmpty) {
    parts.removeLast();
  }
  if (parts.length < 2) {
    return null;
  }
  return parts;
}

bool _isPipeTableSeparatorCell(String cell) {
  return RegExp(r'^:?-{3,}:?$').hasMatch(cell);
}

List<String> _normalizeTableRow(List<String> cells, int length) {
  final row = cells.take(length).toList();
  while (row.length < length) {
    row.add('');
  }
  return row;
}

bool _isMarkdownQuoteLine(String line) {
  return line.trimLeft().startsWith('>');
}

String _quoteLineText(String line) {
  final trimmedLeft = line.trimLeft();
  return trimmedLeft.replaceFirst(RegExp(r'^>\s?'), '').trimRight();
}

String _trimBlockText(String text) {
  return text
      .replaceAll(RegExp(r'^\s*\n'), '')
      .replaceAll(RegExp(r'\n\s*$'), '');
}

_MarkdownBulletList? _markdownBulletList(String text) {
  final lines = text.split('\n');
  final firstBullet = lines.indexWhere(
    (line) => _markdownListLine(line) != null,
  );
  if (firstBullet < 0) {
    return null;
  }
  final markers = <String>[];
  final checks = <bool?>[];
  final items = <String>[];
  for (var index = firstBullet; index < lines.length; index += 1) {
    final trimmedLeft = lines[index].trimLeft();
    if (trimmedLeft.isEmpty) {
      continue;
    }
    final line = _markdownListLine(trimmedLeft);
    if (line == null) {
      if (items.isNotEmpty && _isMarkdownListContinuation(lines[index])) {
        items[items.length - 1] = '${items.last}\n${trimmedLeft.trimRight()}';
        continue;
      }
      return null;
    }
    if (line.item.isNotEmpty) {
      markers.add(line.marker);
      checks.add(line.checked);
      items.add(line.item);
    }
  }
  if (items.isEmpty) {
    return null;
  }
  return _MarkdownBulletList(
    prefix: lines.take(firstBullet).join('\n').trimRight(),
    markers: markers,
    checks: checks,
    items: items,
  );
}

({String marker, bool? checked, String item})? _markdownListLine(String line) {
  final trimmedLeft = line.trimLeft();
  final task = RegExp(r'^-\s+\[([ xX])\]\s+(.+)$').firstMatch(trimmedLeft);
  if (task != null) {
    return (
      marker: '',
      checked: task.group(1)!.toLowerCase() == 'x',
      item: task.group(2)!.trimRight(),
    );
  }
  final bullet = RegExp(r'^-\s+(.+)$').firstMatch(trimmedLeft);
  if (bullet != null) {
    return (marker: '•', checked: null, item: bullet.group(1)!.trimRight());
  }
  final ordered = RegExp(r'^(\d+)\.\s+(.+)$').firstMatch(trimmedLeft);
  if (ordered != null) {
    return (
      marker: '${ordered.group(1)}.',
      checked: null,
      item: ordered.group(2)!.trimRight(),
    );
  }
  return null;
}

bool _isMarkdownListContinuation(String line) {
  return line.startsWith('  ') || line.startsWith('\t');
}

_CompactLinkPreview? _compactLinkPreview(String text) {
  final hrefMatch = RegExp(
    r'https?://\S+',
    caseSensitive: false,
  ).firstMatch(text);
  if (hrefMatch == null) {
    return null;
  }
  final href = hrefMatch.group(0)!.trim();
  final uri = Uri.tryParse(href);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  final labelText = _cleanCompactLinkText(
    text
        .replaceRange(hrefMatch.start, hrefMatch.end, ' ')
        .replaceAll(RegExp(r'\s+'), ' '),
  );
  if (labelText.length < 4) {
    return null;
  }
  final sourceMatch = RegExp(
    r'^(.*?)\s*(?:[—–]| - |:)\s*(.+)$',
  ).firstMatch(labelText);
  final prefix = _cleanCompactLinkText(sourceMatch?.group(1) ?? '');
  final title = _cleanCompactLinkText(sourceMatch?.group(2) ?? labelText);
  if (title.isEmpty || title.startsWith(RegExp(r'https?://'))) {
    return null;
  }
  return _CompactLinkPreview(
    href: href,
    prefix: prefix.isEmpty ? null : prefix,
    title: title,
  );
}

String _cleanCompactLinkText(String value) {
  return value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[\s"“”‘’]+|[\s"“”‘’]+$'), '')
      .trim();
}

class _InlineMathPart {
  const _InlineMathPart.text(this.text) : math = null;
  const _InlineMathPart.math(this.math) : text = '';

  final String text;
  final String? math;
}

List<_InlineMathPart>? _inlineMathParts(String text) {
  final parts = <_InlineMathPart>[];
  var scan = 0;
  var textStart = 0;
  var foundMath = false;

  while (scan < text.length) {
    final codeRange = _inlineCodeRangeAt(text, scan);
    if (codeRange != null) {
      scan = codeRange.end;
      continue;
    }

    final math = _inlineMathAt(text, scan);
    if (math == null) {
      scan += 1;
      continue;
    }

    if (scan > textStart) {
      parts.add(_InlineMathPart.text(text.substring(textStart, scan)));
    }
    parts.add(_InlineMathPart.math(math.expression));
    foundMath = true;
    scan = math.end;
    textStart = scan;
  }

  if (!foundMath) {
    return null;
  }
  if (textStart < text.length) {
    parts.add(_InlineMathPart.text(text.substring(textStart)));
  }
  return parts;
}

({int end})? _inlineCodeRangeAt(String text, int start) {
  if (text.codeUnitAt(start) != 0x60) {
    return null;
  }
  final end = text.indexOf('`', start + 1);
  if (end < 0) {
    return null;
  }
  return (end: end + 1);
}

({String expression, int end})? _inlineMathAt(String text, int start) {
  return _texInlineMathAt(text, start) ?? _singleDollarMathAt(text, start);
}

({String expression, int end})? _texInlineMathAt(String text, int start) {
  if (start + 1 >= text.length ||
      text.codeUnitAt(start) != 0x5c ||
      text.codeUnitAt(start + 1) != 0x28) {
    return null;
  }
  final end = text.indexOf(r'\)', start + 2);
  if (end < 0) {
    return null;
  }
  final expression = text.substring(start + 2, end).trim();
  if (expression.isEmpty) {
    return null;
  }
  return (expression: expression, end: end + 2);
}

({String expression, int end})? _singleDollarMathAt(String text, int start) {
  if (text.codeUnitAt(start) != 0x24 ||
      (start > 0 && text.codeUnitAt(start - 1) == 0x5c) ||
      (start + 1 < text.length && text.codeUnitAt(start + 1) == 0x24)) {
    return null;
  }
  final end = text.indexOf(r'$', start + 1);
  if (end < 0 || end == start + 1) {
    return null;
  }
  if (end + 1 < text.length && text.codeUnitAt(end + 1) == 0x24) {
    return null;
  }
  final expression = text.substring(start + 1, end).trim();
  if (!_looksLikeGuardedMath(expression)) {
    return null;
  }
  return (expression: expression, end: end + 1);
}

bool _looksLikeGuardedMath(String expression) {
  if (expression.isEmpty) {
    return false;
  }
  if (RegExp(r'^\d+(?:[.,]\d+)?(?:\s|[-–]\d)').hasMatch(expression)) {
    return false;
  }
  if (RegExp(r'^[A-Za-z]$').hasMatch(expression)) {
    return true;
  }
  if (RegExp(r'[\\^_{}=]').hasMatch(expression)) {
    return true;
  }
  return false;
}

List<InlineSpan>? _inlineMarkdownSpans(String text, Color color) {
  final matches = RegExp(
    r'`([^`]+)`|\*\*([^*]+)\*\*|~~([^~]+)~~|<mark>([^<]+)</mark>|<sup>([^<]+)</sup>|<sub>([^<]+)</sub>',
    caseSensitive: false,
  ).allMatches(text).toList();
  if (matches.isEmpty) {
    return null;
  }
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final match in matches) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, match.start)));
    }
    final code = match.group(1);
    final bold = match.group(2);
    final strike = match.group(3);
    final mark = match.group(4);
    final sup = match.group(5);
    final sub = match.group(6);
    if (code != null) {
      spans.add(
        TextSpan(
          text: code,
          style: TextStyle(
            color: color,
            backgroundColor: AppThemeTokens.panelMuted,
            fontFamily: 'monospace',
            fontSize: 13,
          ),
        ),
      );
    } else if (strike != null) {
      spans.add(
        TextSpan(
          text: strike,
          style: TextStyle(
            color: color,
            decoration: TextDecoration.lineThrough,
          ),
        ),
      );
    } else if (mark != null) {
      spans.add(
        TextSpan(
          text: mark,
          style: TextStyle(
            color: color,
            backgroundColor: AppThemeTokens.warningSoft,
          ),
        ),
      );
    } else if (sup != null || sub != null) {
      spans.add(
        TextSpan(
          text: sup ?? sub ?? '',
          style: TextStyle(color: color, fontSize: 10),
        ),
      );
    } else {
      spans.add(
        TextSpan(
          text: bold ?? '',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      );
    }
    cursor = match.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor)));
  }
  return spans;
}

List<_MessageContentSegment> _messageContentSegments(String text) {
  final matches = RegExp(
    r'(!?)\[([^\]]+)\]\(([^)]+)\)',
  ).allMatches(text).toList();
  if (matches.isEmpty) {
    return [if (text.isNotEmpty) _MessageContentSegment.text(text)];
  }
  final segments = <_MessageContentSegment>[];
  var cursor = 0;
  for (final match in matches) {
    final bang = match.group(1) ?? '';
    final href = match.group(3) ?? '';
    final filePath = _localFilePreviewPath(href);
    if (match.start > cursor) {
      segments.add(
        _MessageContentSegment.text(text.substring(cursor, match.start)),
      );
    }
    final label = (match.group(2) ?? filePath ?? href).trim();
    final displayLabel = label.isEmpty
        ? (filePath == null ? href.trim() : _fileNameFromPath(filePath))
        : label;
    if (bang == '!') {
      segments.add(
        _MessageContentSegment.media(
          attachment: NanobotMediaAttachment(
            kind: _markdownAttachmentKind(href, displayLabel),
            url: href.trim(),
            name: displayLabel,
          ),
        ),
      );
    } else if (filePath != null) {
      segments.add(
        _MessageContentSegment.file(text: displayLabel, filePath: filePath),
      );
    } else if (_navigableMarkdownHref(href) != null) {
      segments.add(_MessageContentSegment.link(text: displayLabel, href: href));
    } else {
      segments.add(_MessageContentSegment.text(displayLabel));
    }
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

String _markdownAttachmentKind(String source, String label) {
  final attachment = NanobotMediaAttachment.fromJson({
    'url': source,
    'name': label,
  });
  if (attachment.kind != 'file') {
    return attachment.kind;
  }
  return _extensionOf(label).isNotEmpty || _extensionOf(source).isNotEmpty
      ? 'file'
      : 'image';
}

String _extensionOf(String value) {
  final clean = value.split('?').first.split('#').first.trim();
  final name = _fileNameFromPath(clean);
  final dotIndex = name.lastIndexOf('.');
  if (dotIndex <= 0 || dotIndex == name.length - 1) {
    return '';
  }
  return name.substring(dotIndex).toLowerCase();
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

String? _navigableMarkdownHref(String href) {
  final trimmed = href.trim();
  if (trimmed.isEmpty || trimmed.contains('*')) {
    return null;
  }
  return trimmed;
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
    this.onForkFromHere,
  });

  final NanobotMessage message;
  final ValueChanged<String> onOpenFilePreview;
  final Future<void> Function()? onForkFromHere;

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
              if (message.media.isNotEmpty) ...[
                if (message.content.trim().isNotEmpty ||
                    message.reasoning?.trim().isNotEmpty == true)
                  const SizedBox(height: 8),
                _MessageMediaRow(media: message.media),
              ],
              if (_showsAssistantActions(
                role: message.role,
                isStreaming: message.status == NanobotMessageStatus.streaming,
                content: message.content,
              )) ...[
                const SizedBox(height: 8),
                _AssistantMessageActions(
                  content: message.content,
                  onForkFromHere: onForkFromHere,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantMessageActions extends StatefulWidget {
  const _AssistantMessageActions({
    required this.content,
    required this.onForkFromHere,
  });

  final String content;
  final Future<void> Function()? onForkFromHere;

  @override
  State<_AssistantMessageActions> createState() =>
      _AssistantMessageActionsState();
}

class _AssistantMessageActionsState extends State<_AssistantMessageActions> {
  var _copied = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: _copied ? 'Copied reply' : 'Copy reply',
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            color: AppThemeTokens.mutedText,
            onPressed: () {
              unawaited(_copyReply());
            },
            icon: Icon(_copied ? Icons.check : Icons.copy),
          ),
          if (widget.onForkFromHere != null)
            IconButton(
              tooltip: 'Fork',
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              color: AppThemeTokens.mutedText,
              onPressed: () {
                unawaited(widget.onForkFromHere!());
              },
              icon: const Icon(Icons.call_split),
            ),
        ],
      ),
    );
  }

  Future<void> _copyReply() async {
    await Clipboard.setData(ClipboardData(text: widget.content));
    if (!mounted) {
      return;
    }
    setState(() {
      _copied = true;
    });
  }
}

class _MessageMediaRow extends ConsumerWidget {
  const _MessageMediaRow({required this.media});

  final List<NanobotMediaAttachment> media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaBaseUrl = ref.watch(nanobotConfigProvider).baseUrl;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final attachment in media)
          _MediaAttachmentTile(
            attachment: attachment,
            mediaBaseUrl: mediaBaseUrl,
          ),
      ],
    );
  }
}

class _MediaAttachmentTile extends StatelessWidget {
  const _MediaAttachmentTile({
    required this.attachment,
    required this.mediaBaseUrl,
  });

  final NanobotMediaAttachment attachment;
  final String mediaBaseUrl;

  @override
  Widget build(BuildContext context) {
    final label = attachment.name?.trim().isNotEmpty == true
        ? attachment.name!.trim()
        : _fileNameFromPath(attachment.url ?? 'Attachment');
    final imageBytes = _dataUrlImageBytes(attachment.url);
    final resolvedUrl = _resolvedMediaUrl(attachment.url, mediaBaseUrl);
    if (attachment.kind == 'image' &&
        (imageBytes != null || resolvedUrl != null)) {
      return _ImageAttachmentFrame(
        label: label,
        image: _attachmentImage(
          label: label,
          imageBytes: imageBytes,
          resolvedUrl: resolvedUrl,
          fallback: _AttachmentLabelTile(
            attachment: attachment,
            url: resolvedUrl,
          ),
        ),
        dialogImage: _attachmentImage(
          label: label,
          imageBytes: imageBytes,
          resolvedUrl: resolvedUrl,
          fit: BoxFit.contain,
          fallback: _AttachmentLabelTile(
            attachment: attachment,
            url: resolvedUrl,
          ),
        ),
      );
    }
    if (attachment.kind == 'video' && resolvedUrl != null) {
      return _VideoAttachmentFrame(label: label, url: resolvedUrl);
    }

    return _AttachmentLabelTile(attachment: attachment, url: resolvedUrl);
  }
}

class _VideoAttachmentFrame extends StatefulWidget {
  const _VideoAttachmentFrame({required this.label, required this.url});

  final String label;
  final String url;

  @override
  State<_VideoAttachmentFrame> createState() => _VideoAttachmentFrameState();
}

class _VideoAttachmentFrameState extends State<_VideoAttachmentFrame> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _createController();
  }

  @override
  void didUpdateWidget(_VideoAttachmentFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeController();
      _createController();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _createController() {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) {
      _error = FormatException('Invalid video URL', widget.url);
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri);
    controller.addListener(_handleControllerChanged);
    _controller = controller;
    _initializeFuture = controller.initialize().catchError((Object error) {
      if (mounted) {
        setState(() {
          _error = error;
        });
      } else {
        _error = error;
      }
    });
  }

  void _disposeController() {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    controller.removeListener(_handleControllerChanged);
    controller.dispose();
    _controller = null;
    _initializeFuture = null;
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Container(
      key: const ValueKey('nanobot-markdown-video'),
      constraints: const BoxConstraints(
        minWidth: 160,
        minHeight: 96,
        maxWidth: 520,
        maxHeight: 544,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppThemeTokens.workspace,
        border: Border.all(color: AppThemeTokens.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Semantics(
        label: 'Video attachment: ${widget.label}',
        child: FutureBuilder<void>(
          future: _initializeFuture,
          builder: (context, snapshot) {
            if (_error != null || controller == null) {
              return _AttachmentLabelTile(
                attachment: NanobotMediaAttachment(
                  kind: 'video',
                  url: widget.url,
                  name: widget.label,
                ),
              );
            }
            if (snapshot.connectionState != ConnectionState.done ||
                !controller.value.isInitialized) {
              return const SizedBox(
                height: 128,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            final aspectRatio = controller.value.aspectRatio > 0
                ? controller.value.aspectRatio
                : 16 / 9;
            return Stack(
              alignment: Alignment.bottomLeft,
              children: [
                AspectRatio(
                  aspectRatio: aspectRatio,
                  child: VideoPlayer(controller),
                ),
                Material(
                  color: Colors.black54,
                  child: IconButton(
                    tooltip: controller.value.isPlaying
                        ? 'Pause video'
                        : 'Play video',
                    color: Colors.white,
                    onPressed: () {
                      if (controller.value.isPlaying) {
                        controller.pause();
                      } else {
                        controller.play();
                      }
                    },
                    icon: Icon(
                      controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 18,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ImageAttachmentFrame extends StatelessWidget {
  const _ImageAttachmentFrame({
    required this.label,
    required this.image,
    required this.dialogImage,
  });

  final String label;
  final Widget image;
  final Widget dialogImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 80,
        minHeight: 56,
        maxWidth: 520,
        maxHeight: 544,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppThemeTokens.workspace,
        border: Border.all(color: AppThemeTokens.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showImagePreviewDialog(context, label, dialogImage),
          child: Semantics(
            label: label,
            image: true,
            button: true,
            child: Center(child: image),
          ),
        ),
      ),
    );
  }
}

Widget _attachmentImage({
  required String label,
  required Uint8List? imageBytes,
  required String? resolvedUrl,
  required Widget fallback,
  BoxFit fit = BoxFit.contain,
}) {
  if (imageBytes != null) {
    return Image.memory(
      imageBytes,
      excludeFromSemantics: true,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
  return Image.network(
    resolvedUrl!,
    excludeFromSemantics: true,
    fit: fit,
    errorBuilder: (context, error, stackTrace) => fallback,
  );
}

Future<void> _showImagePreviewDialog(
  BuildContext context,
  String label,
  Widget image,
) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: AppThemeTokens.workspace,
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Image preview',
                        style: TextStyle(
                          color: AppThemeTokens.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Semantics(
                    label: label,
                    image: true,
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 5,
                      child: image,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AttachmentLabelTile extends StatelessWidget {
  const _AttachmentLabelTile({required this.attachment, this.url});

  final NanobotMediaAttachment attachment;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final label = attachment.name?.trim().isNotEmpty == true
        ? attachment.name!.trim()
        : _fileNameFromPath(attachment.url ?? 'Attachment');
    final semanticsLabel = switch (attachment.kind) {
      'file' => 'File attachment',
      'video' => 'Video attachment: $label',
      'image' => 'Image attachment: $label',
      _ => 'Attachment',
    };
    final tile = Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppThemeTokens.workspace,
        border: Border.all(color: AppThemeTokens.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _mediaIcon(attachment.kind),
            size: 16,
            color: AppThemeTokens.mutedText,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppThemeTokens.text,
                fontSize: 12,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
    final href = url;
    return Semantics(
      label: semanticsLabel,
      container: true,
      link: href != null,
      onTap: href == null ? null : () => _launchExternalUrl(href),
      child: href == null
          ? tile
          : Tooltip(
              message: href,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _launchExternalUrl(href),
                  child: tile,
                ),
              ),
            ),
    );
  }

  IconData _mediaIcon(String kind) {
    return switch (kind) {
      'image' => Icons.image_outlined,
      'video' => Icons.play_circle_outline,
      _ => Icons.insert_drive_file_outlined,
    };
  }
}

Uint8List? _dataUrlImageBytes(String? url) {
  final value = url?.trim();
  if (value == null || !value.startsWith('data:image/')) {
    return null;
  }
  final commaIndex = value.indexOf(',');
  if (commaIndex < 0) {
    return null;
  }
  final metadata = value.substring(0, commaIndex).toLowerCase();
  if (!metadata.contains(';base64')) {
    return null;
  }
  try {
    return base64Decode(value.substring(commaIndex + 1));
  } on FormatException {
    return null;
  }
}

String? _resolvedMediaUrl(String? url, String mediaBaseUrl) {
  final value = url?.trim();
  if (value == null || value.isEmpty || value.startsWith('data:')) {
    return null;
  }
  final parsed = Uri.tryParse(value);
  if (parsed == null) {
    return null;
  }
  if (parsed.hasScheme) {
    return value;
  }
  final base = Uri.tryParse(mediaBaseUrl);
  if (base == null || !base.hasScheme) {
    return null;
  }
  return base.resolveUri(parsed).toString();
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

class _StreamErrorNotice extends StatelessWidget {
  const _StreamErrorNotice({required this.error, required this.onDismiss});

  final NanobotStreamError error;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final copy = _streamErrorCopy(error);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppThemeTokens.dangerSoft,
          border: Border.all(color: AppThemeTokens.dangerBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppThemeTokens.dangerText,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.title,
                    style: const TextStyle(
                      color: AppThemeTokens.dangerText,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    copy.body,
                    style: const TextStyle(
                      color: AppThemeTokens.dangerText,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Dismiss',
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
              color: AppThemeTokens.dangerText,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

({String title, String body}) _streamErrorCopy(NanobotStreamError error) {
  return switch (error.kind) {
    NanobotStreamErrorKind.messageTooBig => (
      title: 'Message too large',
      body:
          'The server rejected your last message because it exceeded the size limit. '
          'Remove some images or try smaller files, then send again.',
    ),
  };
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
          Flexible(
            fit: FlexFit.loose,
            child: PopupMenuButton<String>(
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
                  Flexible(
                    child: Text(
                      modeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scope.isFullAccess
                            ? AppThemeTokens.warning
                            : AppThemeTokens.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
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

class _QueuedPromptStack extends StatelessWidget {
  const _QueuedPromptStack({
    required this.prompts,
    required this.onGuide,
    required this.onEdit,
    required this.onDelete,
    required this.onReorder,
  });

  final List<_QueuedPrompt> prompts;
  final ValueChanged<_QueuedPrompt> onGuide;
  final ValueChanged<_QueuedPrompt> onEdit;
  final ValueChanged<String> onDelete;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Queued guidance',
      child: Container(
        key: const ValueKey('nanobot-queued-guidance'),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppThemeTokens.panelMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppThemeTokens.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Queued guidance',
              style: TextStyle(
                color: AppThemeTokens.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 216),
              child: ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: prompts.length,
                onReorderItem: onReorder,
                itemBuilder: (context, index) {
                  final prompt = prompts[index];
                  return Padding(
                    key: ValueKey('nanobot-queued-prompt-${prompt.id}'),
                    padding: EdgeInsets.only(
                      bottom: index == prompts.length - 1 ? 0 : 4,
                    ),
                    child: _QueuedPromptRow(
                      prompt: prompt,
                      index: index,
                      onGuide: onGuide,
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueuedPromptRow extends StatelessWidget {
  const _QueuedPromptRow({
    required this.prompt,
    required this.index,
    required this.onGuide,
    required this.onEdit,
    required this.onDelete,
  });

  final _QueuedPrompt prompt;
  final int index;
  final ValueChanged<_QueuedPrompt> onGuide;
  final ValueChanged<_QueuedPrompt> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final text = prompt.text.trim();
    final mediaCount = prompt.media.length;
    final label = text.isNotEmpty
        ? text
        : mediaCount == 1
        ? '1 image'
        : '$mediaCount images';
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppThemeTokens.panel,
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Tooltip(
              message: 'Drag to reorder',
              child: Icon(
                Icons.drag_indicator,
                size: 16,
                color: AppThemeTokens.subtleText,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppThemeTokens.headingText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          TextButton.icon(
            onPressed: () => onGuide(prompt),
            icon: const Icon(Icons.subdirectory_arrow_right, size: 14),
            label: const Text('Guide'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Edit guidance',
            onPressed: () => onEdit(prompt),
            icon: const Icon(Icons.edit_outlined, size: 16),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          ),
          IconButton(
            tooltip: 'Delete guidance',
            onPressed: () => onDelete(prompt.id),
            icon: const Icon(Icons.delete_outline, size: 16),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatefulWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.isStreaming,
    required this.runStartedAt,
    required this.goalState,
    required this.attachedImages,
    required this.queuedPrompts,
    required this.isPickingImages,
    required this.isTranscribingVoice,
    required this.inlineError,
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
    required this.onQueueGuidance,
    required this.onFlushQueuedPrompt,
    required this.onSendQueuedPrompt,
    required this.onEditQueuedPrompt,
    required this.onDeleteQueuedPrompt,
    required this.onReorderQueuedPrompts,
    required this.onTranscribeVoice,
    required this.onAttachImages,
    required this.onRemoveAttachedImage,
    required this.onWorkspaceAccessMode,
    required this.onWorkspaceProjectPath,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final bool isStreaming;
  final int? runStartedAt;
  final Map<String, Object?>? goalState;
  final List<NanobotSendMedia> attachedImages;
  final List<_QueuedPrompt> queuedPrompts;
  final bool isPickingImages;
  final bool isTranscribingVoice;
  final String? inlineError;
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
  final VoidCallback onQueueGuidance;
  final VoidCallback onFlushQueuedPrompt;
  final ValueChanged<_QueuedPrompt> onSendQueuedPrompt;
  final ValueChanged<_QueuedPrompt> onEditQueuedPrompt;
  final ValueChanged<String> onDeleteQueuedPrompt;
  final void Function(int oldIndex, int newIndex) onReorderQueuedPrompts;
  final VoidCallback? onTranscribeVoice;
  final VoidCallback onAttachImages;
  final ValueChanged<int> onRemoveAttachedImage;
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
  void didUpdateWidget(covariant _InputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isStreaming &&
        !widget.isStreaming &&
        widget.queuedPrompts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.isStreaming) {
          return;
        }
        widget.onFlushQueuedPrompt();
      });
    }
  }

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
                  if (widget.queuedPrompts.isNotEmpty)
                    _QueuedPromptStack(
                      prompts: widget.queuedPrompts,
                      onGuide: widget.onSendQueuedPrompt,
                      onEdit: widget.onEditQueuedPrompt,
                      onDelete: widget.onDeleteQueuedPrompt,
                      onReorder: widget.onReorderQueuedPrompts,
                    ),
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
                  _RunGoalStrip(
                    startedAt: widget.runStartedAt,
                    goalState: widget.goalState,
                  ),
                  if (widget.attachedImages.isNotEmpty)
                    _ComposerImageChipRow(
                      images: widget.attachedImages,
                      onRemove: widget.onRemoveAttachedImage,
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Attach image',
                          onPressed:
                              widget.isPickingImages ||
                                  widget.attachedImages.length >=
                                      _NanobotWorkspacePageState
                                          ._maxImageAttachments
                              ? null
                              : widget.onAttachImages,
                          icon: widget.isPickingImages
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
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
                  if (widget.inlineError != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppThemeTokens.dangerSoft,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppThemeTokens.dangerBorder,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Text(
                              widget.inlineError!,
                              style: const TextStyle(
                                color: AppThemeTokens.dangerText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (widget.onTranscribeVoice != null) ...[
              IconButton(
                tooltip: widget.isTranscribingVoice
                    ? 'Transcribing voice'
                    : 'Voice input',
                onPressed: widget.isTranscribingVoice
                    ? null
                    : widget.onTranscribeVoice,
                icon: widget.isTranscribingVoice
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.mic_none),
              ),
              const SizedBox(width: 4),
            ],
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
      if (event.logicalKey == LogicalKeyboardKey.enter &&
          !HardwareKeyboard.instance.isShiftPressed &&
          _canQueueGuidance()) {
        widget.onQueueGuidance();
        return KeyEventResult.handled;
      }
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

  bool _canQueueGuidance() {
    final text = widget.controller.text.trim();
    return widget.isStreaming &&
        widget.canSend &&
        (text.isNotEmpty || widget.attachedImages.isNotEmpty) &&
        !text.trimLeft().startsWith('/');
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

class _ComposerImageChipRow extends StatelessWidget {
  const _ComposerImageChipRow({required this.images, required this.onRemove});

  final List<NanobotSendMedia> images;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < images.length; index += 1)
              _ComposerImageChip(
                key: ValueKey('composer-image-${images[index].name}-$index'),
                media: images[index],
                onRemove: () => onRemove(index),
              ),
          ],
        ),
      ),
    );
  }
}

class _ComposerImageChip extends StatelessWidget {
  const _ComposerImageChip({
    super.key,
    required this.media,
    required this.onRemove,
  });

  final NanobotSendMedia media;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final label = media.name?.trim().isNotEmpty == true
        ? media.name!.trim()
        : 'Image attachment';
    final thumbnail = _bytesFromDataUrl(media.dataUrl);
    final sizeLabel = _composerImageSizeLabel(media.dataUrl);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppThemeTokens.panelMuted,
        borderRadius: BorderRadius.circular(AppThemeTokens.radius),
        border: Border.all(color: AppThemeTokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox.square(
                dimension: 40,
                child: thumbnail == null
                    ? const ColoredBox(
                        color: AppThemeTokens.panel,
                        child: Icon(
                          Icons.image_outlined,
                          size: 18,
                          color: AppThemeTokens.mutedText,
                        ),
                      )
                    : Image.memory(
                        thumbnail,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        semanticLabel: label,
                      ),
              ),
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppThemeTokens.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (sizeLabel != null)
                    Text(
                      sizeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppThemeTokens.mutedText,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Remove $label',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Uint8List? _bytesFromDataUrl(String dataUrl) {
    final comma = dataUrl.indexOf(',');
    if (comma <= 0 || !dataUrl.substring(0, comma).contains(';base64')) {
      return null;
    }
    try {
      return base64Decode(dataUrl.substring(comma + 1));
    } on FormatException {
      return null;
    }
  }
}

bool _isSupportedComposerImage(String dataUrl) {
  final mime = _composerDataUrlMime(dataUrl);
  return mime == 'image/png' ||
      mime == 'image/jpeg' ||
      mime == 'image/webp' ||
      mime == 'image/gif';
}

String? _composerDataUrlMime(String dataUrl) {
  if (!dataUrl.startsWith('data:')) {
    return null;
  }
  final end = dataUrl.indexOf(RegExp('[;,]'), 5);
  if (end <= 5) {
    return null;
  }
  return dataUrl.substring(5, end).toLowerCase();
}

int? _composerDataUrlByteCount(String dataUrl) {
  final comma = dataUrl.indexOf(',');
  if (comma <= 0 || !dataUrl.substring(0, comma).contains(';base64')) {
    return null;
  }
  try {
    return base64Decode(dataUrl.substring(comma + 1)).length;
  } on FormatException {
    return null;
  }
}

String? _composerImageSizeLabel(String dataUrl) {
  final bytes = _composerDataUrlByteCount(dataUrl);
  if (bytes == null) {
    return null;
  }
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _voiceInputErrorMessage(Object error) {
  final detail = error.toString();
  if (detail.contains('unsupported')) {
    return 'Voice input is not supported in this browser.';
  }
  if (detail.contains('microphone_permission_denied') ||
      detail.contains('permission')) {
    return 'Microphone permission is required.';
  }
  if (detail.contains('not_configured')) {
    return 'Configure a transcription provider first.';
  }
  if (detail.contains('duration')) {
    return 'Recording is too long.';
  }
  if (detail.contains('too_short') || detail.contains('tooShort')) {
    return 'Hold a little longer to record voice.';
  }
  if (detail.contains('no_input') || detail.contains('noInput')) {
    return 'No microphone input detected.';
  }
  return 'Could not transcribe audio.';
}

class _RunGoalStrip extends StatefulWidget {
  const _RunGoalStrip({required this.startedAt, required this.goalState});

  final int? startedAt;
  final Map<String, Object?>? goalState;

  @override
  State<_RunGoalStrip> createState() => _RunGoalStripState();
}

class _RunGoalStripState extends State<_RunGoalStrip> {
  Timer? _timer;
  var _expanded = false;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant _RunGoalStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isGoalActive(widget.goalState)) {
      _expanded = false;
    }
    if (oldWidget.startedAt != widget.startedAt) {
      _syncTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showTimer = widget.startedAt != null;
    final goalLabel = _goalStripPreview(widget.goalState);
    final showGoal = goalLabel != null;
    if (!showTimer && !showGoal) {
      return const SizedBox.shrink();
    }

    final objective = _stringFrom(widget.goalState?['objective']);
    final summary = _stringFrom(widget.goalState?['ui_summary']);
    final canExpand =
        _isGoalActive(widget.goalState) &&
        (objective.trim().isNotEmpty || summary.trim().isNotEmpty);
    final timerLabel = showTimer ? 'Running · ${_elapsedLabel()}' : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppThemeTokens.panelMuted,
          borderRadius: BorderRadius.circular(AppThemeTokens.radius),
          border: Border.all(
            color: _isGoalActive(widget.goalState)
                ? AppThemeTokens.accent.withValues(alpha: 0.32)
                : AppThemeTokens.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_expanded && canExpand)
              _GoalPanel(summary: summary, objective: objective),
            Semantics(
              liveRegion: true,
              label: [
                ?timerLabel,
                if (showGoal) 'Goal · $goalLabel',
              ].join(' · '),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      showTimer ? Icons.radio_button_checked : Icons.adjust,
                      size: 16,
                      color: showTimer
                          ? AppThemeTokens.accent
                          : AppThemeTokens.mutedText,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (timerLabel != null)
                            Text(
                              timerLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppThemeTokens.text,
                              ),
                            ),
                          if (timerLabel != null && showGoal)
                            const Text(
                              '·',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppThemeTokens.mutedText,
                              ),
                            ),
                          if (showGoal)
                            Text(
                              'Goal · $goalLabel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppThemeTokens.text,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (canExpand)
                      IconButton(
                        tooltip: _expanded ? 'Close goal' : 'Show full goal',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        onPressed: () {
                          setState(() => _expanded = !_expanded);
                        },
                        icon: Icon(
                          _expanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    if (widget.startedAt == null) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  String _elapsedLabel() {
    final startedAt = widget.startedAt;
    if (startedAt == null) {
      return '0s';
    }
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final elapsed = (now - startedAt).clamp(0, 1 << 31);
    final minutes = elapsed ~/ 60;
    final seconds = elapsed % 60;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }
}

class _GoalPanel extends StatelessWidget {
  const _GoalPanel({required this.summary, required this.objective});

  final String summary;
  final String objective;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppThemeTokens.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Goal',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppThemeTokens.text,
              ),
            ),
            if (summary.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                summary.trim(),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppThemeTokens.text,
                ),
              ),
            ],
            if (objective.trim().isNotEmpty) ...[
              if (summary.trim().isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: AppThemeTokens.border),
                )
              else
                const SizedBox(height: 8),
              Text(
                objective.trim(),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppThemeTokens.text,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

bool _isGoalActive(Map<String, Object?>? goalState) {
  return goalState?['active'] == true;
}

String? _goalStripPreview(Map<String, Object?>? goalState) {
  if (!_isGoalActive(goalState)) {
    return null;
  }
  final summary = _stringFrom(goalState?['ui_summary']).trim();
  if (summary.isNotEmpty) {
    return summary;
  }
  final objective = _stringFrom(goalState?['objective']).trim();
  if (objective.isNotEmpty) {
    return objective.length > 72 ? '${objective.substring(0, 72)}…' : objective;
  }
  return 'Goal';
}

String _stringFrom(Object? value) => value is String ? value : '';

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
