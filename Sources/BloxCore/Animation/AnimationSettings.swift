public struct AnimationSettings: Equatable, Sendable {
    public var enabled: Bool
    /// Seconds.
    public var duration: Double
    public var curve: Curve

    public init(enabled: Bool = false, duration: Double = 0.18, curve: Curve = .snappy) {
        self.enabled = enabled
        self.duration = duration
        self.curve = curve
    }
}
