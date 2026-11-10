import ApplicationServices

/// Whether the process has been granted Accessibility access.
public enum AccessibilityPermission {
    public static var isGranted: Bool {
        AXIsProcessTrusted()
    }

    /// Checks access and, if missing, shows the system prompt that leads to Settings.
    @discardableResult
    public static func request() -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
