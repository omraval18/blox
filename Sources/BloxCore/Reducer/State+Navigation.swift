import CoreGraphics

extension State {
    mutating func focusNeighbor(_ direction: Direction) {
        guard let target = neighbor(direction) else { return }
        updateFocused { $0.focused = target }
    }

    /// Swaps the focused window with its neighbour in `direction`.
    mutating func moveNeighbor(_ direction: Direction) {
        guard let id = focusedWindow, let target = neighbor(direction) else { return }
        updateFocused { workspace in
            guard let from = workspace.tiled.firstIndex(of: id),
                  let to = workspace.tiled.firstIndex(of: target) else { return }
            workspace.tiled.swapAt(from, to)
        }
    }

    private func neighbor(_ direction: Direction) -> WindowID? {
        guard let name = focusedWorkspaceName, let workspace = workspaces[name],
              let current = workspace.focused, let index = workspace.tiled.firstIndex(of: current),
              monitors.indices.contains(focusedMonitor) else { return nil }
        if workspace.layout == .monocle {
            return Self.cycle(workspace.tiled, from: index, direction)
        }
        let frames = Tiling.frames(workspace, in: monitors[focusedMonitor].frame, gaps: settings.gaps)
        return Self.nearest(to: index, in: frames, direction).map { workspace.tiled[$0] }
    }

    private static func cycle(_ ids: [WindowID], from index: Int, _ direction: Direction) -> WindowID? {
        let step = (direction == .left || direction == .up) ? -1 : 1
        return ids.isEmpty ? nil : ids[(index + step + ids.count) % ids.count]
    }

    /// Closest frame whose centre lies in `direction`; off-axis distance counts double.
    private static func nearest(to index: Int, in frames: [CGRect], _ direction: Direction) -> Int? {
        let origin = frames[index].center
        let scored = frames.indices.compactMap { candidate -> (Int, Double)? in
            let delta = (dx: frames[candidate].center.x - origin.x, dy: frames[candidate].center.y - origin.y)
            let (along, across) = switch direction {
            case .left: (-delta.dx, abs(delta.dy))
            case .right: (delta.dx, abs(delta.dy))
            case .up: (-delta.dy, abs(delta.dx))
            case .down: (delta.dy, abs(delta.dx))
            }
            return along > 0 ? (candidate, along + 2 * across) : nil
        }
        return scored.min { $0.1 < $1.1 }?.0
    }
}

extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
