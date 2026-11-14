import BloxCore
import CoreGraphics

extension WindowSystem {
    /// A difference larger than this from the requested size counts as a size limit rather than
    /// an app rounding to its own grid (terminals snap to character cells).
    private static let tolerance = 24.0

    /// Shortly after a window was given `target`, checks whether the app refused that size: too
    /// small to shrink to (minimum) or unable to grow that far (maximum). If so, reports it so the
    /// layout stops overlapping neighbours or leaving a hole beside the window.
    func checkSizeLimits(_ window: AXWindow, _ target: CGRect) {
        Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard windows[window.id] != nil, parked[window.id] == nil,
                  animator.target(of: window.id) == target, let actual = window.frame else { return }
            // Some apps finish resizing after the animation lands.
            fitBorder(window)
            let limits = Self.limits(actual: actual.size, target: target.size)
            if limits != SizeLimits() {
                onCommand(.windowSizeLimits(window.id, limits))
            }
        }
    }

    private static func limits(actual: CGSize, target: CGSize) -> SizeLimits {
        let pick: (Double, Bool) -> Double = { value, applies in applies ? value : 0 }
        return SizeLimits(
            minimum: CGSize(
                width: pick(actual.width, actual.width > target.width + tolerance),
                height: pick(actual.height, actual.height > target.height + tolerance),
            ),
            maximum: CGSize(
                width: pick(actual.width, actual.width < target.width - tolerance),
                height: pick(actual.height, actual.height < target.height - tolerance),
            ),
        )
    }
}
