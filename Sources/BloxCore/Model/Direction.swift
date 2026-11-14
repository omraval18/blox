import CoreGraphics

public enum Direction: String, Sendable, CaseIterable {
    case left, right, up, down

    /// A displacement of `distance` points this way (y grows downward).
    public func offset(_ distance: Double) -> CGVector {
        switch self {
        case .left: CGVector(dx: -distance, dy: 0)
        case .right: CGVector(dx: distance, dy: 0)
        case .up: CGVector(dx: 0, dy: -distance)
        case .down: CGVector(dx: 0, dy: distance)
        }
    }

    public var opposite: Self {
        switch self {
        case .left: .right
        case .right: .left
        case .up: .down
        case .down: .up
        }
    }
}
