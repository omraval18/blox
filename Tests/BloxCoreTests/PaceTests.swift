@testable import BloxCore
import Testing

struct PaceTests {
    @Test func `the first sample is the average`() {
        let pace = Pace(first: 0.010)
        #expect(pace.average == 0.010)
        #expect(pace.samples == 1)
    }

    @Test func `later samples move the average part of the way`() {
        var pace = Pace(first: 0.010)
        pace.add(0.020)
        #expect(abs(pace.average - (0.010 + Pace.weight * 0.010)) < 1e-12)
        #expect(pace.samples == 2)
    }

    @Test func `a steady pace converges on the new value`() {
        var pace = Pace(first: 0.002)
        for _ in 0 ..< 60 {
            pace.add(0.015)
        }
        #expect(abs(pace.average - 0.015) < 0.0001)
    }

    @Test func `one spike does not dominate`() {
        var pace = Pace(first: 0.004)
        pace.add(1)
        for _ in 0 ..< 20 {
            pace.add(0.004)
        }
        #expect(pace.average < 0.010)
    }

    @Test func `a frame is late when its work outlasts the frame interval`() {
        #expect(Pace.isLate(work: 0.017, interval: 1.0 / 60))
        #expect(!Pace.isLate(work: 0.015, interval: 1.0 / 60))
        #expect(Pace.isLate(work: 0.009, interval: 1.0 / 120))
        #expect(!Pace.isLate(work: 0.5, interval: 0))
    }
}
