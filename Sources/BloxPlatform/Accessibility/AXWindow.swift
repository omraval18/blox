import ApplicationServices
import BloxCore

/// One window as seen through Accessibility.
struct AXWindow {
    let id: WindowID
    let element: AXUIElement
    let pid: pid_t

    init?(_ element: AXUIElement) {
        var pid: pid_t = 0
        guard let id = element.windowID,
              unsafe AXUIElementGetPid(element, &pid) == .success else { return nil }
        AXUIElementSetMessagingTimeout(element, 1)
        self.id = id
        self.element = element
        self.pid = pid
    }

    /// Standard, resizable, on-screen windows are tiled; dialogs, panels and fixed-size windows are left
    /// alone.
    var isTileable: Bool {
        AXAttribute.string(element, kAXRoleAttribute) == kAXWindowRole
            && AXAttribute.string(element, kAXSubroleAttribute) == kAXStandardWindowSubrole
            && !AXAttribute.flag(element, kAXMinimizedAttribute)
            && !AXAttribute.flag(element, "AXFullScreen")
            && AXAttribute.isSettable(element, kAXSizeAttribute)
    }

    var frame: CGRect? {
        guard let origin = AXAttribute.point(element, kAXPositionAttribute),
              let size = AXAttribute.size(element, kAXSizeAttribute) else { return nil }
        return CGRect(origin: origin, size: size)
    }

    /// Size first so growth is not clamped by the old position, then position, then size again
    /// for apps that reflow when moved.
    func setFrame(_ frame: CGRect) {
        AXAttribute.set(element, kAXSizeAttribute, size: frame.size)
        AXAttribute.set(element, kAXPositionAttribute, point: frame.origin)
        AXAttribute.set(element, kAXSizeAttribute, size: frame.size)
    }

    /// One animation step: cheaper than `setFrame` (no settling pass), and move-only when size is fixed.
    func setStep(_ frame: CGRect, resizing: Bool) {
        if resizing {
            AXAttribute.set(element, kAXSizeAttribute, size: frame.size)
        }
        AXAttribute.set(element, kAXPositionAttribute, point: frame.origin)
    }

    func move(to point: CGPoint) {
        AXAttribute.set(element, kAXPositionAttribute, point: point)
    }

    func raise() {
        AXUIElementPerformAction(element, kAXRaiseAction as CFString)
        AXAttribute.set(AXUIElementCreateApplication(pid), kAXFrontmostAttribute, bool: true)
        AXAttribute.set(element, kAXMainAttribute, bool: true)
    }
}
