import 'package:agent_client/features/files/application/agent_files_provider.dart';
import 'package:agent_client/features/files/domain/agent_file_item.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FilesPanel extends ConsumerWidget {
  const FilesPanel({super.key, required this.agentId});

  final String agentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(agentFilesProvider(agentId));

    return ColoredBox(
      color: const Color(0xFFF7F8FA),
      child: ListView.separated(
        key: const Key('agent-files-list'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: files.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return _FileRow(file: files[index]);
        },
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file});

  final AgentFileItem file;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
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
              IconButton(
                tooltip: 'More',
                onPressed: () {},
                icon: const Icon(Icons.more_horiz),
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
    };
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
