import AppKit
import ApplicationServices
import BloxCore

/// Bridges macOS windows to BloxCore: reports what happens as `Command`s and performs `Effect`s.
@MainActor
public final class WindowSystem {
    let onCommand: @MainActor (Command) -> Void
    var observers: [pid_t: AppObserver] = [:]
    var windows: [WindowID: AXWindow] = [:]
    var ids: [AXUIElement: WindowID] = [:]
    var parked: [WindowID: CGRect] = [:]
    /// Hidden windows whose app moved them back on screen even after being parked again.
    var refusesParking: Set<WindowID> = []
    /// Windows reported moved or resized since their last check (see `reshaped`).
    var reshapes: Set<WindowID> = []
    let animator = FrameAnimator()
    /// Kept current by the app after every state change; read for animation and cursor behaviour.
    public var settings = Settings() {
        didSet {
            guard settings.border != oldValue.border else { return }
            border.apply(settings.border)
            syncBorders()
        }
    }

    let border = BorderOverlay()
    var focusedID: WindowID?
    /// Set while executing the effects of a workspace switch.
    var slide: Direction?
    /// Windows that have not been placed yet: their first placement may play the open animation.
    var newWindows: Set<WindowID> = []
    var adoption = Adoption.running
    private var tokens: [any NSObjectProtocol] = []

    public init(onCommand: @escaping @MainActor (Command) -> Void) {
        self.onCommand = onCommand
    }

    public func start() {
        animator.writer.onApplied = { [weak self] id, step in self?.applied(id, step) }
        border.apply(settings.border)
        onCommand(.monitorsChanged(Displays.monitors()))
        adoption = .collecting([:])
        for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular {
            attach(app.processIdentifier)
        }
        placePending()
        tokens = subscribeToSystemEvents()
        reportFrontmostFocus()
    }

    func attach(_ pid: pid_t) {
        guard pid != getpid(), observers[pid] == nil else { return }
        let observer = AppObserver(pid: pid) { [weak self] event in self?.handle(event) }
        guard let observer else { return }
        observers[pid] = observer
        observer.windows.forEach(adopt)
    }

    func detach(_ pid: pid_t) {
        observers.removeValue(forKey: pid)?.stop()
        // First, so nothing is restored on an app that is gone.
        animator.writer.forgetApp(pid)
        releaseWindows(of: pid)
    }

    func releaseWindows(of pid: pid_t) {
        for window in windows.values where window.pid == pid {
            release(window.element)
        }
    }

    func reportFrontmostFocus() {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier,
              let element = observers[pid]?.focusedWindow else { return }
        reportFocus(element)
    }
}
