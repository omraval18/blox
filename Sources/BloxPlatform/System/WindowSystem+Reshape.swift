import BloxCore

extension WindowSystem {
    /// Move/resize reports are gathered for one display frame, then the window is checked once.
    /// Apps report every intermediate frame, often in bursts after an animation landed; answering
    /// each with an Accessibility read and a ring redraw made the ring jitter behind its window.
    private static let reshapeSettleTime = Duration.milliseconds(16)

    /// A window moved or resized, by Blox or anyone else: check it at most once per display frame.
    func reshaped(_ id: WindowID) {
        guard reshapes.insert(id).inserted else { return }
        Task {
            try? await Task.sleep(for: Self.reshapeSettleTime)
            reshapes.remove(id)
            recheck(id)
        }
    }

    /// Steps of Blox's own animations are skipped; the settled frame is not.
    /// - Shown: its ring follows the real frame (an app that clamps its size, or a drag).
    /// - Hidden: an app that put it back on screen (some resize themselves to a character grid, and
    ///   AppKit pulls the window into view) has it parked again, once; Blox does not fight an app
    ///   that keeps moving it back.
    private func recheck(_ id: WindowID) {
        guard animator.destination(of: id) == nil, let window = windows[id],
              let frame = window.frame else { return }
        guard parked[id] != nil else {
            refusesParking.remove(id)
            border.update(id, frame: frame)
            return border.settle(id)
        }
        guard Displays.isShowing(frame), refusesParking.insert(id).inserted else { return }
        window.move(to: Displays.parkingPoint())
        if window.frame.map(Displays.isShowing) == false {
            refusesParking.remove(id)
        }
    }
}
