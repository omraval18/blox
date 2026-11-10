@testable import BloxCore
import Testing

struct CommandParserTests {
    @Test(arguments: [
        ("focus left", Command.focus(.left)),
        ("move down", .move(.down)),
        ("workspace 3", .switchWorkspace("3")),
        ("move-to-workspace web", .moveToWorkspace("web")),
        ("layout primary", .setLayout(.primary)),
        ("resize -0.05", .resize(-0.05)),
        ("toggle-floating", .toggleFloating),
        ("retile", .retile),
    ])
    func `parses valid commands`(text: String, expected: Command) {
        #expect(Command(parsing: text) == expected)
    }

    @Test(arguments: ["", "focus", "focus sideways", "layout grid", "resize big", "retile now", "explode"])
    func `rejects invalid commands`(text: String) {
        #expect(Command(parsing: text) == nil)
    }
}
