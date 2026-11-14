<div align="center">

<img src="docs/logo.png" width="128" alt="Blox logo">

# Blox

**A tiny tiling window manager for macOS.**
AeroSpace-style workspaces and keys. Hyprland-style borders and animation.

![platform](https://img.shields.io/badge/macOS-14%2B-black)
![swift](https://img.shields.io/badge/Swift-6.2-orange)
![size](https://img.shields.io/badge/binary-~0.4%20MB-brightgreen)
![license](https://img.shields.io/badge/license-MIT-blue)

</div>

Blox tiles your windows with the Accessibility API. There is no SIP change, no daemon, no
scripting language and no dependencies. One TOML file configures everything and reloads on save.

> **Status: early (`v0.0.x`).** The core is well tested; real-window behaviour is still being
> confirmed on live setups. Expect rough edges until `v0.1.0`.

## Highlights

- **Three layouts**: `dwindle`, `primary` (one big window plus a stack), `monocle`. Windows that
  cannot shrink enough are restacked instead of overlapping.
- **Virtual workspaces**, AeroSpace-style: hidden windows are parked offscreen, so there are no Space-switch
  animations. Names are free text (`1`-`9`, `A`-`Z`, anything).
- **Multi-monitor**: each display shows its own workspace.
- **Hyprland look**: a gradient ring on the focused window, a softer one on the rest, and bezier-curve animation
  with presets copied from popular `hyprdots` setups. Windows glide into place.
- **Menu bar** shows the current workspace; the menu lists every workspace and the apps in it.
- **App rules** by bundle id: send an app to a workspace or float it.
- **Binding modes** (resize, service, ...) like AeroSpace.
- **CLI** (`blox focus left`) over a private Unix socket.
- **Hot-reloaded config** with line-numbered errors in the menu bar; the last good config stays active.

## Light by design

Everything is event-driven (`AXObserver`, workspace notifications, `RegisterEventHotKey`). No timers, no
polling, and the display link exists only while windows animate.

| 3 windows, idle | Blox | AeroSpace 0.21 |
|---|---|---|
| Memory footprint | **17 MB** | 31 MB |
| Threads | **4** | 12 |
| Binary | **0.4 MB** | 16.6 MB |
| Idle CPU | 0.0% | 0.0% |

A layout pass for 30 windows takes about 0.2 ms; the budget is 10 ms and a test enforces it.
Method and scripts: [`docs/benchmarking.md`](docs/benchmarking.md).

## Install

1. Download `Blox-<version>.zip` from the releases page and move `Blox.app` to `/Applications`.
2. Open it and grant **Accessibility** (System Settings, Privacy & Security, Accessibility), then open it again.
3. Optional CLI: `ln -s /Applications/Blox.app/Contents/Helpers/blox /usr/local/bin/blox`
4. Optional autostart: System Settings, General, Login Items, add Blox.

The app is ad-hoc signed and not notarized, so on first launch right-click and choose Open. Each new
build changes the signature and macOS will ask for Accessibility again.

Build from source (Swift 6.2): `Scripts/release.sh` produces `dist/Blox.app` and a zip.

> Running another tiling manager (AeroSpace, yabai)? Quit it first. Two managers fight over the same
> windows and keys.

## Configure

The first run writes `~/.config/blox/blox.toml`. A full AeroSpace-compatible example lives in
[`examples/aerospace-compat.toml`](examples/aerospace-compat.toml).

```toml
[gaps]
inner = 18
outer = 0

[layout]
default = "dwindle"      # dwindle | primary | monocle
ratio = 0.5

[border]
enabled = true
width = 2
radius = 20
colors = "ca9ee6 f2d5cf"        # focused gradient
inactive = "b4befecc 6c7086cc"  # omit to ring only the focused window

[animation]
style = "hyprdots"       # or: curve = "snappy" | "x1 y1 x2 y2"

[animation.open]         # Hyprland's windowsIn: slide | popin [percent] | off
style = "popin 85"

[animation.workspaces]   # Hyprland's workspaces: slide | off
style = "slide"
duration = 0.3           # each phase may set its own duration and curve

[workspace.3]            # per-workspace starting layout and ratio (Hyprland workspace rules)
layout = "monocle"

[rules]
"com.google.Chrome" = "workspace B"

[bindings]
"alt-h" = "focus left"
"alt-shift-h" = "move left"
"alt-1" = "workspace 1"
```

Sections: `[gaps] [layout] [focus] [border] [animation] [animation.open] [animation.workspaces] [curves] [workspace.<name>] [rules] [bindings] [mode.<name>]`.
Gaps also take `outer-top|bottom|left|right` (per-edge) and `smart = true` (no gaps around a lone window).
Unknown keys are errors with line numbers. Modifiers: `alt`, `ctrl`, `shift`, `cmd`.
Chain commands with `;`, for example `"alt-r" = "mode resize ; layout dwindle"`.

### Commands

Used by bindings and the CLI (`blox <command>`):

| | |
|---|---|
| Focus and move | `focus <dir>`, `move <dir>` (left, right, up, down) |
| Workspaces | `workspace <n>`, `move-to-workspace <n>`, `workspace-back-and-forth`, `move-workspace-to-monitor` |
| Layout | `layout <name>`, `resize <delta>`, `balance`, `toggle-floating`, `fullscreen`, `close` |
| Misc | `mode <name>`, `animation <style\|off>`, `exec <cmd>`, `retile`, `reload-config` |
| Info | `status`, `version` |

## Behaviour and limits

- Only standard, resizable windows are tiled; dialogs, panels and fixed-size windows are left alone.
- Hidden (Cmd-H) apps leave the layout and rejoin when shown; windows that go native full screen leave it too.
- Blox starts without Accessibility access and begins working the moment you grant it; no relaunch.
- Turn off **Displays have separate Spaces** for several monitors. Avoid native Spaces and native full screen:
  Blox manages its own workspaces and only sees the current Space.
- Animation moves real windows through Accessibility, so slow apps can look less smooth.
- macOS does not let a third party blur, shadow or dim other apps' windows without private APIs or
  disabling SIP, so Blox does not try.
- A hard kill leaves windows on hidden workspaces offscreen until Blox starts again. Quitting, `SIGTERM` and
  `SIGINT` restore them first.

## Development

```
Scripts/test.sh     # unit, property and fuzz tests
Scripts/lint.sh     # format, SwiftLint (strict), size gates
Scripts/bench.sh    # memory of the running app
```

The architecture is strict and enforced by lint:

```
BloxCore      pure Swift: model, layouts, reducer, config, animation math (no AppKit)
BloxPlatform  the only code that touches the OS: Accessibility, hotkeys, borders, displays
BloxIPC       socket protocol shared by app and CLI
BloxApp       composition root, wiring only
BloxCLI       thin client
```

State changes only in a pure reducer: `Event -> Command -> reduce(State, Command) -> (State, [Effect])`,
and the platform executes the effects. That makes the core testable without a screen. The test suite
includes a seeded fuzzer that throws random command sequences at the reducer and checks invariants plus a
simulated desktop after every step. Contributor rules are in [`CLAUDE.md`](CLAUDE.md); current state in
[`docs/HANDOFF.md`](docs/HANDOFF.md).

## License

MIT
