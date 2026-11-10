public struct Gaps: Equatable, Sendable {
    /// Space between two tiled windows.
    public var inner: Double
    /// Space between tiled windows and the screen edge.
    public var outer: Double

    public init(inner: Double = 0, outer: Double = 0) {
        self.inner = inner
        self.outer = outer
    }
}
