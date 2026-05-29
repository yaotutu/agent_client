import 'package:agent_client/features/files/domain/agent_file_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final agentFilesProvider = Provider.family<List<AgentFileItem>, String>((
  ref,
  agentId,
) {
  return switch (agentId) {
    'agent-research' => _researchFiles,
    'agent-ops' => _opsFiles,
    _ => _generalFiles,
  };
});

const _generalFiles = [
  AgentFileItem(
    name: 'Project Brief.pdf',
    kind: AgentFileKind.document,
    sizeLabel: '2.4 MB',
    updatedLabel: 'Updated 09:45',
    owner: 'General Agent',
  ),
  AgentFileItem(
    name: 'Conversation Map.xlsx',
    kind: AgentFileKind.spreadsheet,
    sizeLabel: '846 KB',
    updatedLabel: 'Updated yesterday',
    owner: 'General Agent',
  ),
  AgentFileItem(
    name: 'Mobile Layout.png',
    kind: AgentFileKind.image,
    sizeLabel: '1.1 MB',
    updatedLabel: 'Updated Monday',
    owner: 'Design',
  ),
];

const _researchFiles = [
  AgentFileItem(
    name: 'Research Notes.md',
    kind: AgentFileKind.document,
    sizeLabel: '124 KB',
    updatedLabel: 'Updated 10:12',
    owner: 'Research Agent',
  ),
  AgentFileItem(
    name: 'Source Pack.zip',
    kind: AgentFileKind.archive,
    sizeLabel: '18.6 MB',
    updatedLabel: 'Updated yesterday',
    owner: 'Research Agent',
  ),
];

const _opsFiles = [
  AgentFileItem(
    name: 'Release Checklist.pdf',
    kind: AgentFileKind.document,
    sizeLabel: '612 KB',
    updatedLabel: 'Updated 08:30',
    owner: 'Ops Agent',
  ),
];
