import ApplicationServices
import BloxCore

/// Private but long-stable symbol that maps an AX window to its WindowServer ID.
/// AeroSpace, yabai and Rectangle all rely on it; there is no public equivalent.
@_silgen_name("_AXUIElementGetWindow")
@unsafe private func axGetWindow(
    _ element: AXUIElement,
    _ identifier: UnsafeMutablePointer<UInt32>,
) -> AXError

extension AXUIElement {
    var windowID: WindowID? {
        var identifier: UInt32 = 0
        guard unsafe axGetWindow(self, &identifier) == .success, identifier != 0 else { return nil }
        return WindowID(identifier)
    }
}
