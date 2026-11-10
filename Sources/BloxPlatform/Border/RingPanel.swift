import AppKit

/// A panel that may sit anywhere. By default macOS pushes windows below the menu bar, which would
/// shift the ring a few points off the window it hugs whenever that window touches the top edge.
final class RingPanel: NSPanel {
    override func constrainFrameRect(_ frameRect: NSRect, to _: NSScreen?) -> NSRect {
        frameRect
    }
}
