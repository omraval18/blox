extension State {
    /// Shows `name` on the focused monitor, or focuses the monitor already showing it.
    mutating func showWorkspace(_ name: String) {
        let current = focusedWorkspaceName
        defer {
            if current != name {
                previousWorkspace = current
            }
        }
        if let index = monitors.firstIndex(where: { $0.workspace == name }) {
            focusedMonitor = index
        } else if monitors.indices.contains(focusedMonitor) {
            update(name) { _ in }
            monitors[focusedMonitor].workspace = name
        }
    }

    /// Swaps the focused monitor's workspace with the next monitor's; focus goes with it.
    mutating func swapWithNextMonitor() {
        guard monitors.count > 1 else { return }
        let next = (focusedMonitor + 1) % monitors.count
        let name = monitors[focusedMonitor].workspace
        monitors[focusedMonitor].workspace = monitors[next].workspace
        monitors[next].workspace = name
        focusedMonitor = next
    }

    mutating func sendFocusedWindow(to name: String) {
        guard let id = focusedWindow, name != focusedWorkspaceName else { return }
        updateFocused { $0.remove(id) }
        update(name) { workspace in
            workspace.tiled.append(id)
            workspace.focused = id
        }
    }

    /// Reconciles the display list, keeping each known display's workspace.
    mutating func applyMonitors(_ updated: [Monitor]) {
        let previous = Dictionary(monitors.map { ($0.id, $0.workspace) }) { first, _ in first }
        var used = Set(updated.compactMap { previous[$0.id] })
        monitors = updated.map { monitor in
            var result = monitor
            result.workspace = previous[monitor.id] ?? freeWorkspaceName(avoiding: used)
            used.insert(result.workspace)
            update(result.workspace) { _ in }
            return result
        }
        focusedMonitor = min(focusedMonitor, max(monitors.count - 1, 0))
    }

    private func freeWorkspaceName(avoiding used: Set<String>) -> String {
        (1...).lazy.map(String.init).first { !used.contains($0) } ?? "1"
    }
}
