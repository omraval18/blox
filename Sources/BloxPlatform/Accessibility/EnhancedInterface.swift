import ApplicationServices

/// The app-level `AXEnhancedUserInterface` setting. Assistive tools switch it on, and with it some
/// apps (Chromium, Electron) animate their own window resizes and fight the animator, so it is off
/// while Blox sets an app's frames. When to switch it is decided by `AppQueue` (Core); this only
/// makes the calls. An app where it is off is never written to.
enum EnhancedInterface {
    private static let attribute = "AXEnhancedUserInterface"

    /// Switches the setting off if it is on; true when it did.
    static func switchOff(_ app: AXUIElement) -> Bool {
        guard AXAttribute.flag(app, attribute) else { return false }
        return AXAttribute.set(app, attribute, bool: false)
    }

    static func restore(_ app: AXUIElement) {
        AXAttribute.set(app, attribute, bool: true)
    }
}
