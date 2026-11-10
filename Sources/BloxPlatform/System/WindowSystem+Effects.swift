import BloxCore
import CoreGraphics

extension WindowSystem {
    /// Performs what the reducer asked for. Windows that vanished in the meantime are skipped.
    public func execute(_ effects: [Effect]) {
        for effect in effects {
            switch effect {
            case let .place(id, frame): place(id, frame)
            case let .park(id): park(id)
            case let .unpark(id): unpark(id)
            case let .focus(id): windows[id]?.raise()
            }
        }
    }

    private func place(_ id: WindowID, _ frame: CGRect) {
        parked.removeValue(forKey: id)
        windows[id]?.setFrame(frame)
    }

    private func park(_ id: WindowID) {
        guard let window = windows[id], parked[id] == nil, let frame = window.frame else { return }
        parked[id] = frame
        window.move(to: Displays.parkingPoint())
    }

    private func unpark(_ id: WindowID) {
        guard let frame = parked.removeValue(forKey: id) else { return }
        windows[id]?.setFrame(frame)
    }
}
