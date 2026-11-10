@testable import BloxCore
import Testing

struct HyprdotsTests {
    @Test func `default style uses hyprdots window move curve and speed`() {
        let style = AnimationStyle.named("hyprdots")
        #expect(style?.curve == Curve(parsing: "0.05 0.9 0.1 1.05"))
        #expect(style?.duration == 0.5)
    }

    @Test func `preset styles keep their speeds from the source`() {
        #expect(AnimationStyle.named("classic")?.duration == 0.7)
        #expect(AnimationStyle.named("diablo")?.curve == Curve(parsing: "0.4 0.9 0.6 1"))
        #expect(AnimationStyle.named("moving")?.curve == Curve(parsing: "0.5 -0.5 0.68 1.5"))
        #expect(AnimationStyle.named("minimal")?.curve == Curve(parsing: "0.25 1 0.5 1"))
        #expect(AnimationStyle.named("optimized")?.duration == 0.3)
    }

    @Test func `curve names from the source are usable in config`() throws {
        let config = try Config(parsing: "[animation]\ncurve = \"diablo-overshoot\"")
        #expect(config.settings.animation.curve == Curve(parsing: "0.13 0.99 0.29 1.08"))
    }

    @Test func `inactive border colors parse`() throws {
        let text = "[border]\ncolors = \"ca9ee6 f2d5cf\"\ninactive = \"b4befecc 6c7086cc\""
        let border = try Config(parsing: text).settings.border
        #expect(border.colors.count == 2)
        #expect(border.inactiveColors.count == 2)
        #expect(border.inactiveColors.first?.alpha == 0xCC / 255.0)
        #expect(BorderSettings().inactiveColors.isEmpty)
    }

    @Test func `floating A window releases its decorations`() {
        let base = run([.windowAppeared(id(1)), .windowAppeared(id(2))]).0
        let (_, effects) = reduce(base, .toggleFloating)
        #expect(effects.contains(.release(id(2))))
    }

    @Test func `tiling A floating window again places it`() {
        let base = run([.windowAppeared(id(1)), .windowAppeared(id(2)), .toggleFloating]).0
        let (_, effects) = reduce(base, .toggleFloating)
        #expect(effects.contains {
            if case .place(id(2), _) = $0 {
                true
            } else {
                false
            }
        })
    }
}
