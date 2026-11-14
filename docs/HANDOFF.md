# Blox handoff (state as of v0.0.20)

Read this first in a new session, then `CLAUDE.md` (rules) and `docs/benchmarking.md`.

## What this is

A lightweight tiling window manager for macOS in Swift, built on the Accessibility (AX) API.
AeroSpace-style virtual workspaces and keybindings, Hyprland/hyprdots-style animation and borders,
TOML config with hot reload, CLI over a Unix socket. MIT licensed. Goal: ship **v0.1.0** (first
usable release) once the owner confirms it works on their Mac. Versions are `v0.0.x` patches,
each tagged; `VERSION` and `Sources/BloxIPC/Version.swift` must match (a test checks this).

## Where things stand

- Repo `main` at v0.0.18 plus the `tune/hyprland-feel` branch (v0.0.19, see below). 90 source files,
  29 test files, **149 tests passing**, lint clean.
- **Installed locally**: `/Applications/Blox.app` v0.0.16 (v0.0.18 built, not yet installed), CLI symlinked at `/opt/homebrew/bin/blox`
  (into the app bundle). Blox is **not running**: the owner uses **AeroSpace** as their daily driver
  (start-at-login on). Never launch Blox without their say-so; it tiles every open window and both
  managers fight over the same keys.
- Config in use: `~/.config/blox/blox.toml`, same content as `examples/aerospace-compat.toml`.
  Their AeroSpace dotfiles live in `~/dev/dotfiles` (stow); those were not touched.
- Accessibility permission for Blox was reset (`tccutil reset`) and the app freshly reinstalled so
  the owner can re-grant it. Expect that to be the first thing they do.

## v0.0.19 (branch `tune/hyprland-feel`, not yet merged or tagged)

Built without launching Blox: AeroSpace was running on the owner's desktop, and it tiles every
window, so any live run would have fought it. Everything below is verified by unit tests, build and
lint only, and **none of the platform behaviour has been seen on real windows**.

- Hyprland-style animation phases: `[animation.open]` (`slide|popin [pct]|off`) and
  `[animation.workspaces]` (`slide|off`), each with optional `duration` and `curve`
  (ADR 0001). The `animation <style>` command and `style =` keep the phase choices.
- Workspace slide: reducer emits `Effect.slide(direction)`; `WindowSystem+Transitions` and
  `FrameAnimator` (`AnimationTrack.Finish.park`) glide windows off/on an edge.
- Smoothness: frames snap to whole points and unchanged ones skip the AX round trip; progress is
  taken at the display link's `targetTimestamp`; the animation cap rose from 6 to 8 movers; border
  rings only rebuild their path on resize.
- Fixes found by reading the code against AeroSpace: Cmd-H apps leave the layout and rejoin on
  unhide (no hole, no ghost ring); windows that go native fullscreen leave tiling; windows that are
  not tileable yet at creation get one retry 250 ms later; Blox waits for the Accessibility grant
  (distributed notification) instead of exiting, so a rebuilt, re-signed binary needs no relaunch.
- Config: `[gaps] outer-top|bottom|left|right` and `smart`, `[workspace.<name>] layout|ratio`,
  workspace names sort numerically (`2` before `10`), new `close` command.
- Look first at (unverified): the slide on a real multi-window switch, popin start frames, the
  fullscreen/hide handling, and whether apps keep up with 8 simultaneous movers.
- Not done, deliberately: `slidevert` (macOS keeps windows below the menu bar), border spin
  (`borderangle`, would need an always-running animation), window fade (no AX opacity), per-app AX
  queues (needs non-Sendable AX types off the main actor; since done for frame setting, ADR 0003).

## Menu bar redesign (on `tune/hyprland-feel`, uncommitted at time of writing)

- The bar item is a template pill with the current workspace (filled; outlined plus the mode name
  while a non-main mode is active; ` !` on a config error). `StatusBadge`.
- The menu lists only workspaces in use (holding windows or on a display), not every configured
  name: a header with the focused workspace set large, rows with a name badge, app icons and names,
  a window count, native footer items with symbols. Typing a workspace's key while open switches.
- Items are built in `menuNeedsUpdate`, so while closed a state change only redraws the pill
  (it used to rebuild the whole NSMenu on every focus change).
- Verified by an offscreen render of the views in light and dark; the live menu (highlight via
  `menu(_:willHighlight:)`, click via `performActionForItem`, key equivalents) is unverified.

## Live-test fixes (2026-11-14)

- Border rings follow the window's real frame: windows subscribe to AX moved/resized, and
  `WindowSystem.reshaped` redraws the ring when Blox is not animating that window. Before, rings
  sat at the requested frame, so a clamped window (System Settings) had a ring around empty space.
