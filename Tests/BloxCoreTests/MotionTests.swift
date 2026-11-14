@testable import BloxCore
import CoreGraphics
import Testing

struct MotionTests {
    @Test func `entrance parses names and popin percent`() {
        #expect(Entrance(parsing: "off") == .off)
        #expect(Entrance(parsing: "slide") == .slide)
        #expect(Entrance(parsing: "popin") == .popin(0.8))
        #expect(Entrance(parsing: "popin 60") == .popin(0.6))
        #expect(Entrance(parsing: "popin 0") == nil)
        #expect(Entrance(parsing: "popin 101") == nil)
        #expect(Entrance(parsing: "spin") == nil)
    }

    @Test func `popin starts centred and smaller, others have no start`() {
        let target = CGRect(x: 100, y: 100, width: 400, height: 200)
        #expect(Entrance.popin(0.5).startFrame(for: target) == CGRect(
            x: 200,
            y: 150,
            width: 200,
            height: 100,
        ))
        #expect(Entrance.slide.startFrame(for: target) == nil)
        #expect(Entrance.off.startFrame(for: target) == nil)
    }

    @Test func `vertical motion turns horizontal travel into vertical`() {
        #expect(WorkspaceMotion.slide.exit(for: .left) == .left)
        #expect(WorkspaceMotion.slideVertical.exit(for: .left) == .up)
        #expect(WorkspaceMotion.slideVertical.exit(for: .right) == .down)
        #expect(WorkspaceMotion.off.exit(for: .left) == nil)
        #expect(WorkspaceMotion(parsing: "slidevert") == .slideVertical)
    }

    @Test func `phases follow movement timing unless they override it`() {
        var settings = AnimationSettings(enabled: true, duration: 0.4, curve: .bounce)
        #expect(settings.timing(of: settings.open) == Timing(duration: 0.4, curve: .bounce))
        settings.open.duration = 0.2
        #expect(settings.timing(of: settings.open) == Timing(duration: 0.2, curve: .bounce))
        settings.enabled = false
        #expect(settings.timing(of: settings.open) == nil)
        #expect(settings.moveTiming == nil)
    }

    @Test func `applying a preset keeps the per-phase choices`() {
        var settings = AnimationSettings()
        settings.open.style = .popin(0.7)
        settings.applyPreset(AnimationStyle.named("bounce") ?? settings)
        #expect(settings.enabled)
        #expect(settings.curve == .bounce)
        #expect(settings.open.style == .popin(0.7))
    }

    @Test func `interpolated frames land on whole points`() {
        let frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            .interpolated(to: CGRect(x: 33, y: 10, width: 333, height: 99), progress: 0.5)
        #expect(frame == frame.pixelAligned)
    }
}
