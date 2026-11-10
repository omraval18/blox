public struct Settings: Equatable, Sendable {
    public var gaps: Gaps
    public var defaultLayout: LayoutKind
    public var defaultRatio: Double
    public var animation: AnimationSettings

    public init(
        gaps: Gaps = Gaps(),
        defaultLayout: LayoutKind = .dwindle,
        defaultRatio: Double = 0.5,
        animation: AnimationSettings = AnimationSettings(),
    ) {
        self.animation = animation
        self.gaps = gaps
        self.defaultLayout = defaultLayout
        self.defaultRatio = defaultRatio
    }
}
