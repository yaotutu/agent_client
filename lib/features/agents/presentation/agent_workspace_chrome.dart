part of 'agent_workspace_page.dart';

class _AppRail extends StatelessWidget {
  const _AppRail();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('agent-app-rail'),
      width: _appRailWidth,
      decoration: const BoxDecoration(
        color: Color(0xFFF0F7FC),
        border: Border(right: BorderSide(color: AppThemeTokens.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const _WorkspaceAvatar(),
          const SizedBox(height: 28),
          _RailButton(
            key: const Key('agent-rail-conversations-button'),
            icon: Icons.chat_bubble_outline,
            selected: true,
            tooltip: 'Conversations',
            onPressed: () {},
          ),
          const SizedBox(height: 10),
          const _RailButton(
            icon: Icons.more_horiz,
            tooltip: 'More',
            onPressed: null,
          ),
          const SizedBox(height: 10),
          const _RailButton(
            icon: Icons.calendar_today_outlined,
            tooltip: 'Schedule',
            onPressed: null,
          ),
          const Spacer(),
          _RailButton(
            key: const Key('global-settings-button'),
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            onPressed: () => openAppSettingsPage(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _WorkspaceAvatar extends StatelessWidget {
  const _WorkspaceAvatar();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const CircleAvatar(
          radius: 23,
          backgroundColor: Color(0xFF1D2939),
          foregroundColor: Colors.white,
          child: Text('>_'),
        ),
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: AppThemeTokens.success,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.selected = false,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: selected ? AppThemeTokens.brand : const Color(0xFF667085),
        ),
      ),
    );
  }
}
