@testable import BloxCore
import Testing

struct WorkspaceSlideTests {
    private func slides(_ commands: [Command], from state: State = makeState()) -> [Direction] {
        run(commands, from: state).1.compactMap { effect in
            if case let .slide(direction) = effect {
                direction
            } else {
                nil
            }
        }
    }

    @Test func `moving to a later workspace slides left, to an earlier one right`() {
        #expect(slides([.switchWorkspace("2")]) == [.left])
        let on3 = run([.switchWorkspace("3")]).0
        #expect(slides([.switchWorkspace("2")], from: on3) == [.right])
    }

    @Test func `the hint comes before the placements it describes`() {
        let state = run([.windowAppeared(id(1))]).0
        let effects = run([.switchWorkspace("2")], from: state).1
        #expect(effects.first == .slide(.left))
        #expect(effects.contains(.park(id(1))))
    }

    @Test func `no hint without a workspace change`() {
        #expect(slides([.focus(.left), .resize(0.05), .setLayout(.monocle)]).isEmpty)
        #expect(slides([.switchWorkspace("1")]).isEmpty)
    }

    @Test func `numbers sort numerically and before letters`() {
        #expect(WorkspaceOrder.precedes("2", "10"))
        #expect(WorkspaceOrder.precedes("9", "A"))
        #expect(!WorkspaceOrder.precedes("B", "A"))
        let on10 = run([.switchWorkspace("10")]).0
        #expect(slides([.switchWorkspace("A")], from: on10) == [.left])
    }

    @Test func `close targets the focused window and leaves state alone`() {
        let state = run([.windowAppeared(id(1)), .windowAppeared(id(2))]).0
        let (next, effects) = reduce(state, .close)
        #expect(effects == [.close(id(2))])
        #expect(next == state)
        #expect(reduce(makeState(), .close).1.isEmpty)
        #expect(Command(parsing: "close") == .close)
    }
}
