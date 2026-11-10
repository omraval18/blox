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
            case let .focus(id): focus(id)
            case let .run(line): Shell.run(line)
            }
        }
    }

    /// Puts every parked window back where it was. Called on quit so nothing is left offscreen.
    public func restoreParked() {
        for id in Array(parked.keys) {
            unpark(id)
        }
    }

    private func focus(_ id: WindowID) {
        guard let window = windows[id] else { return }
        window.raise()
        guard settings.mouseFollowsFocus, let frame = animator.target(of: id) ?? window.frame else { return }
        CGWarpMouseCursorPosition(CGPoint(x: frame.midX, y: frame.midY))
    }

    private func place(_ id: WindowID, _ frame: CGRect) {
        parked.removeValue(forKey: id)
        guard let window = windows[id] else { return }
        animator.move(window, to: frame, using: settings.animation)
    }

    private func park(_ id: WindowID) {
        guard let window = windows[id], parked[id] == nil, let frame = window.frame else { return }
        parked[id] = frame
        animator.forget(id)
        window.move(to: Displays.parkingPoint())
    }

    private func unpark(_ id: WindowID) {
        guard let frame = parked.removeValue(forKey: id) else { return }
        windows[id]?.setFrame(frame)
        animator.record(id, frame)
    }
}
