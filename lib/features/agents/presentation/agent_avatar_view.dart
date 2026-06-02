import 'package:agent_client/app/theme/app_theme_tokens.dart';
import 'package:agent_client/features/agents/domain/agent.dart';
import 'package:agent_client/features/agents/domain/agent_avatar.dart';
import 'package:flutter/material.dart';

class AgentAvatarView extends StatelessWidget {
  const AgentAvatarView({
    super.key,
    required this.agent,
    this.selected = false,
    this.radius = 24,
    this.showStatus = true,
  });

  final Agent agent;
  final bool selected;
  final double radius;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final statusSize = radius <= 20 ? 10.0 : 13.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _AvatarCircle(agent: agent, selected: selected, radius: radius),
        if (showStatus)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: statusSize,
              height: statusSize,
              decoration: BoxDecoration(
                color: _statusColor(agent.status),
                shape: BoxShape.circle,
                border: Border.all(color: AppThemeTokens.panel, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.agent,
    required this.selected,
    required this.radius,
  });

  final Agent agent;
  final bool selected;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = agent.avatarUrl;
    if (AgentAvatarOptions.isDefaultAssetPath(avatarUrl)) {
      final size = radius * 2;
      return ClipOval(
        child: Image.asset(
          avatarUrl!,
          key: Key('agent-avatar-image-${agent.id}'),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              _InitialAvatar(agent: agent, selected: selected, radius: radius),
        ),
      );
    }

    return _InitialAvatar(agent: agent, selected: selected, radius: radius);
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({
    required this.agent,
    required this.selected,
    required this.radius,
  });

  final Agent agent;
  final bool selected;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: selected
          ? AppThemeTokens.brand
          : AppThemeTokens.brandSoft,
      foregroundColor: selected ? Colors.white : AppThemeTokens.brand,
      child: Text(_initialFor(agent.name)),
    );
  }
}

Color _statusColor(AgentStatus status) {
  return switch (status) {
    AgentStatus.online => AppThemeTokens.success,
    AgentStatus.busy => AppThemeTokens.warning,
    AgentStatus.offline => AppThemeTokens.subtleText,
  };
}

String _initialFor(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed.characters.first.toUpperCase();
}
