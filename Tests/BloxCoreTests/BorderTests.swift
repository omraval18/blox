@testable import BloxCore
import Testing

struct BorderTests {
    @Test func `parses six and eight digit hex`() throws {
        let opaque = try #require(RGBA(hex: "ff8000"))
        #expect(opaque.red == 1 && opaque.alpha == 1)
        #expect(abs(opaque.green - 128.0 / 255) < 1e-9)
        let translucent = try #require(RGBA(hex: "#00ff0080"))
        #expect(translucent.green == 1)
        #expect(abs(translucent.alpha - 128.0 / 255) < 1e-9)
    }

    @Test(arguments: ["", "fff", "gggggg", "12345", "1234567", "#"])
    func `rejects bad hex`(text: String) {
        #expect(RGBA(hex: text) == nil)
    }

    @Test func `border section parses`() throws {
        let text = """
        [border]
        enabled = true
        width = 4
        radius = 16
        angle = 90
        colors = "ff0000 00ff00 0000ff"
        """
        let border = try Config(parsing: text).settings.border
        #expect(border.enabled && border.width == 4 && border.radius == 16 && border.angle == 90)
        #expect(border.colors.count == 3)
    }

    @Test(arguments: ["width = 0", "radius = 99", "colors = \"red\"", "colors = \"\"", "enabled = 1"])
    func `rejects bad border settings`(line: String) {
        #expect(throws: ConfigError.self) { try Config(parsing: "[border]\n\(line)") }
    }
}
