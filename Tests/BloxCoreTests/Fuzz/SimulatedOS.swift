@testable import BloxCore
import CoreGraphics

/// A fake desktop that obeys effects literally. If replaying every effect leaves it disagreeing with
/// what the state says should be on screen, the reducer lost or mis-ordered an effect.
struct SimulatedOS {
    enum Spot: Equatable {
        case unknown
        case frame(CGRect)
        case parked
    }

    private var spots: [WindowID: Spot] = [:]
    private(set) var problems: [String] = []

    mutating func apply(_ command: Command, effects: [Effect]) {
        switch command {
        case let .windowAppeared(id, _): spots[id] = spots[id] ?? .unknown
        case let .windowDisappeared(id): spots[id] = nil
        default: break
        }
        for effect in effects {
            apply(effect)
        }
    }

    private mutating func apply(_ effect: Effect) {
        switch effect {
        case let .place(id, frame): change(id, to: .frame(frame), effect)
        case let .park(id): change(id, to: .parked, effect)
        case let .unpark(id), let .release(id): change(id, to: .unknown, effect)
        case let .focus(id): require(spots[id] != nil, "focus on dead window \(id.rawValue)")
        case .run, .slide, .close: break
        }
    }

    private mutating func change(_ id: WindowID, to spot: Spot, _ effect: Effect) {
        require(spots[id] != nil, "\(effect) targets a window the OS does not have")
        if case .unpark = effect {
            require(spots[id] == .parked, "unpark of window \(id.rawValue) that is not parked")
        }
        if case .park = effect {
            require(spots[id] != .parked, "park of already parked window \(id.rawValue)")
        }
        spots[id] = spot
    }

    private mutating func require(_ condition: Bool, _ message: @autoclosure () -> String) {
        if !condition {
            problems.append(message())
        }
    }

    /// Where the OS disagrees with the state's idea of the screen.
    func mismatches(against state: State) -> [String] {
        state.placements().compactMap { id, placement in
            let spot = spots[id]
            let agrees: Bool = switch placement {
            case let .frame(frame): spot == .frame(frame)
            case .parked: spot == .parked
            case .free: spot != nil && spot != .parked
            }
            let has = String(describing: spot)
            return agrees ? nil : "window \(id.rawValue): state wants \(placement), OS has \(has)"
        }
    }
}
