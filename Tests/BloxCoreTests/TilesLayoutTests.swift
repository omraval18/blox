@testable import BloxCore
import CoreGraphics
import Testing

struct TilesLayoutTests {
    private func width(_ low: Double, max high: Double = 0) -> SizeLimits {
        SizeLimits(minimum: CGSize(width: low, height: 0), maximum: CGSize(width: high, height: 0))
    }

    @Test func `windows share the width in one full-height row`() {
        let area = CGRect(x: 0, y: 0, width: 900, height: 600)
        #expect(TilesLayout().frames(count: 3, in: area, ratio: 0.5) == [
            CGRect(x: 0, y: 0, width: 300, height: 600),
            CGRect(x: 300, y: 0, width: 300, height: 600),
            CGRect(x: 600, y: 0, width: 300, height: 600),
        ])
    }

    @Test func `a portrait area stacks them in one column`() {
        let area = CGRect(x: 0, y: 0, width: 600, height: 900)
        #expect(TilesLayout().frames(count: 2, in: area, ratio: 0.5).map(\.height) == [450, 450])
    }

    @Test func `a fixed-width window keeps its width and the rest share what is left`() {
        let area = CGRect(x: 0, y: 0, width: 1000, height: 600)
        let limits = [SizeLimits(), width(0, max: 200), SizeLimits()]
        #expect(TilesLayout().frames(count: 3, in: area, ratio: 0.5, limits: limits).map(\.width) == [
            400,
            200,
            400,
        ])
    }

    @Test func `minimums are kept and impossible ones fall back to equal shares`() {
        #expect(TilesLayout.shares(of: 900, bounds: [(500, 0), (0, 0), (0, 0)]) == [500, 200, 200])
        #expect(TilesLayout.shares(of: 900, bounds: [(600, 0), (600, 0)]) == [450, 450])
    }

    @Test func `tiles is a layout the config and commands accept`() {
        #expect(LayoutKind(rawValue: "tiles") == .tiles)
        #expect(Command(parsing: "layout tiles") == .setLayout(.tiles))
    }
}
