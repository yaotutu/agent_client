# Agent Client Responsive UI Design

> Note: The large-screen direction in this document is superseded by
> `docs/superpowers/specs/2026-06-02-mobile-first-adaptive-ui-strategy.md`.
> Current policy is mobile first, tablet second, and desktop-as-tablet until a
> dedicated desktop enhancement phase is planned.

## Goal

Improve the mobile, tablet, and large-screen UI without changing backend contracts or feature boundaries. The app should feel like one coherent agent workspace: focused chat, dense but readable file/task lists, and predictable navigation.

## Approved Direction

Use the adaptive layout direction from option B, with one extra constraint from review: large screens must remain two columns. Do not use a three-column layout with Agent navigation, Session navigation, and Chat visible at the same time.

## Responsive Layout

- Compact screens under `600px`: single-column workspace.
  - Top app header shows menu, current agent name, and stable actions.
  - Agent navigation stays in the drawer.
  - Chat, Files, and Tasks remain in tabs.
  - Chat session switching uses a dialog.

- Medium screens from `600px` to `839px`: two columns with a compact Agent rail.
  - Left column is a narrow agent rail, around `72-88px`.
  - Right column owns the whole workspace.
  - No persistent session rail.

- Wide screens from `840px` upward: two columns with a full Agent panel.
  - Left column uses a readable Agent navigation panel, around `260-300px`.
  - Right column remains a single workspace surface.
  - Chat sessions are opened from a composer button and selected in a dialog, not a permanent column.

## Chat Experience

- Add a conversation switch button at the lower-left of the Chat composer.
- Remove the need for a permanent `ChatSessionRail`.
- Keep the composer fixed at the bottom of the Chat panel.
- Use wider assistant bubbles and stable max width so large screens feel spacious but lines remain readable.
- Keep touch targets at least `44px` high for buttons and session rows.

## Files And Tasks

- Match Files and Tasks density to the Chat workspace instead of making them feel like separate card-heavy pages.
- Use flatter row styling with subtle borders, consistent icon blocks, and tighter vertical rhythm.
- Keep the current feature behavior: browse directories, open editable files, refresh, and display task status.

## Visual System

- Keep the current teal brand color, but reduce large solid color areas.
- Centralize repeated visual tokens where practical:
  - workspace background
  - panel background
  - border color
  - primary text
  - muted text
  - radius
  - common spacing
- Prefer quiet, utilitarian styling over decorative dashboard cards.
- Keep cards at `8px` radius unless Material components impose their own shape.

## Architecture Boundaries

- UI changes stay in `presentation/` widgets and `app/theme`.
- Do not import `features/agent_control/*` into UI, controllers, or domain layers.
- Do not expose Agent Control DTOs to presentation widgets.
- Keep chat cache/session behavior unchanged.

## Testing And Verification

- Update or add widget tests if existing responsive behavior is covered by tests.
- Run:
  - `flutter analyze`
  - `flutter test --no-pub`
  - `git diff --check`
- Manually inspect representative widths:
  - phone: around `390px`
  - small tablet: around `768px`
  - large screen: around `1200px`

## Out Of Scope

- New backend routing.
- Chat protocol changes.
- File editor feature changes.
- New task data model.
- A full visual redesign with custom illustration, marketing-style hero content, or decorative backgrounds.
