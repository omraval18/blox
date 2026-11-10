@testable import BloxCore
import CoreGraphics
import Testing

struct SettingsAndSummaryTests {
    @Test func `updating settings retiles with new gaps`() {
        let base = run([.windowAppeared(id(1))]).0
        let (state, effects) = reduce(base, .updateSettings(Settings(gaps: Gaps(inner: 0, outer: 10))))
        #expect(state.settings.gaps.outer == 10)
        #expect(effects == [.place(id(1), screen.insetBy(dx: 10, dy: 10))])
    }

    @Test func `summary lists monitors and workspaces`() {
        let state = run([.windowAppeared(id(1)), .windowAppeared(id(2))]).0
        #expect(state.summary == "* monitor 1: workspace 1\n  workspace 1: 2 tiled, 0 floating, dwindle")
    }
}
