import CoreGraphics

/// Splits `area` into `count` frames. Gaps and pixel alignment are applied by `Tiling`.
protocol LayoutAlgorithm: Sendable {
    func frames(count: Int, in area: CGRect, ratio: Double) -> [CGRect]
}

extension CGRect {
    /// Splits into a leading part of `ratio` and the remainder, side by side or stacked.
    func split(ratio: Double, sideBySide: Bool) -> (CGRect, CGRect) {
        if sideBySide {
            let head = width * ratio
            return (
                CGRect(x: minX, y: minY, width: head, height: height),
                CGRect(x: minX + head, y: minY, width: width - head, height: height),
            )
        }
        let head = height * ratio
        return (
            CGRect(x: minX, y: minY, width: width, height: head),
            CGRect(x: minX, y: minY + head, width: width, height: height - head),
        )
    }
}
