public struct Workspace: Equatable, Sendable {
    public var name: String
    public var tiled: [WindowID] = []
    public var floating: [WindowID] = []
    public var focused: WindowID?
    /// A tiled window temporarily covering the whole monitor.
    public var fullscreen: WindowID?
    public var layout: LayoutKind
    public var ratio: Double

    public init(name: String, layout: LayoutKind, ratio: Double) {
        self.name = name
        self.layout = layout
        self.ratio = ratio
    }

    public var windows: [WindowID] {
        tiled + floating
    }

    func contains(_ id: WindowID) -> Bool {
        tiled.contains(id) || floating.contains(id)
    }

    /// Inserts next to the focused window, or at the end.
    mutating func insertTiled(_ id: WindowID) {
        let anchor = focused.flatMap { tiled.firstIndex(of: $0) }
        tiled.insert(id, at: anchor.map { $0 + 1 } ?? tiled.count)
    }

    /// Removes a window; focus moves to the window that took its place.
    mutating func remove(_ id: WindowID) {
        let index = tiled.firstIndex(of: id)
        tiled.removeAll { $0 == id }
        floating.removeAll { $0 == id }
        if fullscreen == id {
            fullscreen = nil
        }
        guard focused == id else { return }
        focused = index.flatMap { tiled.indices.contains($0) ? tiled[$0] : tiled.last } ?? windows.last
    }
}
