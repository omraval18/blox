import AppKit
import BloxCore

/// One workspace in the menu: the workspace and the apps that have windows in it, in window order.
struct WorkspaceRow: Equatable {
    let info: WorkspaceInfo
    let apps: [pid_t]

    var appNames: [String] {
        apps.compactMap { NSRunningApplication(processIdentifier: $0)?.localizedName }
    }
}
