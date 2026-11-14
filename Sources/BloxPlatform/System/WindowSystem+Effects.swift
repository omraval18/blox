import BloxCore
import CoreGraphics

extension WindowSystem {
    /// Performs what the reducer asked for. Windows that vanished in the meantime are skipped.
    public func execute(_ effects: [Effect]) {
        defer { slide = nil }
        for effect in effects {
            switch effect {
            case let .slide(direction): slide = direction
            case let .place(id, frame): place(id, frame)
            case let .park(id): park(id)
            case let .unpark(id): unpark(id)
            case let .focus(id): focus(id)
            case let .close(id): windows[id]?.close()
            case let .release(id): border.remove(id)
            case let .run(line): run(line)
            }
        }
    }

    /// Puts every parked window back where it was, and gives apps back the Accessibility setting
    /// Blox switched off while animating. Called on quit so nothing is left changed.
    public func restoreParked() {
        for id in Array(parked.keys) {
            unpark(id)
        }
        animator.writer.restoreInterfaces()
    }

    /// Runs a shell command. Commands such as dock autohide change the usable screen area without
    /// a notification, so the display geometry is re-read once shortly afterwards.
    private func run(_ line: String) {
        Shell.run(line)
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            onCommand(.monitorsChanged(Displays.monitors()))
        }
    }

    private func focus(_ id: WindowID) {
        guard let window = windows[id] else { return }
        window.raise()
        guard settings.mouseFollowsFocus, let frame = animator.target(of: id) ?? window.frame else { return }
        CGWarpMouseCursorPosition(CGPoint(x: frame.midX, y: frame.midY))
    }

    private func place(_ id: WindowID, _ frame: CGRect) {
        let wasParked = parked.removeValue(forKey: id) != nil
        guard let window = windows[id], !adoption.hold(id, frame) else { return }
        if wasParked, let arrival = slideIn(to: frame) {
            // A window still sliding out turns around from where it is.
            let start = animator.destination(of: id) == nil ? arrival.start : nil
            animator.move(window, to: frame, timing: arrival.timing, from: start)
        } else if newWindows.remove(id) != nil {
            let arrival = entrance(to: frame)
            animator.move(window, to: frame, timing: arrival.timing, from: arrival.start)
        } else {
            animator.move(window, to: frame, timing: settings.animation.moveTiming)
        }
    }

    /// Applies the frames collected while adopting existing windows: once each, without animation.
    func placePending() {
        for (id, frame) in adoption.finish() {
            newWindows.remove(id)
            windows[id].map { animator.move($0, to: frame, timing: nil) }
        }
    }

    private func park(_ id: WindowID) {
        guard let window = windows[id], parked[id] == nil else { return }
        adoption.drop(id)
        newWindows.remove(id)
        let moving = animator.destination(of: id)
        guard let actual = realFrame(of: window) ?? animator.frame(of: id) else { return }
        parked[id] = moving ?? actual
        border.remove(id)
        guard let leave = slideOut(from: actual) else {
            animator.forget(id)
            return window.move(to: Displays.parkingPoint())
        }
        animator.record(id, actual)
        animator.move(
            window,
            to: leave.frame,
            timing: leave.timing,
            finish: .park(leaving: Displays.screen(containing: actual)),
        )
    }

    private func unpark(_ id: WindowID) {
        guard let frame = parked.removeValue(forKey: id), let window = windows[id] else { return }
        if let arrival = slideIn(to: frame) {
            let start = animator.destination(of: id) == nil ? arrival.start : nil
            return animator.move(window, to: frame, timing: arrival.timing, from: start)
        }
        animator.forget(id)
        animator.writer.place(window, frame)
        animator.record(id, frame)
        followBorder(id, frame)
        border.settle(id)
    }
}
