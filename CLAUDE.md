# Blox

Lightweight tiling window manager for macOS in Swift. AeroSpace-style virtual workspaces and
keybindings, Hyprland/hyprdots-style animation and borders, built on the Accessibility API.
Current state and next steps: `docs/HANDOFF.md` (read it first). Benchmarking: `docs/benchmarking.md`.

## Commands
- Build: `swift build` · Test: `Scripts/test.sh` · Full gate: `Scripts/lint.sh` (must pass before any commit)
- Package: `Scripts/release.sh` (app bundle + zip) · Runtime memory: `Scripts/bench.sh` · Compare managers: `Scripts/bench-compare.swift`

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

## Performance budgets (idle CPU ~0%, memory footprint < 30 MB, layout pass < 10 ms)
- Event-driven only: AXObserver, NSWorkspace notifications, hotkeys via RegisterEventHotKey. No timers, no polling.
- Diff target frames against current ones; skip unchanged windows. AX calls use 1 s messaging timeouts.
- Animation moves real windows through AX, driven by a CADisplayLink that exists only while animating.
  One border panel per visible window, updated only when its window or focus changes.
- Measure, do not guess: `Scripts/bench.sh` on the running app; `PerformanceTests` guard the core.

## Workflow
- Test first for Core (reducer, layouts, config). Core is pure, so tests need no screen or apps.
- Never launch the app against the user's live windows without their consent; they use AeroSpace daily.
- No `swift test` directly on this machine (Command Line Tools only): use `Scripts/test.sh`.
- Define or change a port/type interface and get it reviewed BEFORE implementing against it.
- One small vertical slice per change. Record non-obvious decisions in `docs/adr/`.

## Git
- Commit messages and PR text must never mention the AI assistant: no author/co-author trailers, no "generated with" lines.
- Versions are `v0.0.x` patches until the first usable release, `v0.1.0`. Tag each patch.
