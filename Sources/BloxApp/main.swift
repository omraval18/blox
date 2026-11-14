import AppKit
import BloxPlatform
import Foundation

let application = NSApplication.shared
application.setActivationPolicy(.accessory)

let controller = Controller()

/// Put parked windows back before exiting, whether quit from the menu or killed by a signal.
let signals = [SIGINT, SIGTERM].map { number in
    signal(number, SIG_IGN)
    let source = DispatchSource.makeSignalSource(signal: number, queue: .main)
    source.setEventHandler {
        controller.stop()
        exit(0)
    }
    source.resume()
    return source
}

/// Without Accessibility access Blox waits for the grant (the system prompt is already showing)
/// instead of exiting, so enabling it in System Settings is all it takes.
let grantWatcher = AccessibilityPermission.request()
    ? nil : AccessibilityGrantWatcher { controller.start() }
if grantWatcher == nil {
    controller.start()
}

application.run()
controller.stop()
withExtendedLifetime((signals, grantWatcher)) {}
