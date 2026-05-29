enum AgentFileKind {
  directory,
  document,
  spreadsheet,
  image,
  archive,
  file,
  other,
}

class AgentFileItem {
  const AgentFileItem({
    required this.name,
    required this.path,
    required this.kind,
    required this.sizeLabel,
    required this.updatedLabel,
    required this.owner,
  });

  final String name;
  final String path;
  final AgentFileKind kind;
  final String sizeLabel;
  final String updatedLabel;
  final String owner;
}
