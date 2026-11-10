/// The only place state changes. Pure: same input, same output.
public func reduce(_ state: State, _ command: Command) -> (State, [Effect]) {
    var next = state
    next.apply(command)
    var effects = PlacementDiff.effects(from: state.placements(), to: next.placements())
    if case .focusChanged = command {} else if let focus = next.focusedWindow, focus != state.focusedWindow {
        effects.append(.focus(focus))
    }
    return (next, effects)
}

extension State {
    mutating func apply(_ command: Command) {
        switch command {
        case let .windowAppeared(id): addWindow(id)
        case let .windowDisappeared(id): removeWindow(id)
        case let .focusChanged(id): setFocus(id)
        case let .monitorsChanged(monitors): applyMonitors(monitors)
        case let .focus(direction): focusNeighbor(direction)
        case let .move(direction): moveNeighbor(direction)
        case let .switchWorkspace(name): showWorkspace(name)
        case let .moveToWorkspace(name): sendFocusedWindow(to: name)
        case let .setLayout(kind): updateFocused { $0.layout = kind }
        case let .resize(delta): updateFocused { $0.ratio = min(max($0.ratio + delta, 0.1), 0.9) }
        case .toggleFloating: toggleFloatingFocused()
        case .retile: break
        }
    }
}
