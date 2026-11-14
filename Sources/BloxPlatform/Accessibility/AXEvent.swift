import ApplicationServices

enum AXEvent {
    case created(AXUIElement)
    case destroyed(AXUIElement)
    case focused(AXUIElement)
    case minimized(AXUIElement)
    case restored(AXUIElement)
    /// Moved or resized, by Blox or by anyone else.
    case reshaped(AXUIElement)
}
