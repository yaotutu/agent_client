import 'package:agent_client/app/adaptive/adaptive_layout_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdaptiveLayoutPolicy', () {
    test('classifies phone widths as mobile layout and interaction', () {
      final policy = AdaptiveLayoutPolicy.fromWidth(390);

      expect(policy.deviceClass, AdaptiveDeviceClass.mobile);
      expect(policy.workspaceLayout, WorkspaceLayoutMode.mobile);
      expect(policy.interactionMode, WorkspaceInteractionMode.mobile);
      expect(policy.usesDesktopEnhancements, isFalse);
    });

    test('classifies tablet widths as tablet layout and interaction', () {
      final policy = AdaptiveLayoutPolicy.fromWidth(768);

      expect(policy.deviceClass, AdaptiveDeviceClass.tablet);
      expect(policy.workspaceLayout, WorkspaceLayoutMode.tablet);
      expect(policy.interactionMode, WorkspaceInteractionMode.tablet);
      expect(policy.usesDesktopEnhancements, isFalse);
    });

    test('classifies desktop widths but falls back to tablet behavior', () {
      final policy = AdaptiveLayoutPolicy.fromWidth(1200);

      expect(policy.deviceClass, AdaptiveDeviceClass.desktop);
      expect(policy.workspaceLayout, WorkspaceLayoutMode.tablet);
      expect(policy.interactionMode, WorkspaceInteractionMode.tablet);
      expect(
        policy.conversationListWidth,
        AdaptiveLayoutPolicy.tabletConversationListWidth,
      );
      expect(policy.usesDesktopEnhancements, isFalse);
    });
  });
}
