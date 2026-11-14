public extension Config {
    /// Written to disk on first run; also the reference for every available setting.
    static let defaultText = """
    # Blox configuration. Saved changes apply immediately.

    [gaps]
    inner = 8
    outer = 8
    # outer-top = 32   # per-edge override of outer (also outer-bottom, outer-left, outer-right)
    # smart = true     # no gaps around a lone window

    [layout]
    default = "dwindle"   # dwindle | tiles | primary | monocle
    ratio = 0.5

    [focus]
    mouse-follows = false

    # Ring around the focused window. Two or more colors make a gradient.
    [border]
    enabled = false
    width = 3
    radius = 12
    colors = "33ccff 00ff99"
    angle = 45

    # Window movement animation. Pick a style, or set duration and curve yourself.
    # styles: snappy fast hyprland end4 ml4w wind smooth circ quart overshoot bounce
    [animation]
    enabled = false
    duration = 0.18
    curve = "snappy"   # a preset, a [curves] name, or "x1 y1 x2 y2"

    # How a new window arrives: slide | popin [percent] | off. duration and curve are optional.
    [animation.open]
    style = "slide"

    # How a workspace switch looks: slide | off. duration and curve are optional.
    [animation.workspaces]
    style = "slide"

    # Your own bezier curves, as in Hyprland: name = "x1 y1 x2 y2"
    [curves]

    # Per-workspace starting layout and ratio, as in Hyprland workspace rules:
    # [workspace.3]
    # layout = "monocle"
    # ratio = 0.6

    # Per-app rules by bundle id: "workspace <name>" and/or "float"
    [rules]

    [bindings]
    "alt-h" = "focus left"
    "alt-j" = "focus down"
    "alt-k" = "focus up"
    "alt-l" = "focus right"
    "alt-shift-h" = "move left"
    "alt-shift-j" = "move down"
    "alt-shift-k" = "move up"
    "alt-shift-l" = "move right"
    "alt-minus" = "resize -0.05"
    "alt-equal" = "resize 0.05"
    "alt-f" = "toggle-floating"
    "alt-d" = "layout dwindle"
    "alt-p" = "layout primary"
    "alt-m" = "layout monocle"
    "alt-1" = "workspace 1"
    "alt-2" = "workspace 2"
    "alt-3" = "workspace 3"
    "alt-4" = "workspace 4"
    "alt-shift-1" = "move-to-workspace 1"
    "alt-shift-2" = "move-to-workspace 2"
    "alt-shift-3" = "move-to-workspace 3"
    "alt-shift-4" = "move-to-workspace 4"
    """
}
