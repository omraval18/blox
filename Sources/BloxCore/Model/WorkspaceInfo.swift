/// What a workspace bar needs to know about one workspace.
public struct WorkspaceInfo: Equatable, Sendable {
    public let name: String
    public let windows: [WindowID]
    /// On the monitor you are working on.
    public let isFocused: Bool
    /// Shown on some monitor (focused or not).
    public let isVisible: Bool
}
