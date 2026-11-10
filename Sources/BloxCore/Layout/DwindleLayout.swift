import CoreGraphics

/// Each window takes `ratio` of the remaining area, splitting along its longer side. When a
/// window's minimum size would not fit beside the rest, the split turns to the other axis, and
/// the ratio is nudged so neither side is squeezed below its minimum.
struct DwindleLayout: LayoutAlgorithm {
    func frames(count: Int, in area: CGRect, ratio: Double, minimums: [CGSize]) -> [CGRect] {
        guard count > 0 else { return [] }
        let floors = minimums + Array(repeating: .zero, count: max(count - minimums.count, 0))
        var rest = area
        var result: [CGRect] = []
        for index in 0 ..< count - 1 {
            let tail = floors[(index + 1)...].reduce(CGSize.zero) {
                CGSize(width: max($0.width, $1.width), height: max($0.height, $1.height))
            }
            let (head, remainder) = split(rest, ratio: ratio, head: floors[index], tail: tail)
            result.append(head)
            rest = remainder
        }
        return result + [rest]
    }

    private func split(_ rect: CGRect, ratio: Double, head: CGSize, tail: CGSize) -> (CGRect, CGRect) {
        let preferred = rect.width >= rect.height
        let wide = fits(rect.width, head.width, tail.width)
        let tall = fits(rect.height, head.height, tail.height)
        let sideBySide = preferred ? (wide || !tall) : (!tall && wide)
        let extent = sideBySide ? rect.width : rect.height
        let low = (sideBySide ? head.width : head.height) / extent
        let high = 1 - (sideBySide ? tail.width : tail.height) / extent
        return rect.split(ratio: low <= high ? min(max(ratio, low), high) : ratio, sideBySide: sideBySide)
    }

    private func fits(_ extent: Double, _ head: Double, _ tail: Double) -> Bool {
        head + tail <= extent
    }
}
