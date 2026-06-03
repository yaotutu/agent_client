enum AdaptiveDeviceClass { mobile, tablet, desktop }

enum WorkspaceLayoutMode { mobile, tablet, desktop }

enum WorkspaceInteractionMode { mobile, tablet, desktop }

class AdaptiveLayoutPolicy {
  const AdaptiveLayoutPolicy({
    required this.deviceClass,
    required this.workspaceLayout,
    required this.interactionMode,
    this.conversationListWidth,
  });

  static const mobileMaxWidth = 600.0;
  static const desktopMinWidth = 1024.0;
  static const tabletConversationListWidth = 312.0;

  final AdaptiveDeviceClass deviceClass;
  final WorkspaceLayoutMode workspaceLayout;
  final WorkspaceInteractionMode interactionMode;
  final double? conversationListWidth;

  bool get usesDesktopEnhancements =>
      interactionMode == WorkspaceInteractionMode.desktop;

  bool get usesMobileWorkspace => workspaceLayout == WorkspaceLayoutMode.mobile;

  static AdaptiveLayoutPolicy fromWidth(double width) {
    if (width < mobileMaxWidth) {
      return const AdaptiveLayoutPolicy(
        deviceClass: AdaptiveDeviceClass.mobile,
        workspaceLayout: WorkspaceLayoutMode.mobile,
        interactionMode: WorkspaceInteractionMode.mobile,
      );
    }

    if (width >= desktopMinWidth) {
      return const AdaptiveLayoutPolicy(
        deviceClass: AdaptiveDeviceClass.desktop,
        workspaceLayout: WorkspaceLayoutMode.desktop,
        interactionMode: WorkspaceInteractionMode.desktop,
      );
    }

    return const AdaptiveLayoutPolicy(
      deviceClass: AdaptiveDeviceClass.tablet,
      workspaceLayout: WorkspaceLayoutMode.tablet,
      interactionMode: WorkspaceInteractionMode.tablet,
      conversationListWidth: tabletConversationListWidth,
    );
  }
}
