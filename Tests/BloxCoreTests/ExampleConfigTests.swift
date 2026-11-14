@testable import BloxCore
import Foundation
import Testing

struct ExampleConfigTests {
    private func example(_ name: String) throws -> Config {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let text = try String(contentsOf: root.appendingPathComponent("examples/\(name)"), encoding: .utf8)
        return try Config(parsing: text)
    }

    @Test func `aerospace compat example parses and covers the keymap`() throws {
        let config = try example("aerospace-compat.toml")
        let main = try #require(config.modes["main"])
        #expect(main.count == 2 * 28 + 19)
        #expect(config.settings.defaultLayout == .tiles)
        #expect(Set(config.modes.keys) == ["main", "resize", "service", "anim"])
        #expect(main
            .contains { $0.chord == Chord(parsing: "alt-tab") && $0.commands == [.workspaceBackAndForth] })
        #expect(config.settings.rules["com.google.Chrome"] == WindowRule(workspace: "B"))
        #expect(config.settings.gaps == Gaps(inner: 18, outer: 0))
        #expect(config.settings.border.enabled)
        #expect(config.workspaceNames.count == 28)
        #expect(config.settings.border.inactiveColors.count == 2)
        #expect(config.settings.animation.curve == Curve(parsing: "wind"))
        #expect(config.settings.animation.workspaces.duration == 0.3)
    }

    @Test func `fullscreen binding runs the dock command`() throws {
        let main = try #require(example("aerospace-compat.toml").modes["main"])
        let binding = try #require(main.first { $0.chord == Chord(parsing: "alt-shift-f") })
        #expect(binding.commands.count == 2)
        #expect(binding.commands.first == .toggleFullscreen)
        guard case let .exec(line) = binding.commands[1] else {
            Issue.record("expected exec")
            return
        }
        #expect(line.contains("System Events") && line.contains("true"))
    }
}
