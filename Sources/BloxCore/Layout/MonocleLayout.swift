import CoreGraphics

/// Every window fills the area; the focused one is raised.
struct MonocleLayout: LayoutAlgorithm {
    func frames(count: Int, in area: CGRect, ratio _: Double) -> [CGRect] {
        Array(repeating: area, count: count)
    }
}
