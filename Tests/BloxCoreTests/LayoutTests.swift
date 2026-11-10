@testable import BloxCore
import CoreGraphics
import Testing

struct LayoutTests {
    @Test func `dwindle halves the remainder`() {
        let result = DwindleLayout().frames(count: 3, in: screen, ratio: 0.5)
        #expect(result == [
            CGRect(x: 0, y: 0, width: 500, height: 800),
            CGRect(x: 500, y: 0, width: 500, height: 400),
            CGRect(x: 500, y: 400, width: 500, height: 400),
        ])
    }

    @Test func `single window fills area and zero is empty`() {
        #expect(DwindleLayout().frames(count: 1, in: screen, ratio: 0.5) == [screen])
        #expect(DwindleLayout().frames(count: 0, in: screen, ratio: 0.5).isEmpty)
        #expect(PrimaryLayout().frames(count: 0, in: screen, ratio: 0.5).isEmpty)
    }

    @Test func `primary stacks the rest`() {
        let result = PrimaryLayout().frames(count: 3, in: screen, ratio: 0.6)
        #expect(result[0] == CGRect(x: 0, y: 0, width: 600, height: 800))
        #expect(result[1] == CGRect(x: 600, y: 0, width: 400, height: 400))
        #expect(result[2] == CGRect(x: 600, y: 400, width: 400, height: 400))
    }

    @Test func `monocle shares one frame`() {
        #expect(MonocleLayout().frames(count: 3, in: screen, ratio: 0.5) == Array(
            repeating: screen,
            count: 3,
        ))
    }

    @Test func `gaps keep exact spacing`() {
        let result = Tiling.frames(
            workspace(.dwindle, count: 2),
            in: screen,
            gaps: Gaps(inner: 10, outer: 20),
        )
        #expect(result[0].minX == 20 && result[0].minY == 20)
        #expect(result[1].minX - result[0].maxX == 10)
        #expect(screen.maxX - result[1].maxX == 20)
        #expect(screen.maxY - result[1].maxY == 20)
    }

    @Test func `ratio is clamped`() {
        let result = Tiling.frames(workspace(.primary, count: 2, ratio: 5), in: screen, gaps: Gaps())
        #expect(result[0].width == 900)
    }
}
