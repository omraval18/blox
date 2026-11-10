public enum Command: Equatable, Sendable {
    // Events reported by the OS.
    case windowAppeared(WindowID)
    case windowDisappeared(WindowID)
    case focusChanged(WindowID)
    case monitorsChanged([Monitor])
    // User actions.
    case focus(Direction)
    case move(Direction)
    case switchWorkspace(String)
    case moveToWorkspace(String)
    case setLayout(LayoutKind)
    case resize(Double)
    case toggleFloating
    case retile
    case updateSettings(Settings)
}
