import BloxCore
import CoreGraphics

extension WindowSystem {
    /// Larger than this over the requested size counts as a minimum-size limit rather than an app
    /// rounding to its own grid (terminals snap to character cells).
    private static let minimumTolerance = 24.0

    /// Shortly after a window was given `target`, checks whether the app refused to shrink that
    /// far. If so, reports its real size so the layout can stop overlapping it with neighbours.
    func checkMinimum(_ window: AXWindow, _ target: CGRect) {
        Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard windows[window.id] != nil, parked[window.id] == nil,
                  animator.target(of: window.id) == target, let actual = window.frame else { return }
            let wide = actual.width > target.width + Self.minimumTolerance
            let tall = actual.height > target.height + Self.minimumTolerance
            guard wide || tall else { return }
            onCommand(.windowMinSize(
                window.id,
                CGSize(width: wide ? actual.width : 0, height: tall ? actual.height : 0),
            ))
        }
    }
}
