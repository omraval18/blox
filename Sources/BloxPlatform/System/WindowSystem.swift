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
    let animator = FrameAnimator()
    /// Kept current by the app after every state change; read for animation and cursor behaviour.
    public var settings = Settings() {
        didSet {
            guard settings.border != oldValue.border else { return }
            border.apply(settings.border)
            syncBorder()
        }
    }

    let border = BorderOverlay()
    var focusedID: WindowID?
    private var tokens: [any NSObjectProtocol] = []

    public init(onCommand: @escaping @MainActor (Command) -> Void) {
        self.onCommand = onCommand
    }

    public func start() {
        animator.onFrame = { [weak self] id, frame in self?.followBorder(id, frame) }
        animator.onSettled = { [weak self] window, frame in self?.checkMinimum(window, frame) }
        border.apply(settings.border)
        onCommand(.monitorsChanged(Displays.monitors()))
        for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular {
            attach(app.processIdentifier)
        }
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
        for window in windows.values where window.pid == pid {
            release(window.element)
        }
    }

    func reportFrontmostFocus() {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier,
              let element = observers[pid]?.focusedWindow else { return }
        adopt(element)
        ids[element].map { onCommand(.focusChanged($0)) }
    }
}