- `State.minSizes` became `State.sizeLimits` (`SizeLimits`: minimum and maximum). Platform's
  `checkSizeLimits` reports a window that settles >24 pt smaller than its tile as a maximum, and
  dwindle clamps its split so the spare width goes to the neighbour and the gap stays constant.
  Risk: a learned maximum lasts for the window's lifetime, so an app slower than 250 ms to finish
  resizing could be mis-learned as fixed-size.
- Hidden windows stay hidden. Traced live: macOS clamps a window sliding off-screen so 40 pt stay
  visible, which left a strip at the edge (overlapping the incoming workspace) until the slide
  ended. `AnimationTrack.Finish.park(leaving:)` now parks a window once <= 48 pt remain on its
  screen. And `WindowSystem+Reshape` re-parks a hidden window that comes back on screen (seen:
  Ghostty full-screen behind the active workspace), once per hide, so an app that insists wins
  rather than ping-ponging.
- Border rings no longer resize their panel per animation frame (a window-server surface
  reallocation each step, which made the ring trail a growing window). While animating, `Ring`
  grows its panel once to the screen and moves only layers; `settle()` (animation landed, unanimated
  unpark, app reshape) shrinks it back. The ring shape is a `CALayer` border mask, not a CGPath.
- Startup snaps instead of animating. Adopting each existing window re-tiled the rest, so every
  window glided (and resized) through N layouts at once and the first seconds felt laggy.
  `Adoption.collecting` holds the last frame per window during `start()` and `placePending()`
  applies each once, without animation (as AeroSpace does). New windows still animate.
- Animation glitches, traced live: ring panels faded out on hide (a ghost ring for ~50 ms after a
  workspace switch), fixed with `animationBehavior = .none`; overshooting curves carried windows
  16 pt past their tile (under neighbours, off the screen edge) and re-grew ring panels every
  frame, fixed by `Timing.travel(after:)` clamping to 0...1 (ADR 0002).
- Fixed-size windows: once a maximum is learned, `SizeLimits.fitting` asks for exactly that size,
  centred in the tile (System Settings alone on a workspace sits centred). On landing,
  `fitBorder` reads the real frame, since an app that refuses a size sends no AX notification, so
  the ring used to stay at the tile size. Fuzzing this exposed an old bug: a tile thinner than
  the gap became `CGRect.null` (sent to AX as garbage). `Tiling.inset` now collapses it to zero
  size inside the usable area, and the fuzz invariant rejects non-finite tiles.
- New `tiles` layout (AeroSpace's default `tiles` + `auto` orientation: one row of full-height
  windows sharing the width, one column on portrait). Respects size limits by water-filling
  (`TilesLayout.shares`). Ignores `ratio`, so `resize` does nothing in it yet. The owner's config
  and `examples/aerospace-compat.toml` now default to it; `alt-slash` = tiles,
  `alt-shift-slash` = dwindle. The built-in default stays dwindle.
- Ring lag during animations. Rings now follow the window's real bounds, not the requested
  frame: after each AX step, `followBorder` asks the window server (`WindowServer.bounds`,
  ~0.1 ms, no app round trip) and the ring is flushed per window (`CATransaction.flush()`).
  Requested frames are wrong for apps that refuse sizes: System Settings is fixed-width, so its
  ring glided through sizes the window never took (the owner saw "lag on System Settings only";
  measured AX latency there is ordinary, 4-7 ms). `WindowSystem+Reshape` gathers AX move/resize
  reports for one frame (16 ms) per window; `Ring.move`/`settle` skip no-op work. Not seen on
  screen by the assistant: this terminal lacks Screen Recording permission, and the owner's
  recordings were temp files deleted before they could be read.
- Animations end on arrival (slice 1). `Timing.arrival` (Core, `Timing.swift`) is the first time
  the clamped curve reaches 1; `AnimationTrack.position(at:)` reports done there instead of at
  `duration`, so a `wind` move ends at ~0.08 s of 0.28 s: the ring panel settles, reshape rechecks
  and the size-limit check run as soon as the window lands. Unverified on real windows.
- Geometry reads from the window server (slice 2). `WindowSystem.realFrame(of:)`
  (`WindowSystem+Windows`) asks `WindowServer.bounds` first (~0.1 ms, no app round trip) and AX
  only as a fallback; used by `park`, both reads in `recheck`, `fitBorder`, `checkSizeLimits` and
  `adopt`. Attribute reads, `refreshBorder` and the mouse-follows-focus read still use AX.
  Unverified: whether the window server reflects a park move immediately in `recheck`'s second
  read (if it lags, the window is just treated as refusing parking, which is the cautious side).
