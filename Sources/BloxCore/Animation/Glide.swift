import CoreGraphics

/// How a window's size changes while it glides from one frame to another.
public enum Glide: Equatable, Sendable {
    /// Size and position follow the curve together (or the size does not change).
    case blend
    /// Resized once, to the final size, before it moves; then it only moves. Shrinking first means
    /// it never overlaps the neighbour it is making room for.
    case shrinkFirst
    /// Moves at its old size and takes the final size on arrival, so it never grows into a
    /// neighbour that has not left yet.
    case growLast

    public init(from: CGRect, to: CGRect, mode: ResizeMode) {
        guard mode == .once, from.size != to.size else {
            self = .blend
            return
        }
        self = to.width * to.height < from.width * from.height ? .shrinkFirst : .growLast
    }

    /// The frame to set before the glide starts; nil when there is none.
    public func startFrame(from: CGRect, to: CGRect) -> CGRect? {
        self == .shrinkFirst ? CGRect(origin: from.origin, size: to.size) : nil
    }

    /// Whether each step must set the size as well as the position.
    public func resizesEachStep(from: CGRect, to: CGRect) -> Bool {
        self == .blend && from.size != to.size
    }

    /// The frame to apply at `progress` (0...1) of the way.
    public func frame(from: CGRect, to: CGRect, progress: Double) -> CGRect {
        let blended = from.interpolated(to: to, progress: progress)
        switch self {
        case .blend: return blended
        case .shrinkFirst: return CGRect(origin: blended.origin, size: to.size)
        case .growLast: return CGRect(origin: blended.origin, size: from.size)
        }
    }
}
