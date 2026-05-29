class AgentFileContent {
  const AgentFileContent({
    required this.path,
    required this.size,
    required this.mtimeMs,
    required this.content,
  });

  final String path;
  final int size;
  final double mtimeMs;
  final String content;
}

class AgentFileWriteResult {
  const AgentFileWriteResult({
    required this.path,
    required this.size,
    required this.mtimeMs,
  });

  final String path;
  final int size;
  final double mtimeMs;
}
