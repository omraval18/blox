import CoreGraphics

/// Work for the platform layer. The reducer returns these as data and never performs them.
public enum Effect: Equatable, Sendable {
    /// The shown workspace changed; the place/park effects that follow glide this way (`left`:
    /// outgoing windows leave to the left and new ones enter from the right).
    case slide(Direction)
    case place(WindowID, CGRect)
    /// Move offscreen, remembering the current frame.
    case park(WindowID)
    /// Restore the frame remembered by `park`.
    case unpark(WindowID)
    case focus(WindowID)
    /// Ask the app to close the window.
    case close(WindowID)
    /// The window is no longer laid out (floating): drop decorations that track its tile.
    case release(WindowID)
    /// Run a shell command, fire and forget.
    case run(String)
}
