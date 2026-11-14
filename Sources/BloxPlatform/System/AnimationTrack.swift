import BloxCore
import CoreGraphics
import QuartzCore

/// One window's glide from `from` to `to`, started at `start` (a `CACurrentMediaTime`).
struct AnimationTrack {
    /// What happens to a window when it reaches its frame.
    enum Finish {
        case settle
        /// It slid offscreen: hide it in the parking corner.
        case park
    }

    let window: AXWindow
    let from: CGRect
    let to: CGRect
    let start: CFTimeInterval
    let timing: Timing
    let finish: Finish
}
