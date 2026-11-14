import ApplicationServices
import BloxCore
import CoreGraphics

/// Hands window frames to the channel of each window's app (ADR 0003) without waiting for it, and
/// keeps the numbers the channels report: how long each app takes per animation step, which also
/// decides whether a slow app is resized only once per glide.
@MainActor
final class FrameWriter {
    private(set) var stats = AnimationStats()
    private var channels: [pid_t: AppChannel] = [:]
    /// Called on the main actor once a channel has applied a step.
    var onApplied: (@MainActor (WindowID, FrameStep) -> Void)?

    /// How `window` changes size on its way `from` -> `to`: an app too slow to resize every frame
    /// (the policy is `ResizeMode`, in Core) is resized once. A shrink is submitted right here; the
    /// frame it asked for, if any, comes back with the glide.
    func begin(_ window: AXWindow, from: CGRect, to: CGRect) -> (glide: Glide, shown: CGRect?) {
        let pace = stats.pace(of: window.pid, .resizing)
        let glide = Glide(from: from, to: to, mode: ResizeMode(averageResizeStep: pace?.average))
        let first = glide.startFrame(from: from, to: to)
        first.map { step(window, to: $0, resizing: true) }
        return (glide, first)
    }

    /// One animation step.
    func step(_ window: AXWindow, to frame: CGRect, resizing: Bool) {
        submit(resizing ? .resize(frame) : .move(frame), for: window)
    }

    /// A whole frame before a glide.
    func place(_ window: AXWindow, _ frame: CGRect) {
        submit(.place(frame), for: window)
    }

    /// The final frame of a move or a snap.
    func settle(_ window: AXWindow, _ frame: CGRect) {
        submit(.settle(frame), for: window)
    }

    func park(_ window: AXWindow) {
        submit(.park(Displays.parkingPoint()), for: window)
    }

    /// An animation of one of the app's windows starts or ends: `AXEnhancedUserInterface` stays off
    /// in between (`AppQueue`).
    func hold(_ pid: pid_t) {
        channel(pid).mailbox.withLock { $0.hold() }
    }

    func release(_ pid: pid_t) {
        guard let channel = channels[pid] else { return }
        if channel.mailbox.withLock({ $0.release() }) {
            wake(channel)
        }
    }

    /// A window is gone: its waiting steps are dropped and its channel forgets it.
    func forget(_ id: WindowID, of pid: pid_t) {
        channels[pid]?.mailbox.withLock { $0.forget(id) }
    }

    /// A display frame's work is done: `work` and the link's frame `interval`, in seconds.
    func frameDone(work: Double, interval: Double) {
        stats.frame(work: work, interval: interval)
    }

    /// An app quit: its channel closes and what was measured about it goes.
    func forgetApp(_ pid: pid_t) {
        stats.drop(pid)
        channels.removeValue(forKey: pid)?.mailbox.withLock { $0.close() }
    }

    /// Blox is quitting: every channel stops taking work, and each app that had
    /// `AXEnhancedUserInterface` switched off gets it back, once its channel's current call is done.
    func closeAll() {
        for (pid, channel) in channels {
            channel.mailbox.withLock { $0.close() }
            channel.finishCurrentCall()
            if channel.mailbox.withLock({ $0.needsRestore }) {
                let app = AXUIElementCreateApplication(pid)
                AXUIElementSetMessagingTimeout(app, 1)
                EnhancedInterface.restore(app)
            }
        }
        channels.removeAll()
    }

    private func submit(_ step: FrameStep, for window: AXWindow) {
        let (id, channel) = (window.id, channel(window.pid))
        if channel.mailbox.withLock({ $0.submit(step, for: id) }) {
            wake(channel)
        }
    }

    private func wake(_ channel: AppChannel) {
        Task { await channel.drain() }
    }

    private func channel(_ pid: pid_t) -> AppChannel {
        if let channel = channels[pid] {
            return channel
        }
        let channel = AppChannel(pid: pid) { [weak self] applied in self?.applied(applied, by: pid) }
        channels[pid] = channel
        return channel
    }

    private func applied(_ applied: AppChannel.Applied, by pid: pid_t) {
        switch applied.step {
        case .resize: stats.answered(pid, .resizing, in: applied.seconds)
        case .move: stats.answered(pid, .moving, in: applied.seconds)
        case .place, .settle, .park: break
        }
        onApplied?(applied.window, applied.step)
    }
}
