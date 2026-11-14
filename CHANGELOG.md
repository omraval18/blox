# Changelog

## v0.0.20
- Frames are set through one channel per app, off the main actor, with AXEnhancedUserInterface switched off while moving.
- Slow apps are resized once per glide instead of every frame.
- Animations end when the window arrives, not when the curve's time is up.
- Window geometry is read from the window server, falling back to Accessibility.
- Added `blox stats`: frame counts and per-app animation step times.
- Socket tests run serially.

## v0.0.19
- Hyprland-style animation phases: `[animation.open]` and `[animation.workspaces]` (slide, popin, off), with per-phase duration and curve.
- Workspace slide and window open animations.
- Smart and per-edge outer gaps, per-workspace layout rules, size limits, tiles layout, `close` command.
- Cmd-H apps leave the layout and rejoin on unhide; native fullscreen windows leave tiling.
- Real-frame borders and a redesigned menu bar.

## v0.0.18
- App icon and DMG volume icon.

## v0.0.17
- DMG build in the release script; README rewrite.
