import AppKit
import QuartzCore

/// A display link that exists only while something needs frames, so an idle Blox does no work.
@MainActor
final class DisplayClock: NSObject {
    private var link: CADisplayLink?
    /// Called once per display frame while running.
    var onTick: (@MainActor (CADisplayLink) -> Void)?

    /// Starts ticking unless already running; false when there is no screen to follow.
    func start() -> Bool {
        if link != nil {
            return true
        }
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return false }
        let created = screen.displayLink(target: self, selector: #selector(tick))
        created.add(to: .main, forMode: .common)
        link = created
        return true
    }

    func stop() {
        link?.invalidate()
        link = nil
    }

    @objc private func tick(_ link: CADisplayLink) {
        onTick?(link)
    }
}
