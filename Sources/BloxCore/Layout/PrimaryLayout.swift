import CoreGraphics

/// One primary window on the left, the rest stacked on the right.
struct PrimaryLayout: LayoutAlgorithm {
    func frames(count: Int, in area: CGRect, ratio: Double, minimums _: [CGSize]) -> [CGRect] {
        guard count > 1 else { return count == 1 ? [area] : [] }
        let (primary, stack) = area.split(ratio: ratio, sideBySide: true)
        let height = stack.height / Double(count - 1)
        let rows = (0 ..< count - 1).map { row in
            CGRect(x: stack.minX, y: stack.minY + height * Double(row), width: stack.width, height: height)
        }
        return [primary] + rows
    }
}
