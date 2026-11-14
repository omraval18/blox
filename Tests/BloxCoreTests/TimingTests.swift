@testable import BloxCore
import Testing

struct TimingTests {
    @Test func `an overshooting curve arrives before its time is up`() {
        let timing = Timing(duration: 0.28, curve: .wind)
        #expect(timing.arrival < timing.duration * 0.6)
        #expect(timing.travel(after: timing.arrival) == 1)
        #expect(timing.travel(after: timing.arrival * 0.95) < 1)
    }

    @Test(arguments: [Curve.linear, .easeOut, .easeInOut, .snappy])
    func `a curve that only reaches one at the end arrives at the end`(curve: Curve) {
        let timing = Timing(duration: 0.5, curve: curve)
        #expect(abs(timing.arrival - timing.duration) < 0.005)
        #expect(timing.travel(after: timing.arrival) == 1)
    }

    @Test func `travel holds at the target after first arrival`() throws {
        let curve = try #require(Curve(parsing: "0.34 1.56 0.64 1"))
        let timing = Timing(duration: 1, curve: curve)
        #expect(timing.arrival < 1)
        #expect((0 ... 20).allSatisfy { timing.travel(after: timing.arrival + Double($0) / 20) == 1 })
    }

    @Test func `timings with the same duration and curve are equal`() {
        #expect(Timing(duration: 0.3, curve: .wind) == Timing(duration: 0.3, curve: .wind))
        #expect(Timing(duration: 0.3, curve: .wind) != Timing(duration: 0.4, curve: .wind))
    }
}
