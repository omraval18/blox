public struct AnimationSettings: Equatable, Sendable {
    public var enabled: Bool
    /// Seconds, for windows moving to a new tile. Other phases follow it unless they set their own.
    public var duration: Double
    public var curve: Curve
    public var open = Phase(Entrance.slide)
    public var workspaces = Phase(WorkspaceMotion.slide)

    public init(enabled: Bool = false, duration: Double = 0.18, curve: Curve = .snappy) {
        self.enabled = enabled
        self.duration = duration
        self.curve = curve
    }

    /// Timing for windows moving to a new tile; nil while animation is off.
    public var moveTiming: Timing? {
        timing(of: Phase(0))
    }

    /// Timing for one phase, falling back to the movement timing; nil while animation is off.
    public func timing(of phase: Phase<some Equatable & Sendable>) -> Timing? {
        enabled ? Timing(duration: phase.duration ?? duration, curve: phase.curve ?? curve) : nil
    }

    /// Takes a preset's on/off state, duration and curve and leaves the per-phase choices alone.
    public mutating func applyPreset(_ preset: Self) {
        enabled = preset.enabled
        duration = preset.duration
        curve = preset.curve
    }
}
