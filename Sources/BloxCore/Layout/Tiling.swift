import CoreGraphics

enum Tiling {
    static let ratioRange = 0.1 ... 0.9

    /// Final, gap-adjusted, pixel-aligned frames for `count` windows.
    static func frames(
        _ workspace: Workspace,
        in area: CGRect,
        gaps: Gaps,
        minimums: [CGSize] = [],
    ) -> [CGRect] {
        let half = gaps.inner / 2
        let padded = gaps.padded(area).insetBy(dx: -half, dy: -half)
        let clamped = min(max(workspace.ratio, ratioRange.lowerBound), ratioRange.upperBound)
        return workspace.layout.algorithm
            .frames(count: workspace.tiled.count, in: padded, ratio: clamped, minimums: minimums)
            .map { $0.insetBy(dx: half, dy: half).pixelAligned }
    }
}

extension CGRect {
    /// Rounds edges (not size) so neighbours keep exactly their gap.
    var pixelAligned: CGRect {
        CGRect(
            x: minX.rounded(),
            y: minY.rounded(),
            width: maxX.rounded() - minX.rounded(),
            height: maxY.rounded() - minY.rounded(),
        )
    }
}
