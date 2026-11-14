/// Everything one app's frame channel has to do, shared by the main actor (which adds work) and
/// the channel (which takes it one item at a time). Pure bookkeeping: the channel makes the calls.
///
/// It also decides when the app's `AXEnhancedUserInterface` is switched off and back on (some apps
/// animate their own resizes while it is on): checked before the first step of a session, restored
/// once no frame change is held and nothing waits (see `hold()`).
public struct AppQueue: Sendable {
    public enum Work: Equatable, Sendable {
        /// Read the interface setting and switch it off if on, then report with `checked(switchedOff:)`.
        case suspendInterface
        case step(WindowID, FrameStep)
        /// Switch the interface setting back on.
        case restoreInterface
        /// Drop what is cached about a window that is gone.
        case forget(WindowID)
    }

    private enum Interface: Sendable {
        case unknown
        case untouched
        case switchedOff
    }

    private var windows: [WindowID: StepQueue] = [:]
    private var forgotten: [WindowID] = []
    private var holds = 0
    private var interface = Interface.unknown
    private var draining = false
    private var closed = false

    public init() {}

    /// The setting was switched off and is not back on yet.
    public var needsRestore: Bool {
        interface == .switchedOff
    }

    /// Adds a step for a window; true when the channel is idle and must be woken to apply it.
    public mutating func submit(_ step: FrameStep, for id: WindowID) -> Bool {
        guard !closed else { return false }
        windows[id, default: StepQueue()].push(step)
        return wake()
    }

    /// A frame change for this app starts (an animation): the setting stays off until it ends.
    public mutating func hold() {
        holds += 1
    }

    /// A frame change ends; true when the channel must be woken to restore the setting.
    public mutating func release() -> Bool {
        holds = max(holds - 1, 0)
        guard holds == 0, !closed else { return false }
        if interface == .untouched, !draining {
            interface = .unknown
        }
        return interface == .switchedOff && wake()
    }

    /// A window is gone: its waiting steps are dropped and the channel forgets it on its next run.
    public mutating func forget(_ id: WindowID) {
        windows.removeValue(forKey: id)
        forgotten.append(id)
    }

    /// The channel's next item, or nil when there is none: it goes idle until a submit wakes it.
    public mutating func next() -> Work? {
        if !closed, let work = forgotten.popLast().map(Work.forget) ?? nextStep() ?? restore() {
            return work
        }
        draining = false
        return nil
    }

    public mutating func checked(switchedOff: Bool) {
        interface = switchedOff ? .switchedOff : .untouched
    }

    /// The app quit, or Blox is quitting: no more work is taken.
    public mutating func close() {
        closed = true
        windows.removeAll()
        forgotten.removeAll()
    }

    private mutating func nextStep() -> Work? {
        guard let id = windows.first(where: { !$0.value.isEmpty })?.key else { return nil }
        if interface == .unknown {
            interface = .untouched
            return .suspendInterface
        }
        let step = windows[id]?.pop()
        if windows[id]?.isEmpty == true {
            windows.removeValue(forKey: id)
        }
        return step.map { .step(id, $0) }
    }

    /// Once nothing is held or waiting, the setting goes back on, and is read afresh next time.
    private mutating func restore() -> Work? {
        guard holds == 0 else { return nil }
        defer { interface = .unknown }
        return interface == .switchedOff ? .restoreInterface : nil
    }

    private mutating func wake() -> Bool {
        guard !draining else { return false }
        draining = true
        return true
    }
}
