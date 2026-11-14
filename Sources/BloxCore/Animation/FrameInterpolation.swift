import CoreGraphics

public extension CGRect {
    /// Linear blend between two frames, snapped to whole points so a window is never asked to move
    /// by less than it can show; `progress` may overshoot 0...1 for bouncy curves.
    func interpolated(to target: CGRect, progress: Double) -> CGRect {
        CGRect(
            x: minX + (target.minX - minX) * progress,
            y: minY + (target.minY - minY) * progress,
            width: max(width + (target.width - width) * progress, 1),
            height: max(height + (target.height - height) * progress, 1),
        ).pixelAligned
    }
}
