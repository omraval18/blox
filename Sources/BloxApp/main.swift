import AppKit
import BloxPlatform
import Foundation

guard AccessibilityPermission.request() else {
    FileHandle.standardError
        .write(Data("Blox needs Accessibility access: enable it in System Settings, then relaunch.\n".utf8))
    exit(1)
}

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

controller.start()
application.run()
controller.stop()
withExtendedLifetime(signals) {}
