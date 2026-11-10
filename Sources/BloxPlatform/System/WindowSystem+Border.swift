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

    func refreshBorder(_ id: WindowID) {
        guard let window = windows[id], parked[id] == nil,
              let frame = animator.frame(of: id) ?? window.frame else {
            border.remove(id)
            return
        }
        border.update(id, frame: frame)
    }

    func followBorder(_ id: WindowID, _ frame: CGRect) {
        if parked[id] == nil {
            border.update(id, frame: frame)
        }
    }
}
