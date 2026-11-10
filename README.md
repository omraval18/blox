# Blox

A tiny tiling window manager for macOS. Keyboard-driven, configured with one TOML file, no
dependencies, no SIP changes. The whole app is about 260 KB.

- **Tiling** with three layouts: `dwindle`, `primary` (one big window and a stack), `monocle`.
- **Virtual workspaces** (windows are parked offscreen, so there are no Space-switch animations).
- **Multi-monitor**: each display shows its own workspace.
- **Hot-reloaded config** with line-numbered errors shown in the menu bar.
- **Optional animation** with bezier curves.
- **CLI** (`blox focus left`) over a private Unix socket.
- Idle cost is near zero: everything is event-driven; there are no timers or polling.

## Install

1. Download `Blox-<version>.zip` from the releases page and move `Blox.app` to `/Applications`.
2. Open it. Grant **Accessibility** access when asked (System Settings → Privacy & Security →
   Accessibility), then open it again.
3. Optional CLI: `ln -s /Applications/Blox.app/Contents/Helpers/blox /usr/local/bin/blox`
4. Optional autostart: System Settings → General → Login Items → add Blox.

The app is ad-hoc signed, not notarized. On first launch, right-click → Open. Rebuilding or
updating changes the signature, so macOS may ask you to grant Accessibility again.

Build from source: `Scripts/release.sh` (needs the Swift 6.2 toolchain).

## Configure

The first run writes `~/.config/blox/blox.toml`. Edit it and save; changes apply immediately.
Mistakes show as `▦!` in the menu bar with the line number; the previous config stays active.

```toml
[gaps]
inner = 8
outer = 8

[layout]
default = "dwindle"   # dwindle | primary | monocle
ratio = 0.5

[animation]
enabled = false
duration = 0.18
curve = "snappy"      # linear | ease-out | ease-in-out | snappy | "x1 y1 x2 y2"

[bindings]
"alt-h" = "focus left"
"alt-shift-h" = "move left"
"alt-1" = "workspace 1"
```

Commands (used by bindings and the CLI): `focus|move <left|right|up|down>`, `workspace <name>`,
`move-to-workspace <name>`, `layout <name>`, `resize <±delta>`, `toggle-floating`, `retile`.
Modifiers: `alt`, `ctrl`, `shift`, `cmd`. Workspace names are free text.

## Behaviour and limits

- Only standard, resizable windows are tiled. Dialogs, panels and fixed-size windows are left alone.
- Turn off **Displays have separate Spaces** if you use several monitors, and avoid native Spaces
  and native full screen: Blox manages its own workspaces and only sees windows on the current Space.
- Animation moves windows with the Accessibility API, so apps that resize slowly may look less
  smooth. It is off by default; windows snap instantly.
- If Blox is killed hard (not quit), windows on hidden workspaces stay offscreen. Start Blox
  again and they are brought back.
- Quitting from the menu, or `SIGTERM`/`SIGINT`, restores hidden windows first.

## Development

```
Scripts/test.sh    # unit tests
Scripts/lint.sh    # formatting, lint, file-size gate
```

Layout: `BloxCore` is pure logic (no AppKit); `BloxPlatform` is the only code that touches the
OS; `BloxIPC` is the socket protocol; `BloxApp` wires them together. See `CLAUDE.md` for the rules.

## License

MIT
