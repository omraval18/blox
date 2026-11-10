import CoreGraphics

/// A display. `frame` is the usable area in top-left-origin global coordinates (the space
/// the Accessibility API uses); the platform layer converts from AppKit's bottom-left space.
public struct Monitor: Equatable, Sendable {
    public var id: UInt32
    public var frame: CGRect
    /// Name of the workspace currently shown here. Empty means "not yet assigned".
    public var workspace: String

    public init(id: UInt32, frame: CGRect, workspace: String = "") {
        self.id = id
        self.frame = frame
        self.workspace = workspace
    }
}
