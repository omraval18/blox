@testable import BloxCore
import CoreGraphics
import Testing

struct CurveTests {
    @Test(arguments: [Curve.linear, .easeOut, .easeInOut, .snappy])
    func `curves start at zero and end at one`(curve: Curve) {
        #expect(abs(curve.value(at: 0)) < 1e-6)
        #expect(abs(curve.value(at: 1) - 1) < 1e-6)
    }

    @Test func `linear is identity`() {
        for step in 0 ... 10 {
            let time = Double(step) / 10
            #expect(abs(Curve.linear.value(at: time) - time) < 1e-4)
        }
    }

    @Test func `ease out is front loaded and monotonic`() {
        #expect(Curve.easeOut.value(at: 0.5) > 0.5)
        let samples = (0 ... 20).map { Curve.easeOut.value(at: Double($0) / 20) }
        #expect(samples == samples.sorted())
    }

    @Test func `overshoot curve exceeds one`() throws {
        let curve = try #require(Curve(parsing: "0.34 1.56 0.64 1"))
        #expect((0 ... 100).contains { curve.value(at: Double($0) / 100) > 1.01 })
    }

    @Test func `out of range time is clamped`() {
        #expect(Curve.snappy.value(at: -1) == Curve.snappy.value(at: 0))
        #expect(Curve.snappy.value(at: 9) == Curve.snappy.value(at: 1))
    }

    @Test func `parses presets and numbers`() {
        #expect(Curve(parsing: "snappy") == .snappy)
        #expect(Curve(parsing: "0.2 0.8 0.2 1") == .snappy)
    }

    @Test(arguments: ["", "bouncy", "0.2 0.8 0.2", "2 0 0 1", "0 0 0 9", "a b c d"])
    func `rejects invalid curves`(text: String) {
        #expect(Curve(parsing: text) == nil)
    }

    @Test func `interpolates frames`() {
        let start = CGRect(x: 0, y: 0, width: 100, height: 100)
        let end = CGRect(x: 100, y: 50, width: 300, height: 200)
        #expect(start.interpolated(to: end, progress: 0) == start)
        #expect(start.interpolated(to: end, progress: 1) == end)
        #expect(start.interpolated(to: end, progress: 0.5) == CGRect(x: 50, y: 25, width: 200, height: 150))
    }

    @Test func `windows never travel past their target, even on overshooting curves`() {
        let timing = Timing(duration: 1, curve: .wind)
        #expect((0 ... 100).map { Double($0) / 100 }.contains { Curve.wind.value(at: $0) > 1 })
        #expect((0 ... 100).allSatisfy { timing.travel(after: Double($0) / 100) <= 1 })
        #expect(timing.travel(after: -1) == 0)
        #expect(timing.travel(after: 2) == 1)
    }
}
