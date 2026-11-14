@testable import BloxCore
import CoreGraphics
import Testing

/// How the reducer learns, merges and forgets window size limits.
struct SizeLimitTests {
    private func floor(_ width: Double) -> SizeLimits {
        SizeLimits(minimum: CGSize(width: width, height: 0))
    }

    @Test func `a learned maximum keeps the gap between neighbours`() {
        let base = run(
            [.windowAppeared(id(1)), .windowAppeared(id(2))],
            from: makeState(gaps: Gaps(inner: 18)),
        ).0
        let limits = SizeLimits(maximum: CGSize(width: 300, height: 0))
        let tiles = frames(of: run([.windowSizeLimits(id(1), limits)], from: base).0)
        #expect(tiles[0].width == 300)
        #expect(tiles[1].minX - tiles[0].maxX == 18)
        #expect(tiles[1].maxX == screen.maxX)
    }

    @Test func `learned minimums restack the workspace`() {
        let base = run([.windowAppeared(id(1)), .windowAppeared(id(2))]).0
        let limits = SizeLimits(minimum: CGSize(width: 600, height: 300))
        let (next, effects) = run(
            [.windowSizeLimits(id(1), limits), .windowSizeLimits(id(2), limits)],
            from: base,
        )
        #expect(frames(of: next) == [
            CGRect(x: 0, y: 0, width: 1000, height: 400),
            CGRect(x: 0, y: 400, width: 1000, height: 400),
        ])
        #expect(effects.contains(.place(id(2), CGRect(x: 0, y: 400, width: 1000, height: 400))))
    }

    @Test func `minimums only grow, maximums only shrink, unknown windows are ignored`() {
        let base = run([.windowAppeared(id(1))]).0
        let grown = run([
            .windowSizeLimits(id(1), SizeLimits(minimum: CGSize(width: 500, height: 400))),
            .windowSizeLimits(id(1), SizeLimits(minimum: CGSize(width: 300, height: 600))),
            .windowSizeLimits(id(1), SizeLimits(maximum: CGSize(width: 900, height: 0))),
            .windowSizeLimits(id(1), SizeLimits(maximum: CGSize(width: 950, height: 700))),
        ], from: base).0
        #expect(grown.sizeLimits[id(1)] == SizeLimits(
            minimum: CGSize(width: 500, height: 600),
            maximum: CGSize(width: 900, height: 700),
        ))
        #expect(run([.windowSizeLimits(id(9), floor(1))], from: base).0 == base)
    }

    @Test func `closing A window forgets its limits`() {
        let (next, _) = run([
            .windowAppeared(id(1)),
            .windowSizeLimits(id(1), floor(500)),
            .windowDisappeared(id(1)),
        ])
        #expect(next.sizeLimits.isEmpty)
    }

    @Test func `a fixed-width window alone is centred at its own width`() {
        let base = run([.windowAppeared(id(1))]).0
        let limits = SizeLimits(maximum: CGSize(width: 700, height: 0))
        let (next, effects) = run([.windowSizeLimits(id(1), limits)], from: base)
        let centred = CGRect(x: 150, y: 0, width: 700, height: 800)
        #expect(frames(of: next) == [centred])
        #expect(effects.contains(.place(id(1), centred)))
    }
}
