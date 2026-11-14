@testable import BloxCore
import CoreGraphics
import Testing

struct SizeLimitLayoutTests {
    private let area = CGRect(x: 0, y: 0, width: 1000, height: 800)

    private func floor(_ width: Double) -> SizeLimits {
        SizeLimits(minimum: CGSize(width: width, height: 0))
    }

    private func ceiling(_ width: Double) -> SizeLimits {
        SizeLimits(maximum: CGSize(width: width, height: 0))
    }

    @Test func `stacks when windows cannot fit side by side`() {
        let result = DwindleLayout().frames(count: 2, in: area, ratio: 0.5, limits: [floor(600), floor(600)])
        #expect(result == [
            CGRect(x: 0, y: 0, width: 1000, height: 400),
            CGRect(x: 0, y: 400, width: 1000, height: 400),
        ])
    }

    @Test func `nudges ratio so the head keeps its minimum`() {
        let result = DwindleLayout().frames(
            count: 2,
            in: area,
            ratio: 0.1,
            limits: [floor(300), SizeLimits()],
        )
        #expect(result[0] == CGRect(x: 0, y: 0, width: 300, height: 800))
    }

    @Test func `falls back to the normal split when nothing fits`() {
        let big = SizeLimits(minimum: CGSize(width: 900, height: 900))
        let result = DwindleLayout().frames(count: 2, in: area, ratio: 0.5, limits: [big, big])
        #expect(result[0].width == 500)
    }

    @Test func `unknown limits change nothing`() {
        #expect(
            DwindleLayout().frames(count: 3, in: area, ratio: 0.5, limits: [])
                == DwindleLayout().frames(
                    count: 3,
                    in: area,
                    ratio: 0.5,
                    limits: Array(repeating: SizeLimits(), count: 3),
                ),
        )
    }

    @Test func `a fixed-width head gives its spare width to the neighbour`() {
        let result = DwindleLayout().frames(
            count: 2,
            in: area,
            ratio: 0.5,
            limits: [ceiling(300), SizeLimits()],
        )
        #expect(result == [
            CGRect(x: 0, y: 0, width: 300, height: 800),
            CGRect(x: 300, y: 0, width: 700, height: 800),
        ])
    }

    @Test func `a fixed-width last window gives its spare width back`() {
        let result = DwindleLayout().frames(
            count: 2,
            in: area,
            ratio: 0.5,
            limits: [SizeLimits(), ceiling(300)],
        )
        #expect(result[1] == CGRect(x: 700, y: 0, width: 300, height: 800))
    }
}
