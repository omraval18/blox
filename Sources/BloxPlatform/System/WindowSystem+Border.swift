import BloxCore
import CoreGraphics
import QuartzCore

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

    /// An app took a frame Blox set: its ring follows and is pushed to the screen right away, not
    /// after every app has answered. Answers for windows forgotten or parked since are ignored.
    func applied(_ id: WindowID, _ step: FrameStep) {
        guard animator.frame(of: id) != nil else { return }
        switch step {
        case let .resize(frame), let .move(frame), let .place(frame):
            followBorder(id, frame)
            CATransaction.flush()
        case let .settle(frame):
            followBorder(id, frame)
            CATransaction.flush()
            settled(id, frame)
        case .park:
            break
        }
    }

    /// An animation landed: the ring hugs the window's real frame (an app that refused the size
    /// sends no notification when its size does not change), and its size limits are checked.
    func settled(_ id: WindowID, _ target: CGRect) {
        guard let window = windows[id] else { return }
        fitBorder(window)
        checkSizeLimits(window, target)
    }

    /// Fits a shown window's ring to where the window really is.
    func fitBorder(_ window: AXWindow) {
        guard parked[window.id] == nil else { return }
        if let actual = realFrame(of: window) {
            border.update(window.id, frame: actual)
        }
        border.settle(window.id)
    }

    /// Called right after a window was asked to take `frame`. The ring goes where the window
    /// really is, which the window server knows; `frame` is only the fallback.
    func followBorder(_ id: WindowID, _ frame: CGRect) {
        if parked[id] == nil {
            border.update(id, frame: WindowServer.bounds(of: id) ?? frame)
        }
    }
}
