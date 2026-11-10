# Blox handoff (state as of v0.0.16)

Read this first in a new session, then `CLAUDE.md` (rules) and `docs/benchmarking.md`.

## What this is

A lightweight tiling window manager for macOS in Swift, built on the Accessibility (AX) API.
AeroSpace-style virtual workspaces and keybindings, Hyprland/hyprdots-style animation and borders,
TOML config with hot reload, CLI over a Unix socket. MIT licensed. Goal: ship **v0.1.0** (first
usable release) once the owner confirms it works on their Mac. Versions are `v0.0.x` patches,
each tagged; `VERSION` and `Sources/BloxIPC/Version.swift` must match (a test checks this).

## Where things stand

- Repo `main`, clean, tags `v0.0.1`..`v0.0.16`. 79 source files (largest 121 lines), 17 test
  files, **86 tests passing**, lint clean.
- **Installed locally**: `/Applications/Blox.app` v0.0.16, CLI symlinked at `/opt/homebrew/bin/blox`
  (into the app bundle). Blox is **not running**: the owner uses **AeroSpace** as their daily driver
  (start-at-login on). Never launch Blox without their say-so; it tiles every open window and both
  managers fight over the same keys.
- Config in use: `~/.config/blox/blox.toml`, same content as `examples/aerospace-compat.toml`.
  Their AeroSpace dotfiles live in `~/dev/dotfiles` (stow); those were not touched.
- Accessibility permission for Blox was reset (`tccutil reset`) and the app freshly reinstalled so
  the owner can re-grant it. Expect that to be the first thing they do.

## Verified vs not verified

Verified: the pure core (layouts, reducer, config, curves, minimum-size logic, overview) by unit
tests; IPC round trip over a real socket; build, lint, packaging, signature validity; idle memory
of a running build (see below).

**Never confirmed on real windows** (needs the owner to run Blox): AX placement across apps,
hotkeys (Carbon `RegisterEventHotKey`), the animation feel in heavy apps, the per-window border
rings (inside-edge placement, z-order above their window), the menu bar workspace list rendering,
minimum-size stacking, the dock-hide `exec` bindings. Treat any of these as likely to need fixes.

## Architecture (see CLAUDE.md for rules)

```
BloxCore      pure Swift: Model/, Layout/, Reducer/, Config/, Animation/  (no AppKit; lint-enforced)
BloxPlatform  the only OS code: Accessibility/, Hotkeys/, Border/, System/
BloxIPC       Unix socket server/client + Version.swift
BloxApp       composition root (Controller, StatusMenu, main.swift)
BloxCLI       thin `blox` client
```

Flow: OS event -> `Command` -> `reduce(State, Command) -> (State, [Effect])` -> `WindowSystem`
executes effects. State changes only in the reducer. Notable pieces:

- `Reducer/` : `Command`, `CommandParser` (one text grammar for bindings, CLI, config; `a ; b`
  sequences), `Placement`+`PlacementDiff` (state -> desired frames -> minimal effects),
  `ExtraEffects` (focus, exec).
- `Layout/`: dwindle (min-size aware: restacks when windows cannot fit side by side), primary,
  monocle. Windows are a flat ordered list per workspace; directional focus/move come from geometry.
- `State.minSizes`: learned per-window minimum sizes (platform measures 250 ms after placing a
  window; >24 pt over the requested size counts). Only ever grows.
- `Config/`: hand-written TOML subset parser (no dependency). Sections: `[gaps] [layout] [focus]
  [border] [animation] [curves] [rules] [bindings] [mode.<name>]`. Unknown keys are errors with
  line numbers. `[animation] style` picks a preset; `[curves]` defines Hyprland-style beziers.
- Platform: `WindowSystem` (+Windows/Effects/Border/MinimumSize/Notifications), `FrameAnimator`
  (CADisplayLink only while animating, time-based progress), `BorderOverlay`+`Ring` (one
  click-through panel per window, ordered just above its window), `HotkeyCenter`.
- Workspaces are virtual: hidden windows are parked at the bottom-right screen corner (like
  AeroSpace). `quit`/SIGTERM restores them. Native Spaces and native fullscreen are not handled.
- CLI commands: `focus|move <dir>`, `workspace <n>`, `move-to-workspace <n>`, `layout <name>`,
  `resize <delta>`, `balance`, `toggle-floating`, `fullscreen`, `workspace-back-and-forth`,
  `move-workspace-to-monitor`, `mode <m>`, `animation <style|off>`, `exec <cmd>`, `retile`,
  `reload-config`; plus `status`, `reload`, `version`, `--version`.

## Owner preferences (they said these explicitly)

