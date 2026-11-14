import BloxCore
import CoreGraphics
import QuartzCore

/// Sets window frames for the animator through Accessibility, timing how long each app takes to
/// answer an animation step.
@MainActor
struct FrameWriter {
    private(set) var stats = AnimationStats()

    /// One animation step, timed per app and per kind of step.
    mutating func step(_ window: AXWindow, to frame: CGRect, resizing: Bool) {
        let began = CACurrentMediaTime()
        window.setStep(frame, resizing: resizing)
        stats.answered(window.pid, resizing ? .resizing : .moving, in: CACurrentMediaTime() - began)
    }

    func place(_ window: AXWindow, _ frame: CGRect) {
        window.setFrame(frame)
    }

    func park(_ window: AXWindow) {
        window.move(to: Displays.parkingPoint())
    }

    /// A display frame's work is done: `work` and the link's frame `interval`, in seconds.
    mutating func frameDone(work: Double, interval: Double) {
        stats.frame(work: work, interval: interval)
    }

    /// An app quit: drop what was measured about it.
    mutating func forgetApp(_ pid: pid_t) {
        stats.drop(pid)
    }
}
