# Blox

Lightweight tiling window manager for macOS. Hyprland-style config and animation, AeroSpace-style
virtual workspaces, built on the Accessibility API. v1 scope: window tree, dwindle + master layouts,
virtual workspaces, multi-monitor, hotkeys, TOML config with hot reload, CLI over a Unix socket,
snapshot-overlay animations driven by an animation tree.

## Commands
- Build: `swift build` · Test: `Scripts/test.sh` · Full gate: `Scripts/lint.sh` (must pass before any commit)

## Architecture (dependencies point inward only)
- `BloxCore`: pure Swift. Model, layout algorithms, command reducer, animation math, config schema.
  Never imports AppKit/ApplicationServices (lint-enforced). Defines the ports (protocols) the OS must satisfy.
- `BloxPlatform`: the only code that touches the OS (AX, hotkeys, displays, overlays). Implements Core's ports.
- `BloxIPC`: wire protocol shared by app and CLI. `BloxApp`: composition root, wiring only, no logic. `BloxCLI`: thin client.
- Flow: `Event -> Command -> reduce(State, Command) -> (State, [Effect]) -> Platform executes Effects`.
  State changes ONLY inside the reducer. Effects are data; an executor performs them.

## Code rules (enforced by `.swiftlint.yml`; never raise a limit, split the code)
- One primary type per file. Files <= 300 lines preferred (hard cap 500). Functions <= 25 lines. Complexity <= 8 (hard cap 12).
- Prefer structs/enums/actors. Classes must be `final`. No singletons: inject from `BloxApp`.
- No force unwrap/cast/try, no IUOs, no `@unchecked Sendable`, no `Task.detached`, no TODO comments.
- Illegal states unrepresentable: enums with payloads over boolean flags. Parse config once into typed values.
- Public surface is minimal: default to `internal`; expose only what another target needs.
- Fewest lines that stay clear. No speculative abstraction, no comments restating code, no unused code.

## Performance budgets (idle CPU ~0%, RAM < 30 MB, layout pass < 10 ms)
- Event-driven only: AXObserver, NSWorkspace notifications, CGEventTap. No timers, no polling.
- Diff target frames against current ones; skip unchanged windows. Per-app AX work off the main actor, with timeouts.
- Overlays and snapshots exist only while an animation runs, then are released. One-shot capture, never live streams.
- Animation math runs on Core Animation (GPU), never per-frame in Swift.

## Workflow
- Test first for Core (reducer, layouts, config). Core is pure, so tests need no screen or apps.
- Define or change a port/type interface and get it reviewed BEFORE implementing against it.
- One small vertical slice per change. Record non-obvious decisions in `docs/adr/`.

## Git
- Commit messages and PR text must never mention the AI assistant: no author/co-author trailers, no "generated with" lines.
- Versions are `v0.0.x` patches until the first usable release, `v0.1.0`. Tag each patch.
