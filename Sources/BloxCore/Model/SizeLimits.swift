import CoreGraphics

/// The sizes a window has shown it will accept. Zero on an axis means unknown: no limit.
/// Some apps refuse to shrink (minimum); some refuse to grow (System Settings has a fixed width).
public struct SizeLimits: Equatable, Sendable {
    public var minimum: CGSize
    public var maximum: CGSize

    public init(minimum: CGSize = .zero, maximum: CGSize = .zero) {
        self.minimum = minimum
        self.maximum = maximum
    }

    /// Combines two observations: minimums only grow and maximums only shrink, so layouts settle.
    func merged(with other: Self) -> Self {
        Self(
            minimum: CGSize(
                width: max(minimum.width, other.minimum.width),
                height: max(minimum.height, other.minimum.height),
            ),
            maximum: CGSize(
                width: Self.tighter(maximum.width, other.maximum.width),
                height: Self.tighter(maximum.height, other.maximum.height),
            ),
        )
    }

    /// Grown by `amount` on every known limit: layouts split padded areas, so a window's limits
    /// must include the gap around it.
    func padded(by amount: Double) -> Self {
        Self(minimum: Self.pad(minimum, amount), maximum: Self.pad(maximum, amount))
    }

    /// `frame` shrunk to the known maximum on each axis and centred in it, so the window is asked
    /// for a size it will actually take (a fixed-width window alone on a workspace sits centred).
    func fitting(_ frame: CGRect) -> CGRect {
        let width = maximum.width == 0 ? frame.width : min(frame.width, maximum.width)
        let height = maximum.height == 0 ? frame.height : min(frame.height, maximum.height)
        return CGRect(
            x: (frame.midX - width / 2).rounded(),
            y: (frame.midY - height / 2).rounded(),
            width: width,
            height: height,
        )
    }

    private static func tighter(_ lhs: Double, _ rhs: Double) -> Double {
        lhs == 0 ? rhs : rhs == 0 ? lhs : min(lhs, rhs)
    }

    private static func pad(_ size: CGSize, _ amount: Double) -> CGSize {
        CGSize(
            width: size.width == 0 ? 0 : size.width + amount,
            height: size.height == 0 ? 0 : size.height + amount,
        )
    }
}
