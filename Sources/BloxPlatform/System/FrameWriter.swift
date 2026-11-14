import BloxCore
import CoreGraphics
import QuartzCore

/// Sets window frames for the animator through Accessibility, timing how long each app takes to
/// answer an animation step and resizing apps that are too slow for it only once per glide.
@MainActor
final class FrameWriter {
    private(set) var stats = AnimationStats()
    private var interface = EnhancedInterface()

    /// How `window` changes size on its way `from` -> `to`: an app too slow to resize every frame
    /// (the policy is `ResizeMode`, in Core) is resized once. A shrink happens right here; the
    /// frame it set, if any, comes back with the glide.
    func begin(_ window: AXWindow, from: CGRect, to: CGRect) -> (glide: Glide, shown: CGRect?) {
        let pace = stats.pace(of: window.pid, .resizing)
        let glide = Glide(from: from, to: to, mode: ResizeMode(averageResizeStep: pace?.average))
        let first = glide.startFrame(from: from, to: to)
        first.map { step(window, to: $0, resizing: true) }
        return (glide, first)
    }

    /// One animation step, timed per app and per kind of step.
    func step(_ window: AXWindow, to frame: CGRect, resizing: Bool) {
        let began = CACurrentMediaTime()
        window.setStep(frame, resizing: resizing)
        stats.answered(window.pid, resizing ? .resizing : .moving, in: CACurrentMediaTime() - began)
    }

    /// Sets a whole frame at once (a snap, or an animation's final frame).
    func place(_ window: AXWindow, _ frame: CGRect) {
        hold(window.pid)
        window.setFrame(frame)
        release(window.pid)
    }

    /// Frame changes for an app's windows start or end: `AXEnhancedUserInterface` stays off while
    /// any is under way (`EnhancedInterface`).
    func hold(_ pid: pid_t) {
        interface.begin(pid)
    }

    func release(_ pid: pid_t) {
        interface.end(pid)
    }

    /// Blox is quitting: every app gets its `AXEnhancedUserInterface` back.
    func restoreInterfaces() {
        interface.restoreAll()
    }

    func park(_ window: AXWindow) {
        window.move(to: Displays.parkingPoint())
    }

    /// A display frame's work is done: `work` and the link's frame `interval`, in seconds.
    func frameDone(work: Double, interval: Double) {
        stats.frame(work: work, interval: interval)
    }

    /// An app quit: drop what was measured about it.
    func forgetApp(_ pid: pid_t) {
        stats.drop(pid)
        interface.drop(pid)
    }
}
