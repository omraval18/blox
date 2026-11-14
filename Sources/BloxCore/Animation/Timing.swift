/// How long a motion takes and how it eases.
public struct Timing: Equatable, Sendable {
    /// Seconds.
    public let duration: Double
    public let curve: Curve
    /// Seconds until the window first reaches its target: earlier than `duration` for curves that
    /// overshoot, since travel is held at the target from then on (ADR 0002).
    public let arrival: Double

    public init(duration: Double, curve: Curve) {
        self.duration = duration
        self.curve = curve
        arrival = Self.firstArrival(of: curve) * duration
    }

    /// How far a window has travelled `elapsed` seconds in: the curve's value held within 0...1.
    /// Overshooting curves keep their shape up to the target but never carry a real window past
    /// it, where it would slide under its neighbour or off the screen and back (ADR 0002). Once
    /// arrived it stays: a curve that rises above 1 and dips back below does not pull it back.
    public func travel(after elapsed: Double) -> Double {
        guard elapsed < arrival else { return 1 }
        return min(max(curve.value(at: elapsed / duration), 0), 1)
    }

    /// The earliest linear time in 0...1 at which `curve` reaches 1: found on a fine grid, then
    /// refined by bisection. A curve that only gets there at the end arrives at 1.
    private static func firstArrival(of curve: Curve) -> Double {
        let samples = 200
        guard let index = (1 ..< samples).first(where: { curve.value(at: Double($0) / Double(samples)) >= 1 })
        else { return 1 }
        var (low, high) = (Double(index - 1) / Double(samples), Double(index) / Double(samples))
        for _ in 0 ..< 30 {
            let middle = (low + high) / 2
            if curve.value(at: middle) >= 1 {
                high = middle
            } else {
                low = middle
            }
        }
        return high
    }
}
