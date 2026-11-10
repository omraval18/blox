@testable import BloxCore
import CoreGraphics
import Testing

/// Guards the "layout pass under 10 ms" budget in CLAUDE.md. Debug builds are several times slower
/// than release, so passing here leaves a wide margin.
struct PerformanceTests {
    private func crowded(windows: UInt32) -> State {
        run((1 ... windows).map { .windowAppeared(id($0)) }).0
    }

    @Test func `retiling thirty windows stays within budget`() {
        let state = crowded(windows: 30)
        let clock = ContinuousClock()
        let runs = 200
        let elapsed = clock.measure {
            for _ in 0 ..< runs {
                _ = reduce(state, .retile)
            }
        }
        #expect(elapsed / runs < .milliseconds(10), "average \(elapsed / runs) per retile")
    }

    @Test func `focus navigation stays within budget`() {
        let state = crowded(windows: 30)
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            for _ in 0 ..< 200 {
                _ = reduce(state, .focus(.left))
            }
        }
        #expect(elapsed / 200 < .milliseconds(10), "average \(elapsed / 200) per focus move")
    }
}
