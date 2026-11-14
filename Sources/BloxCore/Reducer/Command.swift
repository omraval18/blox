import CoreGraphics

public enum Command: Equatable, Sendable {
    // Events reported by the OS.
    case windowAppeared(WindowID, app: String = "")
    case windowDisappeared(WindowID)
    case focusChanged(WindowID)
    /// A window settled larger (minimum) or smaller (maximum) than the frame it was given.
    case windowSizeLimits(WindowID, SizeLimits)
    case monitorsChanged([Monitor])
    // User actions.
    case focus(Direction)
    case move(Direction)
    case switchWorkspace(String)
    case moveToWorkspace(String)
    case workspaceBackAndForth
    case moveWorkspaceToMonitor
    case setLayout(LayoutKind)
    case resize(Double)
    case balance
    case toggleFloating
    case toggleFullscreen
    case close
    case setMode(String)
    case setAnimation(String)
    case exec(String)
    case retile
    case reloadConfig
    case updateSettings(Settings)
}
