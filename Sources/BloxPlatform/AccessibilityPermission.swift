import ApplicationServices

/// Whether the process has been granted Accessibility access.
public enum AccessibilityPermission {
    public static var isGranted: Bool {
        AXIsProcessTrusted()
    }
}
