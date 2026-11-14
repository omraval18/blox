import CoreGraphics

/// Each window takes `ratio` of the remaining area, splitting along its longer side. When a
/// window's minimum size would not fit beside the rest, the split turns to the other axis, and
/// the ratio is nudged so neither side is squeezed below its minimum or stretched past its
/// maximum (the space a fixed-width window cannot use goes to its neighbour).
struct DwindleLayout: LayoutAlgorithm {
    func frames(count: Int, in area: CGRect, ratio: Double, limits: [SizeLimits]) -> [CGRect] {
        guard count > 0 else { return [] }
        let known = limits + Array(repeating: SizeLimits(), count: max(count - limits.count, 0))
        var rest = area
        var result: [CGRect] = []
        for index in 0 ..< count - 1 {
            let (head, remainder) = split(
                rest,
                ratio: ratio,
                head: known[index],
                tail: tail(known, after: index),
            )
            result.append(head)
            rest = remainder
        }
        return result + [rest]
    }

    /// The remainder's limits: the largest minimum of the windows in it, and a maximum only when
    /// it holds a single window.
    private func tail(_ limits: [SizeLimits], after index: Int) -> SizeLimits {
        let rest = limits[(index + 1)...]
        let minimum = rest.reduce(CGSize.zero) {
            CGSize(width: max($0.width, $1.minimum.width), height: max($0.height, $1.minimum.height))
        }
        return SizeLimits(minimum: minimum, maximum: rest.count == 1 ? rest[index + 1].maximum : .zero)
    }

    private func split(
        _ rect: CGRect,
        ratio: Double,
        head: SizeLimits,
        tail: SizeLimits,
    ) -> (CGRect, CGRect) {
        let preferred = rect.width >= rect.height
        let wide = head.minimum.width + tail.minimum.width <= rect.width
        let tall = head.minimum.height + tail.minimum.height <= rect.height
        let sideBySide = preferred ? (wide || !tall) : (!tall && wide)
        let bounds = ratioBounds(sideBySide ? rect.width : rect.height, head, tail, sideBySide)
        let clamped = bounds.lowerBound <= bounds.upperBound
            ? min(max(ratio, bounds.lowerBound), bounds.upperBound) : ratio
        return rect.split(ratio: clamped, sideBySide: sideBySide)
    }

    /// The ratios that keep both sides within their limits along the split axis.
    private func ratioBounds(_ extent: Double, _ head: SizeLimits, _ tail: SizeLimits, _ horizontal: Bool)
        -> (lowerBound: Double, upperBound: Double) {
        let along: (CGSize) -> Double = { horizontal ? $0.width : $0.height }
        let headMax = along(head.maximum), tailMax = along(tail.maximum)
        let low = max(along(head.minimum) / extent, tailMax == 0 ? 0 : 1 - tailMax / extent)
        let high = min(1 - along(tail.minimum) / extent, headMax == 0 ? 1 : headMax / extent)
        return (low, high)
    }
}
