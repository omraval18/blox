import AppKit

extension WindowSystem {
    /// Subscribes to app launch/quit/activation and display changes. Returns tokens to retain.
    func subscribeToSystemEvents() -> [any NSObjectProtocol] {
        let workspace = NSWorkspace.shared.notificationCenter
        return [
            observe(NSWorkspace.didLaunchApplicationNotification, on: workspace) { system, pid in
                pid.map(system.attach)
            },
            observe(NSWorkspace.didTerminateApplicationNotification, on: workspace) { system, pid in
                pid.map(system.detach)
            },
            observe(NSWorkspace.didActivateApplicationNotification, on: workspace) { system, _ in
                system.reportFrontmostFocus()
            },
            observe(NSApplication.didChangeScreenParametersNotification, on: .default) { system, _ in
                system.onCommand(.monitorsChanged(Displays.monitors()))
            },
        ]
    }

    private func observe(
        _ name: Notification.Name,
        on center: NotificationCenter,
        _ body: @escaping @MainActor (WindowSystem, pid_t?) -> Void,
    ) -> any NSObjectProtocol {
        center.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
            let pid = runningPID(note)
            MainActor.assumeIsolated { self.map { body($0, pid) } }
        }
    }
}

private func runningPID(_ note: Notification) -> pid_t? {
    (note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.processIdentifier
}
