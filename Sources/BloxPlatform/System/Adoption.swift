import BloxCore
import CoreGraphics

/// Whether Blox is taking over the windows that were open before it started. While it is, each
/// adoption re-tiles the rest, so placements are collected (the last frame per window wins) and
/// applied once at the end, without animation, as AeroSpace does. Gliding every window through each
/// intermediate layout would read as lag, not motion.
enum Adoption {
    case running
    case collecting([WindowID: CGRect])

    /// Holds `frame` for `id` while collecting; false when placements should happen right away.
    mutating func hold(_ id: WindowID, _ frame: CGRect) -> Bool {
        guard case var .collecting(pending) = self else { return false }
        pending[id] = frame
        self = .collecting(pending)
        return true
    }

    mutating func drop(_ id: WindowID) {
        guard case var .collecting(pending) = self else { return }
        pending.removeValue(forKey: id)
        self = .collecting(pending)
    }

    /// Ends collecting and returns what was held.
    mutating func finish() -> [WindowID: CGRect] {
        defer { self = .running }
        guard case let .collecting(pending) = self else { return [:] }
        return pending
    }
}
