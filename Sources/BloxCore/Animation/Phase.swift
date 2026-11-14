/// One kind of motion (a Hyprland animation leaf such as `windowsIn` or `workspaces`): a style
/// plus optional timing that overrides the window-movement timing.
public struct Phase<Style: Equatable & Sendable>: Equatable, Sendable {
    public var style: Style
    public var duration: Double?
    public var curve: Curve?

    public init(_ style: Style) {
        self.style = style
    }
}
