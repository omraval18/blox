/// How long something usually takes, such as an app answering one animation step: an exponential
/// moving average of measured durations, so it follows a change of pace but shrugs off one spike.
public struct Pace: Equatable, Sendable {
    /// Share of each new sample in the average: about the last ten samples count.
    static let weight = 0.2

    /// Seconds.
    public private(set) var average: Double
    public private(set) var samples: Int

    public init(first sample: Double) {
        average = sample
        samples = 1
    }

    public mutating func add(_ sample: Double) {
        average += (sample - average) * Self.weight
        samples += 1
    }

    /// A display frame is late when its work took longer than the frame interval (both seconds):
    /// the next frame was due before this one was done. An unknown interval (0) is never late.
    public static func isLate(work: Double, interval: Double) -> Bool {
        interval > 0 && work > interval
    }
}
