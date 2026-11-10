import BloxCore

/// One line of the workspace menu: the workspace and the apps that have windows in it.
struct WorkspaceRow: Equatable {
    let info: WorkspaceInfo
    let apps: [String]
}
