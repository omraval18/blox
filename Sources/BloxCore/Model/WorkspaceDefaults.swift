/// What a workspace starts with, overriding the global layout settings (Hyprland workspace rules).
public struct WorkspaceDefaults: Equatable, Sendable {
    public var layout: LayoutKind?
    public var ratio: Double?

    public init(layout: LayoutKind? = nil, ratio: Double? = nil) {
        self.layout = layout
        self.ratio = ratio
    }
}