- Keep **AeroSpace keybindings**: `alt-<letter/number>` switches workspace (letters A-Z and 1-9 are
  workspace names), `alt-shift-<key>` moves the window there, `alt-h/j/k/l` focus, `alt-shift-h/j/k/l`
  move, `alt-tab` back-and-forth, resize/service modes. Do not change these.
- Look: hyprdots (Catppuccin mauve->rosewater focused border, soft grey-blue inactive, wind curve
  at 0.5 s). **Subtle UI**; they disliked a thick cyan border.
- Spacing: **0 outer padding, 18 pt between windows** (horizontal and vertical).
- Menu bar like AeroSpace: shows the current workspace letter; clicking lists all workspaces with
  the apps in each and a check on the active one.
- Wants it very light on memory/CPU and a small binary.
- **Never mention the AI in commit messages or PRs** (no co-author trailers, no "generated with").

## Numbers so far

| | Blox v0.0.14 | AeroSpace 0.21.1 |
|---|---|---|
| Memory footprint (3 windows) | 17 MB | 31 MB |
| RSS | 56.5 MB | 101 MB |
| Threads | 4 | 12 |
| Idle CPU | 0.0% | 0.0% |
| Binary | 0.4 MB | 16.6 MB |

Core layout pass: 0.21 ms for 30 windows (debug build); focus move 0.27 ms. Budget 10 ms,
enforced by `PerformanceTests`. These are snapshots, not the full benchmark.

## Benchmark status

`Scripts/bench-compare.swift` (method in `docs/benchmarking.md`) typechecks and its self-test
passes. The live run against AeroSpace was started and **stopped by the owner**; cleanup was done
(test windows closed, workspace restored). It has never completed a run. Run it only with the
owner's consent: it opens up to 20 TextEdit windows and flips workspaces, ~3 min per manager, one
manager at a time, charger plugged in.

## Next steps toward v0.1.0

1. Owner live-tests v0.0.16 (quit AeroSpace, open Blox, grant Accessibility). Fix whatever breaks;
   ask for screenshots. Likely trouble spots are listed under "Never confirmed" above.
2. Run the benchmark for both managers; record results in `docs/benchmarking.md` or a results file.
3. Known gaps, roughly by value: workspace-switch slide animation; fades for window open/close;
   per-app AX queues (AX calls run on the main thread with 1 s timeouts, so one hung app can stall
   tiling); crash recovery for parked windows (a hard kill leaves them offscreen until restart);
   drag-to-swap and focus-follows-mouse; native fullscreen / other Spaces; `join-with` and nested
   containers (deliberately not modelled); per-axis resize (one ratio per workspace today);
   launch-at-login helper; notarization; a stable signing identity.
4. Housekeeping: `docs/adr/` is referenced by CLAUDE.md but does not exist yet; CI workflow
   `.github/workflows/ci.yml` has never run; Periphery is skipped locally (needs full Xcode).
5. When the owner says it is usable: bump to `0.1.0`, `Scripts/release.sh`, tag `v0.1.0`, and
   hand over `dist/Blox-0.1.0.zip`.

## Working in this environment (gotchas that cost time)

- **Command Line Tools only, no Xcode.** Use `Scripts/test.sh` (adds the Testing framework paths)
  and `Scripts/lint.sh` (sets `TOOLCHAIN_DIR` for SwiftLint). Plain `swift test` fails. Periphery
  can't run.
- **Format before lint.** `swiftformat Sources Tests` rewrites code (reflows long calls, turns test
  names into backtick names). Scripted find-and-replace edits break on reformatted text, so read
  the current text first. Strict SwiftLint wants trailing commas in multi-line literals.
- **Lint is strict** (see `.swiftlint.yml`): one declaration per file, functions <= 25 lines, five
  parameters already fail, no force unwraps, no singletons/polling/print, strict memory safety
  needs `unsafe` markers around AX/Carbon/POSIX calls (kept in a few files). Run lint before every
  commit: a chained commit once went through with a lint error and had to be amended.
- **Signing.** There is no code-signing identity on this Mac, so builds are ad-hoc signed and every
  rebuild invalidates the Accessibility approval. Reset with `tccutil reset Accessibility
  dev.blox.Blox` before re-granting. A stable local self-signed certificate would fix this but adds
  a cert to the owner's login keychain, so ask first.
- **Install procedure:** `Scripts/release.sh`, then `ditto dist/Blox.app /Applications/Blox.app`
  (remove the old app first), and keep the CLI symlink at `/opt/homebrew/bin/blox`.
- **The session context's git snapshot can be stale.** Trust `git log`, not the injected status.
- Stopping Blox with SIGTERM restores parked windows; it is safe.
