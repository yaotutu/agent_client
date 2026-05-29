enum AgentFileKind { document, spreadsheet, image, archive }

class AgentFileItem {
  const AgentFileItem({
    required this.name,
    required this.kind,
    required this.sizeLabel,
    required this.updatedLabel,
    required this.owner,
  });

  final String name;
  final AgentFileKind kind;
  final String sizeLabel;
  final String updatedLabel;
  final String owner;
}
