import BloxCore
import CoreGraphics
import QuartzCore

/// One window's glide from `from` to `to`, started at `start` (a `CACurrentMediaTime`).
struct AnimationTrack {
    /// What happens to a window when it reaches its frame.
    enum Finish {
        case settle
        /// It is sliding off `leaving` (a screen): hide it in the parking corner as soon as only a
        /// sliver remains on that screen, before macOS clamps it and leaves a strip showing.
        case park(leaving: CGRect)

        var isSettle: Bool {
            if case .settle = self {
                true
            } else {
                false
            }
        }
    }

    let window: AXWindow
    let from: CGRect
    let to: CGRect
    let start: CFTimeInterval
    let timing: Timing
    let finish: Finish
    /// How the size changes on the way: per step, or once for an app too slow to resize per frame.
    let glide: Glide

    /// Whether each step sets the window's size as well as its position.
    var resizesEachStep: Bool {
        glide.resizesEachStep(from: from, to: to)
    }

    /// The frame the window should take at `time`, and whether the glide is over: it has arrived (an
    /// overshooting curve gets there before its time is up), or a parking window has (nearly) left
    /// its screen and need not travel further.
    func position(at time: CFTimeInterval) -> (frame: CGRect, done: Bool) {
        let elapsed = max(time - start, 0)
        let frame = glide.frame(from: from, to: to, progress: timing.travel(after: elapsed))
        return (frame, elapsed >= timing.arrival || hasLeft(at: frame))
    }

    private func hasLeft(at frame: CGRect) -> Bool {
        guard case let .park(screen) = finish else { return false }
        return frame.intersection(screen).width <= Displays.sliver
    }
}
