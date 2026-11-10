import CoreGraphics

/// Work for the platform layer. The reducer returns these as data and never performs them.
public enum Effect: Equatable, Sendable {
    case place(WindowID, CGRect)
    /// Move offscreen, remembering the current frame.
    case park(WindowID)
    /// Restore the frame remembered by `park`.
    case unpark(WindowID)
    case focus(WindowID)
    /// Run a shell command, fire and forget.
    case run(String)
}
