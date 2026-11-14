import CoreGraphics

public struct Gaps: Equatable, Sendable {
    /// Space between two tiled windows.
    public var inner: Double
    /// Space between tiled windows and the screen edge.
    public var outer: Double
    /// Per-edge overrides of `outer`, for example to leave room for a custom bar.
    public var outerTop: Double?
    public var outerBottom: Double?
    public var outerLeft: Double?
    public var outerRight: Double?
    /// A lone tiled window gets no gaps at all (Hyprland's `no_gaps_when_only`).
    public var smart = false

    public init(inner: Double = 0, outer: Double = 0) {
        self.inner = inner
        self.outer = outer
    }

    /// `area` shrunk by the outer gap on each edge.
    func padded(_ area: CGRect) -> CGRect {
        let left = outerLeft ?? outer
        let top = outerTop ?? outer
        return CGRect(
            x: area.minX + left,
            y: area.minY + top,
            width: area.width - left - (outerRight ?? outer),
            height: area.height - top - (outerBottom ?? outer),
        )
    }
}
