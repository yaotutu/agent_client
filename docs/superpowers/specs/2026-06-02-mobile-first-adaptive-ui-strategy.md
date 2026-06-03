# Mobile-First Adaptive UI Strategy

## Goal

Plan the client UI so future desktop-specific behavior can be added without
splitting apart phone and tablet code after the fact.

## Priority Order

The product adapts in this order:

1. Mobile is the primary design target.
2. Tablet is adapted after the mobile experience is stable.
3. Desktop is adapted last.

Desktop support is still required, and desktop now has its own workspace and
interaction entry point. When a layout entry is not fully implemented, that
entry must degrade to the nearest usable lower layout instead of showing an
empty or placeholder UI.

## Layout Fallback Rule

There are three workspace entries:

- Mobile workspace.
- Tablet workspace.
- Desktop workspace.

Each entry should always be routable. If an entry is still incomplete, it owns
its own fallback:

- Desktop workspace can return the tablet workspace.
- Tablet workspace can return the mobile workspace.
- Mobile workspace is the baseline and must always be usable.

This keeps all form factors working during staged development while still
giving desktop a clean place for pointer-first UI later.

## Directory Layout

Workspace and chat presentation code is organized by target layout:

- `mobile/`: phone-first touch UI.
- `tablet/`: tablet touch UI.
- `desktop/`: pointer-first desktop UI and desktop fallback entry.
- `shared/`: cross-layout building blocks that do not contain layout-specific
  interaction decisions.

Desktop work should add or replace code under `desktop/` first. Shared
components should stay small and neutral so desktop interaction changes do not
leak back into mobile or tablet.

## Separate Concepts

Adaptive code should keep these concepts separate:

- Device class: mobile, tablet, desktop.
- Workspace layout mode: mobile, tablet, or desktop.
- Interaction mode: mobile, tablet, or desktop.

Desktop-specific context menus, hover actions, keyboard shortcuts, and
pointer-first controls must live under the desktop UI tree. They should not
rewrite mobile or tablet behavior.

## Implementation Boundary

Responsive thresholds should live in one adaptive policy module under
`lib/app/`. Entry fallback belongs inside the incomplete workspace entry itself.
Presentation widgets should consume the policy rather than scattering width
checks across the widget tree.

Feature UI may branch on layout or interaction mode, but should avoid checking
raw widths unless it is handling local sizing inside an already selected mode.

## Current Mapping

- Widths under `600px`: mobile device class, mobile layout, mobile interaction.
- Widths from `600px` up to the desktop threshold: tablet device class, tablet
  layout, tablet interaction.
- Widths at or above the desktop threshold: desktop device class, desktop
  layout, desktop interaction.

The desktop workspace entry currently degrades to the tablet shell until the
desktop UI is implemented. That fallback belongs to the desktop workspace
entry, not to the adaptive policy.

## Relationship To Earlier Responsive Design

This strategy supersedes older large-screen assumptions that treated desktop as
a separate active layout target. The active near-term direction is:

- Build mobile first.
- Adapt tablet second.
- Give desktop its own entry point, but let that entry degrade to tablet until
  desktop enhancement work is implemented.

## Testing

Tests should cover both classification and active fallback behavior:

- A phone width selects mobile layout.
- A tablet width selects tablet layout.
- A desktop width selects desktop layout and desktop interaction.
- The desktop workspace entry can currently render the tablet shell as its
  fallback.
- The workspace shell consumes the policy rather than duplicating breakpoint
  constants.
