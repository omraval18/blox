@testable import BloxCore
import CoreGraphics
import Testing

struct GapTests {
    @Test func `a side override replaces the outer gap on that edge only`() {
        var gaps = Gaps(inner: 0, outer: 10)
        gaps.outerTop = 40
        let frame = Tiling.frames(workspace(.monocle, count: 1), in: screen, gaps: gaps)[0]
        #expect(frame == CGRect(x: 10, y: 40, width: 980, height: 750))
    }

    @Test func `smart gaps remove every gap around a lone window only`() {
        var gaps = Gaps(inner: 10, outer: 20)
        gaps.smart = true
        var state = makeState(gaps: gaps)
        state.settings.gaps = gaps
        let one = run([.windowAppeared(id(1))], from: state).0
        #expect(frames(of: one) == [screen])
        let two = run([.windowAppeared(id(2))], from: one).0
        #expect(frames(of: two).allSatisfy { $0.minY == 20 })
    }
}
