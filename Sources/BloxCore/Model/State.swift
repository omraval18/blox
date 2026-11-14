import CoreGraphics

public struct State: Equatable, Sendable {
    public var settings: Settings
    public var monitors: [Monitor] = []
    public var workspaces: [String: Workspace] = [:]
    public var focusedMonitor = 0
    /// Active binding set (`main` unless a mode such as `resize` was entered).
    public var mode = "main"
    var previousWorkspace: String?
    /// Sizes each window has shown it will accept; minimums only grow, maximums only shrink.
    public internal(set) var sizeLimits: [WindowID: SizeLimits] = [:]

    public init(settings: Settings = Settings()) {
        self.settings = settings
    }

    /// Name of the workspace shown on the focused monitor.
    public var focusedWorkspaceName: String? {
        monitors.indices.contains(focusedMonitor) ? monitors[focusedMonitor].workspace : nil
    }

    public var focusedWindow: WindowID? {
        focusedWorkspaceName.flatMap { workspaces[$0]?.focused }
    }

    func workspaceName(containing id: WindowID) -> String? {
        workspaces.values.first { $0.contains(id) }?.name
    }

    /// Applies `change` to the named workspace, creating it from the defaults if needed.
    mutating func update(_ name: String, _ change: (inout Workspace) -> Void) {
        var workspace = workspaces[name]
            ?? Workspace(
                name: name,
                layout: settings.defaultLayout(for: name),
                ratio: settings.defaultRatio(for: name),
            )
        change(&workspace)
        workspaces[name] = workspace
    }

    mutating func updateFocused(_ change: (inout Workspace) -> Void) {
        if let name = focusedWorkspaceName {
            update(name, change)
        }
    }
}
