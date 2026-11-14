import ApplicationServices
import BloxCore
import Dispatch
import os
import QuartzCore

/// Sets one app's window frames off the main actor, so a slow app costs only its own frames and a
/// hung one (1 s Accessibility timeout) stalls neither the other apps nor tiling (ADR 0003).
///
/// It owns its Accessibility elements: they are not `Sendable`, so it resolves windows by ID from
/// the app's window list itself and nothing but IDs, frames and steps crosses in or out. It runs on
/// its own serial queue, so a blocking call never holds a thread of the shared concurrency pool.
actor AppChannel {
    /// What was applied, reported back to the main actor.
    struct Applied: Sendable {
        let window: WindowID
        let step: FrameStep
        /// How long the app took to answer, in seconds.
        let seconds: Double
    }

    /// Shared with the main actor, which adds work without waiting for the channel.
    nonisolated let mailbox = OSAllocatedUnfairLock(initialState: AppQueue())
    private let queue: DispatchSerialQueue
    private let app: AXUIElement
    private var windows: [WindowID: AXWindow] = [:]
    private let report: @MainActor @Sendable (Applied) -> Void

    init(pid: pid_t, report: @escaping @MainActor @Sendable (Applied) -> Void) {
        queue = DispatchSerialQueue(label: "blox.channel.\(pid)")
        app = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app, 1)
        self.report = report
    }

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        unsafe queue.asUnownedSerialExecutor()
    }

    /// Waits until whatever the channel is doing right now is done (Blox is quitting).
    nonisolated func finishCurrentCall() {
        queue.sync {}
    }

    /// Takes work until none is left. Only one drain runs at a time: the mailbox wakes the channel
    /// only when it was idle.
    func drain() async {
        while let work = mailbox.withLock({ $0.next() }) {
            await perform(work)
        }
    }

    private func perform(_ work: AppQueue.Work) async {
        switch work {
        case .suspendInterface:
            let switchedOff = EnhancedInterface.switchOff(app)
            mailbox.withLock { $0.checked(switchedOff: switchedOff) }
        case .restoreInterface:
            EnhancedInterface.restore(app)
        case let .forget(id):
            windows.removeValue(forKey: id)
        case let .step(id, step):
            let began = CACurrentMediaTime()
            guard apply(step, to: id) else { return }
            await report(Applied(window: id, step: step, seconds: CACurrentMediaTime() - began))
        }
    }

    /// False when the window could not be found or did not answer; it is looked up afresh next time.
    private func apply(_ step: FrameStep, to id: WindowID) -> Bool {
        guard let window = window(id) else { return false }
        let applied = switch step {
        case let .resize(frame): window.setStep(frame, resizing: true)
        case let .move(frame): window.setStep(frame, resizing: false)
        case let .place(frame), let .settle(frame): window.setFrame(frame)
        case let .park(point): window.move(to: point)
        }
        if !applied {
            windows.removeValue(forKey: id)
        }
        return applied
    }

    private func window(_ id: WindowID) -> AXWindow? {
        if let known = windows[id] {
            return known
        }
        let found = AXAttribute.elements(app, kAXWindowsAttribute).lazy.compactMap(AXWindow.init)
            .first { $0.id == id }
        windows[id] = found
        return found
    }
}