- `blox stats` (slice 3). `AnimationStats` (Platform) counts display-link frames, late frames
  (tick work longer than `targetTimestamp - timestamp`) and, per app pid, an EMA of how long one
  `setStep` takes, kept apart for resizing and move-only steps. The EMA and the late rule are
  `Pace` in Core (tested). Updated only inside ticks; an app's entry is dropped in `detach`.
  Served by `Controller+Requests` (`stats`) via `WindowSystem.animationStats`. Unverified: the
  numbers on real apps (never run), and the reply over the live socket.
  To stay under the type-length limit, `FrameAnimator` lost its display link to `DisplayClock` and
  its AX writes (and the timing around them) to `FrameWriter`; behaviour unchanged.
- Adaptive resize for slow apps (slice 4). Core: `ResizeMode(averageResizeStep:)` picks
  `.everyFrame` or `.once` (threshold `ResizeMode.slowResizeStep` = 8 ms; unmeasured apps animate
  fully, which is how they get measured) and `Glide` (`.blend`, `.shrinkFirst`, `.growLast`) gives
  each step's frame; tested. Platform: `FrameWriter.begin` reads the app's resize pace from
  `AnimationStats`; a shrinking window takes its final size before it moves, a growing one glides
  at its old size and takes the final size in `arrive(.settle)`. Size is compared by area, so a
  window that grows on one axis and shrinks on the other is treated as one or the other. Parking
  tracks keep `.blend`. `FrameAnimator`'s tracks moved to `Tracks` to stay under the type-length
  limit. Unverified on real windows: how a once-resized Chromium window looks, and whether the
  8 ms threshold is right (check `blox stats`).
- `AXEnhancedUserInterface` off while Blox sets frames (slice 5), **unverified**. `EnhancedInterface`
  (Platform/Accessibility) keeps a per-pid use count: the app attribute is read once when its
  first frame change starts, switched off only if it was on, and switched back on when the last
  ends. Uses are held by `FrameAnimator.move` (one hold per call, so a snap reads it once) and by
  each running track (released on landing, `forget`, snap-over). `FrameWriter.place` holds too, so
  `unpark` (now routed through it) and snaps are covered; the instant park in `park` and the
  re-park in `recheck` (position-only moves) are not. Restored for all apps in
  `restoreParked()` (quit); dropped without restoring when the app quits (`detach`). No effect at
  all on apps where the attribute is already off, which is the usual case; cost there is one
  extra AX read per move or snap. Never seen on a real Chromium/Electron app with it on.
- Per-app frame channels (slice 6, ADR 0003), **unverified on real windows; the riskiest change
  of the day**. `FrameWriter` no longer calls AX: it submits `FrameStep`s (`resize`, `move`,
  `place`, `settle`, `park`) to one `AppChannel` actor per pid, which owns its own `AXUIElement`s
  (resolved by `WindowID` from the app's window list, cached), runs on its own serial dispatch
  queue, applies steps, times them and hops to the main actor (`WindowSystem.applied`: ring
  follows window-server bounds, flush, `settled` for `settle`). The mailbox is
  `OSAllocatedUnfairLock<AppQueue>`; `AppQueue`/`StepQueue` (Core, tested) do latest-frame-wins
  merging, keep final steps in order, and now decide the `AXEnhancedUserInterface` switching from
  slice 5 (the old `EnhancedInterface` state machine became plain calls). Quit
  (`restoreParked`) is synchronous: close channels, wait for each one's current call, restore the
  setting, then set parked frames directly. Unpark without a slide is now a snap through
  `animator.move(timing: nil)`, so it also runs the size-limit check. `blox stats` late frames now
  count only main-actor work per tick. Look first at: rings during fast moves (updates are now
  asynchronous), workspace switches with several apps, Blox quitting while an app is hung.

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
  `reload-config`; plus `status`, `stats`, `reload`, `version`, `--version`.

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

0. Merge `tune/hyprland-feel` (PR), tag `v0.0.19`.
1. Owner live-tests v0.0.19 (quit AeroSpace, open Blox, grant Accessibility). Fix whatever breaks;
   ask for screenshots. Likely trouble spots are listed under "Never confirmed" above.
2. Run the benchmark for both managers; record results in `docs/benchmarking.md` or a results file.
3. Known gaps, roughly by value: fades for window open/close;
   the AX calls still on the main actor (focus/raise, adoption, attribute reads, close: one hung
   app can still stall these; frame setting runs per app since ADR 0003); crash recovery for parked windows (a hard kill leaves them offscreen until restart);
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
