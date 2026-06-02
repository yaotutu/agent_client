# Mobile-First Adaptive UI Strategy

## Goal

Plan the client UI so future desktop-specific behavior can be added without
splitting apart phone and tablet code after the fact.

## Priority Order

The product adapts in this order:

1. Mobile is the primary design target.
2. Tablet is adapted after the mobile experience is stable.
3. Desktop is adapted last.

Desktop support is still required, but desktop should not receive special
layout or interaction behavior until a later desktop enhancement phase.

## Current Desktop Rule

Until desktop enhancement is explicitly enabled, desktop falls back to the
tablet workspace layout and tablet interaction model.

This is an intentional product rule, not an accidental side effect of screen
width. The app may identify a wide surface as desktop, but the active workspace
layout remains tablet.

## Separate Concepts

Adaptive code should keep these concepts separate:

- Device class: mobile, tablet, desktop.
- Workspace layout mode: mobile or tablet for the current phase.
- Interaction mode: mobile or tablet for the current phase.

Future desktop work may add:

- Desktop workspace layout mode.
- Desktop interaction mode.
- Context menus, hover actions, keyboard shortcuts, and pointer-first menus.

Those additions should not rewrite mobile or tablet behavior.

## Implementation Boundary

Responsive thresholds and fallback rules should live in one adaptive policy
module under `lib/app/`. Presentation widgets should consume that policy rather
than scattering width checks across the widget tree.

Feature UI may branch on layout or interaction mode, but should avoid checking
raw widths unless it is handling local sizing inside an already selected mode.

## Current Mapping

- Widths under `600px`: mobile device class, mobile layout, mobile interaction.
- Widths from `600px` up to the desktop threshold: tablet device class, tablet
  layout, tablet interaction.
- Widths at or above the desktop threshold: desktop device class, tablet layout,
  tablet interaction.

The desktop threshold is only used to classify the surface for future policy
decisions. It does not activate desktop-specific UI today.

## Relationship To Earlier Responsive Design

This strategy supersedes older large-screen assumptions that treated desktop as
a separate active layout target. The active near-term direction is:

- Build mobile first.
- Adapt tablet second.
- Let desktop inherit tablet behavior until desktop enhancement work is planned.

## Testing

Tests should cover both classification and active fallback behavior:

- A phone width selects mobile layout.
- A tablet width selects tablet layout.
- A desktop width is classified as desktop but still selects tablet layout and
  tablet interaction.
- The workspace shell consumes the policy rather than duplicating breakpoint
  constants.
