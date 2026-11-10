@testable import BloxCore
import CoreGraphics
import Testing

struct ReducerTests {
    @Test func `new window is placed and focused`() {
        let (state, effects) = run([.windowAppeared(id(1))])
        #expect(effects.contains(.place(id(1), screen)))
        #expect(effects.last == .focus(id(1)))
        #expect(state.focusedWindow == id(1))
    }

    @Test func `ruled window on a hidden workspace is focused there`() {
        var state = makeState()
        state.settings.rules = ["chat": WindowRule(workspace: "2")]
        let (next, effects) = run([.windowAppeared(id(1), app: "chat")], from: state)
        #expect(next.workspaces["2"]?.focused == id(1))
        #expect(effects.contains(.park(id(1))))
        #expect(!effects.contains(.focus(id(1))))
    }

    @Test func `duplicate appear is ignored`() {
        let (state, _) = run([.windowAppeared(id(1)), .windowAppeared(id(1))])
        #expect(state.workspaces["1"]?.tiled == [id(1)])
    }

    @Test func `new window inserts after focused`() {
        let (state, _) = run([
            .windowAppeared(id(1)),
            .windowAppeared(id(2)),
            .focusChanged(id(1)),
            .windowAppeared(id(3)),
        ])
        #expect(state.workspaces["1"]?.tiled == [id(1), id(3), id(2)])
    }

    @Test func `closing window retiles and refocuses`() {
        let (state, effects) = run([
            .windowAppeared(id(1)),
            .windowAppeared(id(2)),
            .windowDisappeared(id(2)),
        ])
        #expect(state.focusedWindow == id(1))
        #expect(effects.last == .focus(id(1)))
        #expect(frames(of: state) == [screen])
    }

    @Test func `os focus change emits no focus effect`() {
        let base = run([.windowAppeared(id(1)), .windowAppeared(id(2))]).0
        let (_, effects) = reduce(base, .focusChanged(id(1)))
        #expect(effects.isEmpty)
    }

    @Test func `focus and move follow geometry`() {
        let base = run([.windowAppeared(id(1)), .windowAppeared(id(2)), .windowAppeared(id(3))]).0
        #expect(base.focusedWindow == id(3))
        #expect(run([.focus(.up)], from: base).0.focusedWindow == id(2))
        #expect(run([.focus(.left)], from: base).0.focusedWindow == id(1))
        #expect(run([.focus(.down)], from: base).0.focusedWindow == id(3))
        let moved = run([.move(.up)], from: base).0
        #expect(moved.workspaces["1"]?.tiled == [id(1), id(3), id(2)])
    }

    @Test func `monocle cycles focus`() {
        let base = run([.windowAppeared(id(1)), .windowAppeared(id(2)), .setLayout(.monocle)]).0
        #expect(run([.focus(.right)], from: base).0.focusedWindow == id(1))
    }

    @Test func `switching workspace parks and restores`() {
        let base = run([.windowAppeared(id(1))]).0
        let (away, parked) = reduce(base, .switchWorkspace("2"))
        #expect(parked == [.park(id(1))])
        #expect(away.focusedWindow == nil)
        let (_, restored) = reduce(away, .switchWorkspace("1"))
        #expect(restored == [.place(id(1), screen), .focus(id(1))])
    }

    @Test func `move to workspace parks window and focuses next`() {
        let base = run([.windowAppeared(id(1)), .windowAppeared(id(2))]).0
        let (state, effects) = reduce(base, .moveToWorkspace("2"))
        #expect(state.workspaces["2"]?.tiled == [id(2)])
        #expect(effects.contains(.park(id(2))))
        #expect(state.focusedWindow == id(1))
    }

    @Test func `floating windows leave the layout and return`() {
        let base = run([.windowAppeared(id(1)), .windowAppeared(id(2))]).0
        let floated = run([.toggleFloating], from: base).0
        #expect(frames(of: floated) == [screen])
        #expect(floated.workspaces["1"]?.floating == [id(2)])
        #expect(run([.toggleFloating], from: floated).0.workspaces["1"]?.tiled == [id(1), id(2)])
    }

    @Test func `resize adjusts and clamps ratio`() {
        let (state, _) = run([.resize(0.2), .resize(5)])
        #expect(state.workspaces["1"]?.ratio == 0.9)
    }

    @Test func `focusing hidden workspace window surfaces it`() {
        let (away, _) = reduce(run([.windowAppeared(id(1))]).0, .switchWorkspace("2"))
        let (state, effects) = reduce(away, .focusChanged(id(1)))
        #expect(state.focusedWorkspaceName == "1")
        #expect(effects == [.place(id(1), screen)])
    }

    @Test func `monitor changes keep workspaces and assign new ones`() {
        let second = Monitor(id: 2, frame: CGRect(x: 1000, y: 0, width: 800, height: 600))
        let (state, _) = reduce(makeState(), .monitorsChanged([Monitor(id: 1, frame: screen), second]))
        #expect(state.monitors.map(\.workspace) == ["1", "2"])
    }
}
