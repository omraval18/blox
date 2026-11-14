@testable import BloxCore
import Testing

struct WorkspaceListTests {
    @Test func `overview includes every configured workspace even when empty`() {
        let state = run([.windowAppeared(id(1))]).0
        let names = state.overview(including: ["1", "B", "T"]).map(\.name)
        #expect(names == ["1", "B", "T"])
        #expect(state.overview(including: ["B"]).first { $0.name == "B" }?.windows.isEmpty == true)
    }

    @Test func `config lists workspaces from bindings and rules`() throws {
        let text = """
        [rules]
        "com.a" = "workspace Z"
        [bindings]
        "alt-1" = "workspace 1"
        "alt-shift-1" = "move-to-workspace 1"
        "alt-b" = "workspace B"
        """
        #expect(try Config(parsing: text).workspaceNames == ["1", "B", "Z"])
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
