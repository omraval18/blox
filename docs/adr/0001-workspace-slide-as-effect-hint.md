# 0001: Workspace slide is a hint effect, not new placement effects

Status: accepted (v0.0.19)

## Context

Hyprland slides windows when the workspace changes. Blox hides a workspace by parking its windows in
a screen corner, so a slide needs outgoing windows to glide off an edge before parking and incoming
windows to start offscreen. The reducer already emits `place`, `park` and `unpark` per window.

## Decision

The reducer emits one extra effect, `slide(direction)`, ahead of the placements of a switch that
changes exactly one monitor's workspace. The direction comes from the workspace order (numbers
numerically, then letters): going forward is `left`. The platform remembers it for the duration of
that `execute` call and:

- turns a `park` into a glide off the edge followed by the real park (`AnimationTrack.Finish.park`);
- starts a `place` or `unpark` of a parked window from the opposite edge.

Whether and how it animates is platform and settings business (`[animation.workspaces]`). With
animation off, or no hint, effects behave exactly as before, so the reducer stays pure and the old
tests only gained the leading hint.

## Consequences

- No hint for monitor swaps or display changes: they have no natural direction.
- A window still sliding out when its workspace returns turns around from where it is.
- Only horizontal travel. Hyprland's `slidevert` is not offered: macOS clamps windows below the menu
  bar, so a window cannot leave through the top.
- Travel distance is the width of the window's own screen, so on multi-monitor setups a sliding
  window crosses the neighbouring screen. `style = "off"` avoids that.
