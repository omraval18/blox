/// Ready-made animation feels. Each is a curve plus duration (Hyprland's `speed` is in tenths of
/// a second; these are tuned shorter because windows are moved through Accessibility).
public enum AnimationStyle {
    private static let styles: [String: (duration: Double, curve: Curve)] = [
        "snappy": (0.18, .snappy),
        "fast": (0.15, .easeOutExpo),
        "hyprland": (0.30, .easeOutQuint),
        "end4": (0.28, .decel),
        "ml4w": (0.40, Curve(0.05, 0.9, 0.1, 1)),
        "wind": (0.35, .wind),
        "smooth": (0.30, .smooth),
        "circ": (0.35, .easeInOutCirc),
        "quart": (0.35, .easeInOutQuart),
        "overshoot": (0.40, .overshoot),
        "bounce": (0.45, .bounce),
    ]

    public static var names: [String] {
        styles.keys.sorted()
    }

    /// The style as enabled settings, or nil for an unknown name.
    public static func named(_ name: String) -> AnimationSettings? {
        styles[name].map { AnimationSettings(enabled: true, duration: $0.duration, curve: $0.curve) }
    }
}
