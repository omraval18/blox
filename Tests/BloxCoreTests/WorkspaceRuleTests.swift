@testable import BloxCore
import Testing

struct WorkspaceRuleTests {
    private func state(_ text: String) throws -> State {
        let settings = try Config(parsing: text).settings
        return reduce(State(settings: settings), .monitorsChanged([Monitor(id: 1, frame: screen)])).0
    }

    @Test func `a workspace rule sets the starting layout and ratio`() throws {
        let start =
            try state("[workspace.3]\nlayout = \"monocle\"\nratio = 0.7\n[layout]\ndefault = \"primary\"")
        let (next, _) = run([.switchWorkspace("3"), .switchWorkspace("4")], from: start)
        #expect(next.workspaces["3"]?.layout == .monocle)
        #expect(next.workspaces["3"]?.ratio == 0.7)
        #expect(next.workspaces["4"]?.layout == .primary)
        #expect(next.workspaces["4"]?.ratio == 0.5)
    }

    @Test func `balance returns to the workspace's own ratio`() throws {
        let start = try state("[workspace.1]\nratio = 0.7")
        let (next, _) = run([.resize(0.1), .balance], from: start)
        #expect(next.workspaces["1"]?.ratio == 0.7)
    }

    @Test func `workspace rules make the workspace reachable in the bar`() throws {
        #expect(try Config(parsing: "[workspace.7]\nratio = 0.5").workspaceNames == ["7"])
    }

    @Test(arguments: [
        "[workspace.1]\nlayout = \"grid\"",
        "[workspace.1]\nratio = 2",
        "[workspace.1]\ngap = 1",
    ])
    func `bad workspace rules report their line`(text: String) {
        let failure = #expect(throws: ConfigError.self) { try Config(parsing: text) }
        #expect(failure?.line == 2)
    }
}
