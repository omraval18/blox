/// How windows travel when the visible workspace changes (Hyprland's `workspaces`).
public enum WorkspaceMotion: Equatable, Sendable {
    case off
    /// Outgoing windows leave through one side edge and the new workspace's enter from the other.
    case slide

    /// `off` or `slide`. Hyprland's `slidevert` is not offered: macOS keeps windows below the menu
    /// bar, so a window cannot leave through the top.
    public init?(parsing text: String) {
        switch text {
        case "off": self = .off
        case "slide": self = .slide
        default: return nil
        }
    }

    /// The direction outgoing windows leave in, or nil when workspaces switch instantly.
    public func exit(for travel: Direction) -> Direction? {
        self == .off ? nil : travel
    }
}
