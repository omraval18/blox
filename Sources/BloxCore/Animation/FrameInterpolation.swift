import CoreGraphics

public extension CGRect {
    /// Linear blend between two frames; `progress` may overshoot 0...1 for bouncy curves.
    func interpolated(to target: CGRect, progress: Double) -> CGRect {
        CGRect(
            x: minX + (target.minX - minX) * progress,
            y: minY + (target.minY - minY) * progress,
            width: max(width + (target.width - width) * progress, 1),
            height: max(height + (target.height - height) * progress, 1),
        )
    }
}
