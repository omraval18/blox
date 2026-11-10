/// A ring drawn just outside the focused window. Two or more colors make a gradient.
public struct BorderSettings: Equatable, Sendable {
    public var enabled = false
    public var width = 3.0
    /// Corner radius of the window the ring hugs; macOS windows are about 10-16.
    public var radius = 12.0
    public var colors = [RGBA(red: 0.2, green: 0.8, blue: 1), RGBA(red: 0, green: 1, blue: 0.6)]
    /// Ring for windows that are not focused; empty means only the focused window gets a ring.
    public var inactiveColors: [RGBA] = []
    /// Gradient direction in degrees, counterclockwise from "to the right".
    public var angle = 45.0

    public init() {}
}
