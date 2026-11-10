public struct Settings: Equatable, Sendable {
    public var gaps = Gaps()
    public var defaultLayout = LayoutKind.dwindle
    public var defaultRatio = 0.5
    public var animation = AnimationSettings()
    /// Window rules keyed by app bundle identifier.
    public var rules: [String: WindowRule] = [:]
    public var mouseFollowsFocus = false

    public init() {}
}
