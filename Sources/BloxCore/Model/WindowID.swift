/// Stable identifier of a window, as assigned by WindowServer.
public struct WindowID: Hashable, Sendable, Comparable {
    public let rawValue: UInt32

    public init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
