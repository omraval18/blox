# 0002: Real windows never overshoot their target

## Context

Hyprland curves such as `wind` (`0.05 0.9 0.1 1.05`) overshoot: a window travels a little past its
target and settles back. Hyprland is the compositor, so it draws that bounce on a buffer it owns.
Blox moves real app windows through Accessibility. A live trace (2026-11-14) showed what the bounce
does there: a window swapped to the right travelled 16 pt past its tile, under its neighbour, and a
window at the screen edge went 16 pt off screen and back. The owner read this as "weird behaviour".
The bounce also pushed windows out of their border ring's enlarged panel on every overshoot frame,
forcing a panel resize per frame.

## Decision

`Timing.travel(after:)` clamps the curve's value to `0...1`. Curves keep their shape up to the
target (the fast start of `wind` is untouched) but a real window never moves past it, or behind its
start for curves that dip below zero.

## Consequences

- No overlap with neighbours and no edge reveal during moves; a window stays within the union of
  its start and end frames, so its ring panel grows at most once per animation.
- Overshooting presets end earlier: `Timing.arrival` is the first moment the curve reaches 1 (found
  once per `Timing`), travel holds at 1 from then on, and the animator ends the track there instead
  of at `duration` (a `wind` move arrived at 0.08 s of 0.28 s). So the ring panel shrinks back, the
  reshape recheck resumes and the size-limit check runs as soon as the window lands. A curve that
  rises above 1 and dips back below before the end does not pull the window back: first arrival wins.
- `Curve.value(at:)` is unchanged, so curve maths and config parsing are unaffected.
