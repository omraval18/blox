import CoreGraphics

/// Each window takes `ratio` of the remaining area, splitting along its longer side.
struct DwindleLayout: LayoutAlgorithm {
    func frames(count: Int, in area: CGRect, ratio: Double) -> [CGRect] {
        var rest = area
        var result: [CGRect] = []
        for _ in 1 ..< max(count, 1) {
            let (head, tail) = rest.split(ratio: ratio, sideBySide: rest.width >= rest.height)
            result.append(head)
            rest = tail
        }
        return count > 0 ? result + [rest] : []
    }
}
