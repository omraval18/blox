import CoreGraphics

/// One frame change for a window, as the main actor hands it to the channel of the window's app.
public enum FrameStep: Equatable, Sendable {
    /// An animation step that sets size and position.
    case resize(CGRect)
    /// An animation step that sets only the position; the size is the one the window has.
    case move(CGRect)
    /// A whole frame at once, before a glide starts or as a snap.
    case place(CGRect)
    /// The final frame of a move: the window has landed once it is applied.
    case settle(CGRect)
    /// Hide the window at the parking point.
    case park(CGPoint)

    /// Settling and parking end a move: they replace whatever is still waiting for the window.
    var isFinal: Bool {
        switch self {
        case .settle, .park: true
        case .resize, .move, .place: false
        }
    }

    /// This step and a `later` animation step (`resize` or `move`) as one: the later position,
    /// and the size the window would have after both.
    func merged(with later: Self) -> Self {
        switch (self, later) {
        case let (.place, .resize(new)): .place(new)
        case let (.place(old), .move(new)): .place(CGRect(origin: new.origin, size: old.size))
        case let (.resize(old), .move(new)): .resize(CGRect(origin: new.origin, size: old.size))
        default: later
        }
    }
}
