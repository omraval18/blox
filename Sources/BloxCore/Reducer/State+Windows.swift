extension State {
    mutating func addWindow(_ id: WindowID) {
        guard workspaceName(containing: id) == nil else { return }
        updateFocused { workspace in
            let anchor = workspace.focused.flatMap { workspace.tiled.firstIndex(of: $0) }
            workspace.tiled.insert(id, at: anchor.map { $0 + 1 } ?? workspace.tiled.count)
            workspace.focused = id
        }
    }

    mutating func removeWindow(_ id: WindowID) {
        guard let name = workspaceName(containing: id) else { return }
        update(name) { $0.remove(id) }
    }

    /// The OS moved focus (click, cmd-tab). Follow it, surfacing the window's workspace if hidden.
    mutating func setFocus(_ id: WindowID) {
        guard let name = workspaceName(containing: id) else { return }
        update(name) { $0.focused = id }
        showWorkspace(name)
    }

    mutating func toggleFloatingFocused() {
        updateFocused { workspace in
            guard let id = workspace.focused else { return }
            if let index = workspace.tiled.firstIndex(of: id) {
                workspace.tiled.remove(at: index)
                workspace.floating.append(id)
            } else {
                workspace.floating.removeAll { $0 == id }
                workspace.tiled.append(id)
            }
        }
    }
}
