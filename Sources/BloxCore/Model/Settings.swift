public struct Settings: Equatable, Sendable {
    public var gaps = Gaps()
    public var defaultLayout = LayoutKind.dwindle
    public var defaultRatio = 0.5
    /// Per-workspace starting layout and ratio, keyed by workspace name.
    public var workspaces: [String: WorkspaceDefaults] = [:]
    public var animation = AnimationSettings()
    /// Window rules keyed by app bundle identifier.
    public var rules: [String: WindowRule] = [:]
    public var mouseFollowsFocus = false
    public var border = BorderSettings()

    public init() {}

    func defaultLayout(for workspace: String) -> LayoutKind {
        workspaces[workspace]?.layout ?? defaultLayout
    }

    func defaultRatio(for workspace: String) -> Double {
        workspaces[workspace]?.ratio ?? defaultRatio
    }
}
