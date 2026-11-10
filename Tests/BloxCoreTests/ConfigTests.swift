@testable import BloxCore
import Testing

struct ConfigTests {
    @Test func `default config is valid`() throws {
        let config = try Config(parsing: Config.defaultText)
        #expect(config.settings.gaps == Gaps(inner: 8, outer: 8))
        #expect(config.bindings.count == 22)
        #expect(config.bindings.first?.command == .focus(.left))
    }

    @Test func `empty config uses defaults`() throws {
        #expect(try Config(parsing: "").settings == Settings())
    }

    @Test func `comments and quoted keys parse`() throws {
        let config = try Config(parsing: "[bindings]\n\"alt-#\" = \"retile\" # trailing\n")
        #expect(config.bindings.first?.chord == Chord(parsing: "alt-#"))
    }

    @Test(arguments: [
        ("[gaps]\ninner = abc", 2),
        ("[gaps]\ninner = 500", 2),
        ("[gapz]\ninner = 1", 2),
        ("[layout]\ndefault = \"grid\"", 2),
        ("[bindings]\n\"h\" = \"focus left\"", 2),
        ("[bindings]\n\"alt-h\" = \"explode\"", 2),
        ("[gaps\ninner = 1", 1),
        ("[gaps]\ninner", 2),
        ("[gaps]\ninner = \"x", 2),
    ])
    func `reports errors with line numbers`(text: String, line: Int) {
        let failure = #expect(throws: ConfigError.self) { try Config(parsing: text) }
        #expect(failure?.line == line)
    }

    @Test func `chord parsing`() {
        #expect(Chord(parsing: "alt-shift-h")?.modifiers == [.alt, .shift])
        #expect(Chord(parsing: "ctrl--")?.key == "-")
        #expect(Chord(parsing: "h") == nil)
        #expect(Chord(parsing: "alt-alt-h") == nil)
        #expect(Chord(parsing: "alt-") == nil)
    }
}
