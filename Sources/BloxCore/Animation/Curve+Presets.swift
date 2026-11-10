/// Named curves, taken from widely used Hyprland configs (Hyprland defaults, end-4, ML4W,
/// JaKooLit, and others), so their names and feel carry over.
extension Curve {
    public static let linear = Self(0, 0, 1, 1)
    public static let easeOut = Self(0, 0, 0.58, 1)
    public static let easeInOut = Self(0.42, 0, 0.58, 1)
    public static let snappy = Self(0.2, 0.8, 0.2, 1)
    static let easeOutQuint = Self(0.23, 1, 0.32, 1)
    static let easeInOutCubic = Self(0.65, 0.05, 0.36, 1)
    static let easeOutExpo = Self(0.16, 1, 0.3, 1)
    static let easeInOutCirc = Self(0.85, 0, 0.15, 1)
    static let easeInOutQuart = Self(0.76, 0, 0.24, 1)
    static let decel = Self(0.05, 0.7, 0.1, 1)
    static let smooth = Self(0.25, 0.1, 0.25, 1)
    static let wind = Self(0.05, 0.9, 0.1, 1.05)
    static let overshoot = Self(0.13, 0.99, 0.29, 1.15)
    static let bounce = Self(0.34, 1.56, 0.64, 1)
    static let quick = Self(0.15, 0, 0.1, 1)
    static let almostLinear = Self(0.5, 0.5, 0.75, 1)

    static let presets: [String: Self] = [
        "linear": linear, "ease-out": easeOut, "ease-in-out": easeInOut, "snappy": snappy,
        "ease-out-quint": easeOutQuint, "ease-in-out-cubic": easeInOutCubic,
        "ease-out-expo": easeOutExpo, "ease-in-out-circ": easeInOutCirc,
        "ease-in-out-quart": easeInOutQuart, "decel": decel, "smooth": smooth, "wind": wind,
        "overshoot": overshoot, "bounce": bounce, "quick": quick, "almost-linear": almostLinear,
    ]
}
