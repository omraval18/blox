import CoreGraphics

extension State {
    /// Adds a new window, honouring any rule for its app. Only a window added to the
    /// workspace you are on takes focus.
    mutating func addWindow(_ id: WindowID, app: String) {
        guard workspaceName(containing: id) == nil, let current = focusedWorkspaceName else { return }
        let rule = settings.rules[app]
        let target = rule?.workspace ?? current
        update(target) { workspace in
            if rule?.floating == true {
                workspace.floating.append(id)
            } else {
                workspace.insertTiled(id)
            }
            if target == current || workspace.focused == nil {
                workspace.focused = id
            }
        }
    }

    mutating func removeWindow(_ id: WindowID) {
        sizeLimits.removeValue(forKey: id)
        guard let name = workspaceName(containing: id) else { return }
        update(name) { $0.remove(id) }
    }

    /// The OS moved focus (click, cmd-tab). Follow it, surfacing the window's workspace if hidden.
    mutating func setFocus(_ id: WindowID) {
        guard let name = workspaceName(containing: id) else { return }
        update(name) { $0.focused = id }
        showWorkspace(name)
    }

    /// Remembers what sizes a window accepts, merged with what was seen before.
    mutating func learnSizeLimits(_ id: WindowID, _ observed: SizeLimits) {
        guard workspaceName(containing: id) != nil else { return }
        let known = sizeLimits[id] ?? SizeLimits()
        let merged = known.merged(with: observed)
        if merged != known {
            sizeLimits[id] = merged
        }
    }

    mutating func toggleFloatingFocused() {
        updateFocused { workspace in
            guard let id = workspace.focused else { return }
            if let index = workspace.tiled.firstIndex(of: id) {
                workspace.tiled.remove(at: index)
                workspace.floating.append(id)
                if workspace.fullscreen == id {
                    workspace.fullscreen = nil
                }
            } else {
                workspace.floating.removeAll { $0 == id }
                workspace.tiled.append(id)
            }
        }
    }

    mutating func toggleFullscreenFocused() {
        updateFocused { workspace in
            guard let id = workspace.focused, workspace.tiled.contains(id) else { return }
            workspace.fullscreen = workspace.fullscreen == id ? nil : id
        }
    }

    mutating func applyAnimation(named name: String) {
        if name == "off" {
            settings.animation.enabled = false
        } else if let style = AnimationStyle.named(name) {
            settings.animation.applyPreset(style)
        }
    }
}
