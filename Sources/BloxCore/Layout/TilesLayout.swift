import CoreGraphics

/// AeroSpace's default `tiles` layout: one row of full-height windows sharing the width equally
/// (one column on a portrait screen). A window that cannot grow past its maximum or shrink below
/// its minimum keeps that size and the others share what is left, so no window is asked for a size
/// it will not take. When the minimums cannot all fit, every window gets an equal share.
struct TilesLayout: LayoutAlgorithm {
    func frames(count: Int, in area: CGRect, ratio _: Double, limits: [SizeLimits]) -> [CGRect] {
        guard count > 0 else { return [] }
        let horizontal = area.width >= area.height
        let along: (CGSize) -> Double = { horizontal ? $0.width : $0.height }
        let known = limits + Array(repeating: SizeLimits(), count: max(count - limits.count, 0))
        let bounds = known.prefix(count).map { (low: along($0.minimum), high: along($0.maximum)) }
        let extent = horizontal ? area.width : area.height
        var offset = 0.0
        return Self.shares(of: extent, bounds: bounds).map { share in
            defer { offset += share }
            return horizontal
                ? CGRect(x: area.minX + offset, y: area.minY, width: share, height: area.height)
                : CGRect(x: area.minX, y: area.minY + offset, width: area.width, height: share)
        }
    }

    /// Splits `total` equally, pinning any share outside its bounds (a zero high is no maximum) and
    /// sharing the rest again until every share fits.
    static func shares(of total: Double, bounds: [(low: Double, high: Double)]) -> [Double] {
        var pinned: [Int: Double] = [:]
        while pinned.count < bounds.count {
            let free = bounds.indices.filter { pinned[$0] == nil }
            let share = (total - pinned.values.reduce(0, +)) / Double(free.count)
            let outside = free.compactMap { index in pin(share, bounds[index]).map { (index, $0) } }
            guard !outside.isEmpty else {
                free.forEach { pinned[$0] = share }
                break
            }
            outside.forEach { pinned[$0.0] = $0.1 }
        }
        let result = bounds.indices.map { pinned[$0] ?? 0 }
        let equal = Array(repeating: total / Double(bounds.count), count: bounds.count)
        return result.reduce(0, +) > total + 0.5 ? equal : result
    }

    private static func pin(_ share: Double, _ bound: (low: Double, high: Double)) -> Double? {
        if bound.high > 0, share > bound.high {
            return bound.high
        }
        return share < bound.low ? bound.low : nil
    }
}
