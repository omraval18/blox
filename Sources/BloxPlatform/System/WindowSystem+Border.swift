import BloxCore
import CoreGraphics

extension WindowSystem {
    /// Tells the system which window has focus (from the model), restyling the rings.
    public func setFocused(_ id: WindowID?) {
        guard id != focusedID else { return }
        let previous = focusedID
        focusedID = id
        border.active = id
        [previous, id].compactMap(\.self).forEach(refreshBorder)
    }

    /// Re-applies border settings to every window that has a frame.
    func syncBorders() {
        windows.keys.filter { parked[$0] == nil }.forEach(refreshBorder)
    }

    /// A failed or timed-out frame read keeps the existing ring rather than dropping it.
    func refreshBorder(_ id: WindowID) {
        guard let window = windows[id], parked[id] == nil else { return border.remove(id) }
        if let frame = animator.frame(of: id) ?? window.frame {
            border.update(id, frame: frame)
        }
    }

    /// The app has really moved focus, and with it the window's z-order: sit above it again.
    func restackBorder(_ id: WindowID) {
        border.raise(id)
    }

    func followBorder(_ id: WindowID, _ frame: CGRect) {
        if parked[id] == nil {
            border.update(id, frame: frame)
        }
    }
}
