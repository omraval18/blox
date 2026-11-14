import ApplicationServices

/// Subscribes to one application's window notifications. Delivery is on the main run loop, and
/// nothing runs between notifications.
@MainActor
final class AppObserver {
    private let observer: AXObserver
    private let application: AXUIElement
    private let onEvent: @MainActor (AXEvent) -> Void

    init?(pid: pid_t, onEvent: @escaping @MainActor (AXEvent) -> Void) {
        var created: AXObserver?
        guard unsafe AXObserverCreate(pid, axCallback, &created) == .success, let created else { return nil }
        observer = created
        application = AXUIElementCreateApplication(pid)
        self.onEvent = onEvent
        AXUIElementSetMessagingTimeout(application, 1)
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(created), .defaultMode)
        let context = unsafe Unmanaged.passUnretained(self).toOpaque()
        let results = [kAXWindowCreatedNotification, kAXFocusedWindowChangedNotification].map {
            unsafe AXObserverAddNotification(created, application, $0 as CFString, context)
        }
        guard results.allSatisfy({ $0 == .success || $0 == .notificationAlreadyRegistered }) else {
            stop()
            return nil
        }
    }

    var windows: [AXUIElement] {
        AXAttribute.elements(application, kAXWindowsAttribute)
    }

    var focusedWindow: AXUIElement? {
        AXAttribute.element(application, kAXFocusedWindowAttribute)
    }

    func watch(_ window: AXUIElement) {
        let context = unsafe Unmanaged.passUnretained(self).toOpaque()
        for name in [
            kAXUIElementDestroyedNotification,
            kAXWindowMiniaturizedNotification,
            kAXWindowDeminiaturizedNotification,
            kAXMovedNotification,
            kAXResizedNotification,
        ] {
            unsafe AXObserverAddNotification(observer, window, name as CFString, context)
        }
    }

    func stop() {
        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
    }

    fileprivate func dispatch(_ name: String, _ element: AXUIElement) {
        switch name {
        case kAXWindowCreatedNotification: onEvent(.created(element))
        case kAXUIElementDestroyedNotification: onEvent(.destroyed(element))
        case kAXFocusedWindowChangedNotification: onEvent(.focused(element))
        case kAXWindowMiniaturizedNotification: onEvent(.minimized(element))
        case kAXWindowDeminiaturizedNotification: onEvent(.restored(element))
        case kAXMovedNotification, kAXResizedNotification: onEvent(.reshaped(element))
        default: break
        }
    }
}

private func axCallback(
    _: AXObserver,
    _ element: AXUIElement,
    _ notification: CFString,
    _ context: UnsafeMutableRawPointer?,
) {
    guard let context = unsafe context else { return }
    let target = unsafe Unmanaged<AppObserver>.fromOpaque(context).takeUnretainedValue()
    // AXUIElement is not Sendable, but this callback is delivered on the main run loop (the source
    // is added to it) and the value never leaves the main actor.
    // swiftlint:disable:next no_unsafe_concurrency
    nonisolated(unsafe) let element = element
    let name = notification as String
    MainActor.assumeIsolated { unsafe target.dispatch(name, element) }
}
