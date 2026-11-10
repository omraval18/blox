@testable import BloxCore
import CoreGraphics
import Testing

struct MinimumSizeTests {
    private let area = CGRect(x: 0, y: 0, width: 1000, height: 800)

    @Test func `stacks when windows cannot fit side by side`() {
        let result = DwindleLayout().frames(
            count: 2, in: area, ratio: 0.5, minimums: [
                CGSize(width: 600, height: 0),
                CGSize(width: 600, height: 0),
            ],
        )
        #expect(result == [
            CGRect(x: 0, y: 0, width: 1000, height: 400),
            CGRect(x: 0, y: 400, width: 1000, height: 400),
        ])
    }

    @Test func `nudges ratio so the head keeps its minimum`() {
        let result = DwindleLayout().frames(
            count: 2, in: area, ratio: 0.1, minimums: [CGSize(width: 300, height: 0), .zero],
        )
        #expect(result[0] == CGRect(x: 0, y: 0, width: 300, height: 800))
    }

    @Test func `falls back to the normal split when nothing fits`() {
        let big = CGSize(width: 900, height: 900)
        let result = DwindleLayout().frames(count: 2, in: area, ratio: 0.5, minimums: [big, big])
        #expect(result[0].width == 500)
    }

    @Test func `unknown minimums change nothing`() {
        #expect(
            DwindleLayout().frames(count: 3, in: area, ratio: 0.5, minimums: [])
                == DwindleLayout().frames(count: 3, in: area, ratio: 0.5, minimums: [.zero, .zero, .zero]),
        )
    }

    @Test func `learned minimums restack the workspace`() {
        let base = run([.windowAppeared(id(1)), .windowAppeared(id(2))]).0
        let size = CGSize(width: 600, height: 300)
        let (next, effects) = run([.windowMinSize(id(1), size), .windowMinSize(id(2), size)], from: base)
        #expect(frames(of: next) == [
            CGRect(x: 0, y: 0, width: 1000, height: 400),
            CGRect(x: 0, y: 400, width: 1000, height: 400),
        ])
        #expect(effects.contains(.place(id(2), CGRect(x: 0, y: 400, width: 1000, height: 400))))
    }

    @Test func `minimums only grow and ignore unknown windows`() {
        let base = run([.windowAppeared(id(1))]).0
        let first = Command.windowMinSize(id(1), CGSize(width: 500, height: 400))
        let second = Command.windowMinSize(id(1), CGSize(width: 300, height: 600))
        let grown = run([first, second], from: base).0
        #expect(grown.minSizes[id(1)] == CGSize(width: 500, height: 600))
        #expect(run([.windowMinSize(id(9), CGSize(width: 1, height: 1))], from: base).0 == base)
    }

    @Test func `closing A window forgets its minimum`() {
        let (next, _) = run([
            .windowAppeared(id(1)),
            .windowMinSize(id(1), CGSize(width: 500, height: 500)),
            .windowDisappeared(id(1)),
        ])
        #expect(next.minSizes.isEmpty)
    }

    @Test func `overview lists occupied and visible workspaces`() {
        let (state, _) = run([
            .windowAppeared(id(1)),
            .switchWorkspace("B"),
            .windowAppeared(id(2)),
            .switchWorkspace("T"),
        ])
        #expect(state.overview().map(\.name) == ["1", "B", "T"])
        #expect(state.overview().map(\.isFocused) == [false, false, true])
        #expect(state.overview().first?.windows == [id(1)])
        #expect(state.overview().map(\.isVisible) == [false, false, true])
    }
}
