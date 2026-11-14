import CoreGraphics

enum Tiling {
    static let ratioRange = 0.1 ... 0.9

    /// Final, gap-adjusted, pixel-aligned frames for `count` windows.
    static func frames(
        _ workspace: Workspace,
        in area: CGRect,
        gaps: Gaps,
        limits: [SizeLimits] = [],
    ) -> [CGRect] {
        let half = gaps.inner / 2
        let usable = gaps.padded(area)
        let clamped = min(max(workspace.ratio, ratioRange.lowerBound), ratioRange.upperBound)
        return workspace.layout.algorithm
            .frames(
                count: workspace.tiled.count,
                in: usable.insetBy(dx: -half, dy: -half),
                ratio: clamped,
                limits: limits,
            )
            .map { inset($0, by: half, within: usable).pixelAligned }
    }

    /// Removes the gap around a tile. A tile squeezed thinner than the gap (more windows or larger
    /// minimums than fit) collapses to zero size inside the usable area, never to the null rect or
    /// into the margin outside it.
    private static func inset(_ tile: CGRect, by half: Double, within usable: CGRect) -> CGRect {
        let inner = tile.insetBy(dx: min(half, tile.width / 2), dy: min(half, tile.height / 2))
        return CGRect(
            x: min(max(inner.minX, usable.minX), usable.maxX - inner.width),
            y: min(max(inner.minY, usable.minY), usable.maxY - inner.height),
            width: inner.width,
            height: inner.height,
        )
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
