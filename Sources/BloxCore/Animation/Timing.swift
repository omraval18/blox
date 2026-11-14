/// How long a motion takes and how it eases.
public struct Timing: Equatable, Sendable {
    /// Seconds.
    public let duration: Double
    public let curve: Curve

    public init(duration: Double, curve: Curve) {
        self.duration = duration
        self.curve = curve
    }
}
