@testable import BloxCore
import CoreGraphics

/// Properties that must hold in every reachable state, whatever sequence led there.
enum StateInvariants {
    static func violations(in state: State) -> [String] {
        ownership(state) + focus(state) + monitors(state) + geometry(state)
    }

    private static func ownership(_ state: State) -> [String] {
        let all = state.workspaces.values.flatMap(\.windows)
        var result: [String] = []
        if Set(all).count != all.count {
            result.append("a window lives in two places")
        }
        if !Set(state.minSizes.keys).isSubset(of: all) {
            result.append("minSize kept for a dead window")
        }
        return result
    }

    private static func focus(_ state: State) -> [String] {
        state.workspaces.values.flatMap { workspace -> [String] in
            var result: [String] = []
            if let focused = workspace.focused, !workspace.contains(focused) {
                result.append("\(workspace.name): focus on a window it does not hold")
            }
            if workspace.focused == nil, !workspace.windows.isEmpty {
                result.append("\(workspace.name): holds windows but none is focused")
            }
            if let full = workspace.fullscreen, !workspace.tiled.contains(full) {
                result.append("\(workspace.name): fullscreen window is not tiled")
            }
            if !Tiling.ratioRange.contains(workspace.ratio) {
                result.append("\(workspace.name): ratio \(workspace.ratio) out of range")
            }
            return result
        }
    }

    private static func monitors(_ state: State) -> [String] {
        let names = state.monitors.map(\.workspace)
        var result: [String] = []
        if Set(names).count != names.count {
            result.append("two monitors show one workspace")
        }
        if names
            .contains(where: { state.workspaces[$0] == nil }) {
            result.append("monitor shows a missing workspace")
        }
        if !state.monitors.isEmpty, !state.monitors.indices.contains(state.focusedMonitor) {
            result.append("focused monitor out of range")
        }
        return result
    }

    private static func geometry(_ state: State) -> [String] {
        state.monitors.flatMap { monitor -> [String] in
            guard let workspace = state.workspaces[monitor.workspace],
                  workspace.layout != .monocle, workspace.fullscreen == nil else { return [] }
            let frames = state.tileFrames(workspace, in: monitor.frame)
            let outside = frames.contains { !monitor.frame.insetBy(dx: -1, dy: -1).contains($0) }
            return (outside ? ["tile leaves its monitor"] : []) + (overlaps(frames) ? ["tiles overlap"] : [])
        }
    }

    private static func overlaps(_ frames: [CGRect]) -> Bool {
        frames.indices.contains { first in
            frames.indices.dropFirst(first + 1).contains { second in
                let shared = frames[first].intersection(frames[second])
                return !shared.isNull && shared.width > 1 && shared.height > 1
            }
        }
    }
}
