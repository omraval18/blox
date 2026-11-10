@testable import BloxCore
import Testing

struct ConfigSectionsTests {
    @Test func `modes allow plain keys but main requires A modifier`() throws {
        let config = try Config(parsing: "[mode.resize]\n\"h\" = \"resize -0.03\"\n\"esc\" = \"mode main\"")
        #expect(config.modes["resize"]?.count == 2)
        #expect(throws: ConfigError.self) { try Config(parsing: "[bindings]\n\"h\" = \"focus left\"") }
    }

    @Test func `binding can run several commands`() throws {
        let config = try Config(parsing: "[bindings]\n\"alt-x\" = \"reload-config ; mode main\"")
        #expect(config.modes["main"]?.first?.commands == [.reloadConfig, .setMode("main")])
    }

    @Test func `rules parse workspace and float`() throws {
        let text = """
        [rules]
        "com.a" = "workspace B"
        "com.b" = "float"
        "com.c" = "workspace T float"
        """
        let config = try Config(parsing: text)
        #expect(config.settings.rules["com.a"] == WindowRule(workspace: "B"))
        #expect(config.settings.rules["com.b"] == WindowRule(floating: true))
        #expect(config.settings.rules["com.c"] == WindowRule(workspace: "T", floating: true))
    }

    @Test(arguments: ["workspace", "tile", "workspace B nonsense"])
    func `bad rules are rejected`(value: String) {
        #expect(throws: ConfigError.self) { try Config(parsing: "[rules]\n\"com.a\" = \"\(value)\"") }
    }

    @Test func `custom curves can be named and used`() throws {
        let config =
            try Config(parsing: "[curves]\nmine = \"0.1 0.2 0.3 0.4\"\n[animation]\ncurve = \"mine\"")
        #expect(config.settings.animation.curve == Curve(parsing: "0.1 0.2 0.3 0.4"))
    }

    @Test func `style sets animation and keys override it`() throws {
        let config = try Config(parsing: "[animation]\nduration = 0.5\nstyle = \"bounce\"")
        #expect(config.settings.animation.enabled)
        #expect(config.settings.animation.curve == .bounce)
        #expect(config.settings.animation.duration == 0.5)
    }

    @Test func `focus section and errors`() throws {
        #expect(try Config(parsing: "[focus]\nmouse-follows = true").settings.mouseFollowsFocus)
        #expect(throws: ConfigError.self) { try Config(parsing: "[animation]\nstyle = \"nope\"") }
        #expect(throws: ConfigError.self) { try Config(parsing: "[curves]\nbad = \"1 2\"") }
    }

    @Test func `every style is usable`() {
        for name in AnimationStyle.names {
            #expect(AnimationStyle.named(name)?.enabled == true)
        }
    }
}
