import CoreGraphics

enum PlacementDiff {
    /// Effects needed to move from `old` to `new`, in a stable order.
    static func effects(from old: [WindowID: Placement], to new: [WindowID: Placement]) -> [Effect] {
        new.sorted { $0.key < $1.key }.compactMap { id, placement in
            guard old[id] != placement else { return nil }
            switch placement {
            case let .frame(frame): return .place(id, frame)
            case .parked: return .park(id)
            case .free: return old[id] == .parked ? .unpark(id) : nil
            }
        }
    }
}
