@testable import BloxCore
import Testing

struct AnimationTableTests {
    @Test func `open and workspaces tables set their phase`() throws {
        let text = """
        [curves]
        mine = "0.1 0.2 0.3 0.4"
        [animation]
        style = "bounce"
        [animation.open]
        style = "popin 70"
        duration = 0.25
        [animation.workspaces]
        style = "slide"
        curve = "mine"
        """
        let animation = try Config(parsing: text).settings.animation
        #expect(animation.curve == .bounce)
        #expect(animation.open.style == .popin(0.7))
        #expect(animation.open.duration == 0.25)
        #expect(animation.workspaces.style == .slide)
        #expect(animation.workspaces.curve == Curve(parsing: "0.1 0.2 0.3 0.4"))
    }

    @Test(arguments: [
        "[animation.open]\nstyle = \"spin\"",
        "[animation.workspaces]\nstyle = \"slidevert\"",
        "[animation.open]\nduration = 5",
        "[animation.open]\nspeed = 1",
    ])
    func `bad phase values report their line`(text: String) {
        let failure = #expect(throws: ConfigError.self) { try Config(parsing: text) }
        #expect(failure?.line == 2)
    }

    @Test func `gap sides and smart gaps parse`() throws {
        let gaps = try Config(parsing: "[gaps]\nouter = 4\nouter-top = 30\nsmart = true").settings.gaps
        #expect(gaps.outerTop == 30)
        #expect(gaps.outerLeft == nil)
        #expect(gaps.smart)
    }
}
