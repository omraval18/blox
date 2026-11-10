public extension Config {
    /// Written to disk on first run; also the reference for every available setting.
    static let defaultText = """
    # Blox configuration. Saved changes apply immediately.

    [gaps]
    inner = 8
    outer = 8

    [layout]
    default = "dwindle"   # dwindle | primary | monocle
    ratio = 0.5

    [focus]
    mouse-follows = false

    # Window movement animation. Pick a style, or set duration and curve yourself.
    # styles: snappy fast hyprland end4 ml4w wind smooth circ quart overshoot bounce
    [animation]
    enabled = false
    duration = 0.18
    curve = "snappy"   # a preset, a [curves] name, or "x1 y1 x2 y2"

    # Your own bezier curves, as in Hyprland: name = "x1 y1 x2 y2"
    [curves]

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
