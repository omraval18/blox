/// How windows travel when the visible workspace changes (Hyprland's `workspaces`).
public enum WorkspaceMotion: Equatable, Sendable {
    case off
    case slide
    case slideVertical

    /// `off`, `slide` or `slidevert`.
    public init?(parsing text: String) {
        switch text {
        case "off": self = .off
        case "slide": self = .slide
        case "slidevert": self = .slideVertical
        default: return nil
        }
    }

    /// The direction outgoing windows leave in, given the horizontal direction the reducer reports.
    public func exit(for travel: Direction) -> Direction? {
        switch (self, travel) {
        case (.off, _): nil
        case (.slideVertical, .left): .up
        case (.slideVertical, .right): .down
        default: travel
        }
    }
}
