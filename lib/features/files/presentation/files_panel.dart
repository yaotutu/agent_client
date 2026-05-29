import 'dart:math' as math;

import 'package:agent_client/features/files/application/agent_files_provider.dart';
import 'package:agent_client/features/files/data/agent_resources_repository.dart';
import 'package:agent_client/features/files/domain/agent_file_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _rootPath = '.';

class FilesPanel extends HookConsumerWidget {
  const FilesPanel({super.key, required this.agentId});

  final String agentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = useState(_rootPath);
    final query = (agentId: agentId, path: currentPath.value);
    final files = ref.watch(agentFilesProvider(query));

    void openDirectory(AgentFileItem file) {
      currentPath.value = file.path.isEmpty ? _rootPath : file.path;
    }

    void openFile(AgentFileItem file) {
      showDialog<bool>(
        context: context,
        builder: (context) {
          return _FileEditorDialog(
            agentId: agentId,
            file: file,
            directoryPath: currentPath.value,
          );
        },
      ).then((saved) {
        if (saved == true && context.mounted) {
          ref.invalidate(agentFilesProvider(query));
        }
      });
    }

    void refresh() {
      ref.invalidate(agentFilesProvider(query));
    }

    return ColoredBox(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          _FilesToolbar(
            path: currentPath.value,
            onBack: currentPath.value == _rootPath
                ? null
                : () {
                    currentPath.value = _parentPath(currentPath.value);
                  },
            onRefresh: refresh,
          ),
          Expanded(
            child: files.when(
              data: (files) {
                if (files.isEmpty) {
                  return const _EmptyDirectory();
                }
                return ListView.separated(
                  key: const Key('agent-files-list'),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: files.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _FileRow(
                      file: files[index],
                      onOpenDirectory: openDirectory,
                      onOpenFile: openFile,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Unable to load files: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilesToolbar extends StatelessWidget {
  const _FilesToolbar({
    required this.path,
    required this.onBack,
    required this.onRefresh,
  });

  final String path;
  final VoidCallback? onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E7EC))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            key: const Key('agent-files-back-button'),
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              _pathLabel(path),
              key: const Key('agent-files-current-path'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            key: const Key('agent-files-refresh-button'),
            tooltip: 'Refresh',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _EmptyDirectory extends StatelessWidget {
  const _EmptyDirectory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'This folder is empty',
        style: TextStyle(color: Color(0xFF667085)),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.file,
    required this.onOpenDirectory,
    required this.onOpenFile,
  });

  final AgentFileItem file;
  final ValueChanged<AgentFileItem> onOpenDirectory;
  final ValueChanged<AgentFileItem> onOpenFile;

  @override
  Widget build(BuildContext context) {
    final isDirectory = file.kind == AgentFileKind.directory;
    final isEditable = _canEdit(file);
    final onTap = isDirectory
        ? () => onOpenDirectory(file)
        : isEditable
        ? () => onOpenFile(file)
        : null;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: Key('agent-file-row-${file.path}'),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE4E7EC)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _iconFor(file.kind),
                  color: const Color(0xFF256D85),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MetaText(file.updatedLabel),
                        const _MetaDot(),
                        _MetaText(file.sizeLabel),
                        const _MetaDot(),
                        _MetaText(file.owner),
                      ],
                    ),
                  ],
                ),
              ),
              if (isDirectory)
                const Icon(Icons.chevron_right, color: Color(0xFF667085))
              else
                IconButton(
                  key: Key('agent-file-edit-${file.path}'),
                  tooltip: isEditable ? 'Edit file' : 'Preview unavailable',
                  onPressed: isEditable ? () => onOpenFile(file) : null,
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(AgentFileKind kind) {
    return switch (kind) {
      AgentFileKind.document => Icons.description_outlined,
      AgentFileKind.spreadsheet => Icons.table_chart_outlined,
      AgentFileKind.image => Icons.image_outlined,
      AgentFileKind.archive => Icons.inventory_2_outlined,
      AgentFileKind.directory => Icons.folder_outlined,
      AgentFileKind.file => Icons.insert_drive_file_outlined,
      AgentFileKind.other => Icons.help_outline,
    };
  }
}

class _FileEditorDialog extends HookConsumerWidget {
  const _FileEditorDialog({
    required this.agentId,
    required this.file,
    required this.directoryPath,
  });

  final String agentId;
  final AgentFileItem file;
  final String directoryPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(
      agentFileProvider((agentId: agentId, path: file.path)),
    );
    final controller = useTextEditingController();
    final loadedVersion = useRef<String?>(null);
    final isSaving = useState(false);
    final saveError = useState<String?>(null);
    final loadedFile = fileState.asData?.value;

    useEffect(() {
      final fileContent = loadedFile;
      if (fileContent == null) {
        return null;
      }
      final version = '${fileContent.path}:${fileContent.mtimeMs}';
      if (loadedVersion.value != version) {
        controller.text = fileContent.content;
        loadedVersion.value = version;
      }
      return null;
    }, [loadedFile?.path, loadedFile?.mtimeMs, loadedFile?.content]);

    Future<void> save() async {
      isSaving.value = true;
      saveError.value = null;
      try {
        await ref
            .read(agentResourcesRepositoryProvider)
            .writeFile(
              agentName: agentId,
              path: file.path,
              content: controller.text,
            );
        ref.invalidate(agentFileProvider((agentId: agentId, path: file.path)));
        ref.invalidate(
          agentFilesProvider((agentId: agentId, path: directoryPath)),
        );
        if (context.mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (error) {
        saveError.value = error.toString();
      } finally {
        if (context.mounted) {
          isSaving.value = false;
        }
      }
    }

    final size = MediaQuery.sizeOf(context);
    final width = math.min(size.width - 32, 920.0);
    final height = math.min(size.height - 32, 720.0);
    final canSave = loadedFile != null && !isSaving.value;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            _FileEditorHeader(file: file),
            Expanded(
              child: fileState.when(
                data: (_) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE4E7EC)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      key: const Key('agent-file-editor-field'),
                      controller: controller,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Unable to open file: $error'),
                  ),
                ),
              ),
            ),
            if (saveError.value != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Unable to save file: ${saveError.value}',
                    style: const TextStyle(color: Color(0xFFB42318)),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isSaving.value
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: const Key('agent-file-save-button'),
                    onPressed: canSave
                        ? () {
                            save();
                          }
                        : null,
                    icon: isSaving.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(isSaving.value ? 'Saving' : 'Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileEditorHeader extends StatelessWidget {
  const _FileEditorHeader({required this.file});

  final AgentFileItem file;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          const Icon(Icons.edit_document, color: Color(0xFF256D85)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              file.path,
              key: const Key('agent-file-editor-title'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Color(0xFF667085), fontSize: 13),
    );
  }
}

class _MetaDot extends StatelessWidget {
  const _MetaDot();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '·',
      style: TextStyle(color: Color(0xFF98A2B3), fontSize: 13),
    );
  }
}

bool _canEdit(AgentFileItem file) {
  if (file.kind == AgentFileKind.directory ||
      file.kind == AgentFileKind.image ||
      file.kind == AgentFileKind.archive) {
    return false;
  }
  return true;
}

String _parentPath(String path) {
  final parts = path.split('/').where((part) => part.isNotEmpty).toList();
  if (parts.length <= 1) {
    return _rootPath;
  }
  return parts.take(parts.length - 1).join('/');
}

String _pathLabel(String path) {
  if (path == _rootPath || path.isEmpty) {
    return 'Workspace';
  }
  return 'Workspace / ${path.split('/').where((part) => part.isNotEmpty).join(' / ')}';
}
