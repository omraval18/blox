import BloxCore
import CoreGraphics

extension WindowSystem {
    /// Tells the system which window has focus (from the model), moving the ring to it.
    public func setFocused(_ id: WindowID?) {
        guard id != focusedID else { return }
        focusedID = id
        syncBorder()
    }

    func syncBorder() {
        guard let id = focusedID, let window = windows[id],
              let frame = animator.frame(of: id) ?? window.frame else {
            border.hide()
            return
        }
        border.show(around: frame, above: id.rawValue)
    }

    func followBorder(_ id: WindowID, _ frame: CGRect) {
        if id == focusedID {
            border.move(to: frame)
        }
    }
}
