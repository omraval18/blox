import CoreGraphics

enum Placement: Equatable {
    case frame(CGRect)
    /// Visible but not managed by a layout (floating windows).
    case free
    case parked
}

extension State {
    /// Where every known window should be right now.
    func placements() -> [WindowID: Placement] {
        var result: [WindowID: Placement] = [:]
        for workspace in workspaces.values {
            for id in workspace.windows {
                result[id] = .parked
            }
        }
        for monitor in monitors {
            guard let workspace = workspaces[monitor.workspace] else { continue }
            let frames = tileFrames(workspace, in: monitor.frame)
            for (id, frame) in zip(workspace.tiled, frames) {
                result[id] = .frame(frame)
            }
            for id in workspace.floating {
                result[id] = .free
            }
            if let id = workspace.fullscreen, workspace.tiled.contains(id) {
                result[id] = .frame(monitor.frame)
            }
        }
        return result
    }
}
