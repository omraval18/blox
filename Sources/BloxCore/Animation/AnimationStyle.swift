/// Ready-made animation feels. Each is a curve plus duration. The `hyprdots` family is copied
/// from prasanthrangan/hyprdots with its window-move curve and speed unchanged (Hyprland's
/// `speed` is in tenths of a second); the others are tuned shorter.
public enum AnimationStyle {
    private static let styles: [String: (duration: Double, curve: Curve)] = [
        "hyprdots": (0.50, .wind),
        "classic": (0.70, .wind),
        "diablo": (0.60, .diabloBounce),
        "diablo-overshoot": (0.60, .diabloOvershoot),
        "minimal": (0.60, .easeOutQuart),
        "moving": (0.40, .smoothIn),
        "optimized": (0.30, .optimizedWind),
        "vertical": (0.15, .easeInOutSine),
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
