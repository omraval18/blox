/// How long a motion takes and how it eases.
public struct Timing: Equatable, Sendable {
    /// Seconds.
    public let duration: Double
    public let curve: Curve

    public init(duration: Double, curve: Curve) {
        self.duration = duration
        self.curve = curve
    }

    /// How far a window has travelled `elapsed` seconds in: the curve's value held within 0...1.
    /// Overshooting curves keep their shape up to the target but never carry a real window past
    /// it, where it would slide under its neighbour or off the screen and back (ADR 0002).
    public func travel(after elapsed: Double) -> Double {
        min(max(curve.value(at: elapsed / duration), 0), 1)
    }
}
