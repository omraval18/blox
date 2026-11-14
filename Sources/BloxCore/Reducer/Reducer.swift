/// The only place state changes. Pure: same input, same output.
public func reduce(_ state: State, _ command: Command) -> (State, [Effect]) {
    var next = state
    next.apply(command)
    let layout = PlacementDiff.effects(from: state.placements(), to: next.placements())
    return (
        next,
        WorkspaceSlide.effects(from: state, to: next) + layout
            + ExtraEffects.effects(for: command, from: state, to: next),
    )
}

extension State {
    mutating func apply(_ command: Command) {
        switch command {
        case let .windowAppeared(id, app): addWindow(id, app: app)
        case let .windowDisappeared(id): removeWindow(id)
        case let .focusChanged(id): setFocus(id)
        case let .windowMinSize(id, size): learnMinSize(id, size)
        case let .monitorsChanged(monitors): applyMonitors(monitors)
        case let .focus(direction): focusNeighbor(direction)
        case let .move(direction): moveNeighbor(direction)
        case let .switchWorkspace(name): showWorkspace(name)
        case let .moveToWorkspace(name): sendFocusedWindow(to: name)
        case .workspaceBackAndForth: previousWorkspace.map { showWorkspace($0) }
        case .moveWorkspaceToMonitor: swapWithNextMonitor()
        case let .setLayout(kind): updateFocused { $0.layout = kind }
        case let .resize(delta): updateFocused { $0.ratio = min(max($0.ratio + delta, 0.1), 0.9) }
        case .balance: updateFocused { [settings] in $0.ratio = settings.defaultRatio(for: $0.name) }
        case .toggleFloating: toggleFloatingFocused()
        case .toggleFullscreen: toggleFullscreenFocused()
        case let .setMode(name): mode = name
        case let .setAnimation(name): applyAnimation(named: name)
        case let .updateSettings(settings): self.settings = settings
        case .exec, .retile, .reloadConfig, .close: break
        }
    }
}
