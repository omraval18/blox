import ApplicationServices

/// Keeps `AXEnhancedUserInterface` off while Blox sets an app's window frames. Assistive tools
/// switch it on, and with it some apps (Chromium, Electron) animate their own resizes and fight the
/// animator. It is read once when the app's first frame change starts, switched off only if it was
/// on, and switched back on when the app's last frame change ends. Apps where it is off are never
/// written to.
struct EnhancedInterface {
    private static let attribute = "AXEnhancedUserInterface"

    /// How many frame changes are under way for an app, and whether Blox switched the attribute off.
    private enum Hold {
        case untouched(Int)
        case switchedOff(Int)
    }

    private var holds: [pid_t: Hold] = [:]

    /// A frame change for an app's window starts.
    mutating func begin(_ pid: pid_t) {
        switch holds[pid] {
        case let .untouched(count): holds[pid] = .untouched(count + 1)
        case let .switchedOff(count): holds[pid] = .switchedOff(count + 1)
        case nil: holds[pid] = Self.switchOff(Self.application(pid)) ? .switchedOff(1) : .untouched(1)
        }
    }

    /// A frame change ends. When it was the app's last, the attribute is restored if Blox changed it.
    mutating func end(_ pid: pid_t) {
        switch holds[pid] {
        case let .untouched(count) where count > 1: holds[pid] = .untouched(count - 1)
        case let .switchedOff(count) where count > 1: holds[pid] = .switchedOff(count - 1)
        case .switchedOff: restore(pid)
        case .untouched, nil: holds.removeValue(forKey: pid)
        }
    }

    /// Restores every app Blox changed, whatever is still under way (Blox is quitting).
    mutating func restoreAll() {
        for pid in Array(holds.keys) {
            if case .switchedOff = holds[pid] {
                restore(pid)
            }
        }
        holds.removeAll()
    }

    /// The app quit: there is nothing left to restore.
    mutating func drop(_ pid: pid_t) {
        holds.removeValue(forKey: pid)
    }

    private mutating func restore(_ pid: pid_t) {
        holds.removeValue(forKey: pid)
        AXAttribute.set(Self.application(pid), Self.attribute, bool: true)
    }

    /// Switches the attribute off if it is on; true when it did.
    private static func switchOff(_ app: AXUIElement) -> Bool {
        guard AXAttribute.flag(app, attribute) else { return false }
        return AXAttribute.set(app, attribute, bool: false)
    }

    private static func application(_ pid: pid_t) -> AXUIElement {
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app, 1)
        return app
    }
}
