@testable import BloxCore
import CoreGraphics
import Testing

struct ParityTests {
    private func state(rules: [String: WindowRule]) -> State {
        var settings = Settings()
        settings.rules = rules
        return reduce(State(settings: settings), .monitorsChanged([Monitor(id: 1, frame: screen)])).0
    }

    @Test func `rule sends window to workspace without stealing focus`() {
        let base = state(rules: ["com.web": WindowRule(workspace: "B")])
        let (next, effects) = run(
            [.windowAppeared(id(1)), .windowAppeared(id(2), app: "com.web")],
            from: base,
        )
        #expect(next.workspaces["B"]?.tiled == [id(2)])
        #expect(next.focusedWindow == id(1))
        #expect(effects.contains(.park(id(2))))
    }

    @Test func `float rule keeps window out of the layout`() {
        let base = state(rules: ["com.app": WindowRule(floating: true)])
        let (next, _) = run([.windowAppeared(id(1)), .windowAppeared(id(2), app: "com.app")], from: base)
        #expect(next.workspaces["1"]?.floating == [id(2)])
        #expect(frames(of: next) == [screen])
    }

    @Test func `back and forth toggles between two workspaces`() {
        let (next, _) = run([.switchWorkspace("2"), .switchWorkspace("3"), .workspaceBackAndForth])
        #expect(next.focusedWorkspaceName == "2")
        #expect(run([.workspaceBackAndForth], from: next).0.focusedWorkspaceName == "3")
    }

    @Test func `back and forth without history does nothing`() {
        #expect(run([.workspaceBackAndForth]).0.focusedWorkspaceName == "1")
    }

    @Test func `fullscreen covers the monitor and raises`() {
        let base = run([.windowAppeared(id(1)), .windowAppeared(id(2))]).0
        let (next, effects) = reduce(base, .toggleFullscreen)
        #expect(effects.contains(.place(id(2), screen)))
        #expect(effects.last == .focus(id(2)))
        let (restored, _) = reduce(next, .toggleFullscreen)
        #expect(restored.workspaces["1"]?.fullscreen == nil)
    }

    @Test func `removing fullscreen window clears it`() {
        let base = run([.windowAppeared(id(1)), .toggleFullscreen, .windowDisappeared(id(1))]).0
        #expect(base.workspaces["1"]?.fullscreen == nil)
    }

    @Test func `balance resets ratio`() {
        let (next, _) = run([.resize(0.3), .balance])
        #expect(next.workspaces["1"]?.ratio == 0.5)
    }

    @Test func `mode switches binding set`() {
        #expect(run([.setMode("resize")]).0.mode == "resize")
    }

    @Test func `exec emits shell effect only`() {
        let (_, effects) = reduce(makeState(), .exec("echo hi"))
        #expect(effects == [.run("echo hi")])
    }

    @Test func `workspace follows focus to next monitor`() {
        let second = Monitor(id: 2, frame: CGRect(x: 1000, y: 0, width: 800, height: 600))
        let two = reduce(makeState(), .monitorsChanged([Monitor(id: 1, frame: screen), second])).0
        let (next, _) = reduce(two, .moveWorkspaceToMonitor)
        #expect(next.monitors.map(\.workspace) == ["2", "1"])
        #expect(next.focusedMonitor == 1)
    }

    @Test func `single monitor ignores move to monitor`() {
        #expect(run([.moveWorkspaceToMonitor]).0 == makeState())
    }

    @Test func `animation command switches style and off`() {
        let styled = run([.setAnimation("bounce")]).0
        #expect(styled.settings.animation.enabled)
        #expect(styled.settings.animation.curve == .bounce)
        #expect(run([.setAnimation("bounce"), .setAnimation("off")]).0.settings.animation.enabled == false)
        #expect(run([.setAnimation("nonsense")]).0 == makeState())
    }

    @Test func `sequences and new commands parse`() {
        #expect(Command.sequence(parsing: "reload-config ; mode main") == [.reloadConfig, .setMode("main")])
        #expect(Command.sequence(parsing: "retile ; bogus").isEmpty)
        #expect(Command(parsing: "exec osascript -e 'beep'") == .exec("osascript -e 'beep'"))
        #expect(Command(parsing: "workspace-back-and-forth") == .workspaceBackAndForth)
        #expect(Command(parsing: "animation overshoot") == .setAnimation("overshoot"))
        #expect(Command(parsing: "exec ") == nil)
    }
}
