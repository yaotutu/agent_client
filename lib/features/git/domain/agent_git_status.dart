class AgentGitStatus {
  const AgentGitStatus({
    required this.isRepo,
    required this.branch,
    required this.upstream,
    required this.ahead,
    required this.behind,
    required this.clean,
    required this.items,
  });

  const AgentGitStatus.empty()
    : isRepo = false,
      branch = null,
      upstream = null,
      ahead = 0,
      behind = 0,
      clean = true,
      items = const [];

  final bool isRepo;
  final String? branch;
  final String? upstream;
  final int ahead;
  final int behind;
  final bool clean;
  final List<AgentGitStatusItem> items;
}

class AgentGitStatusItem {
  const AgentGitStatusItem({
    required this.path,
    required this.status,
    this.from,
    this.index,
    this.worktree,
  });

  final String path;
  final String status;
  final String? from;
  final String? index;
  final String? worktree;
}

class AgentGitDiff {
  const AgentGitDiff({
    required this.isRepo,
    required this.path,
    required this.diff,
  });

  final bool isRepo;
  final String path;
  final String diff;
}
