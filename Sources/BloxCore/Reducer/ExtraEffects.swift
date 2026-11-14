/// Effects that are not layout changes: keyboard focus and shell commands.
enum ExtraEffects {
    static func effects(for command: Command, from old: State, to new: State) -> [Effect] {
        switch command {
        case let .exec(line): return [.run(line)]
        case .close: return new.focusedWindow.map { [.close($0)] } ?? []
        case .toggleFullscreen: return new.focusedWindow.map { [.focus($0)] } ?? []
        case .focusChanged: return []
        default:
            // Keyboard focus follows the model, except when the OS itself moved it.
            guard let focus = new.focusedWindow, focus != old.focusedWindow else { return [] }
            return [.focus(focus)]
        }
    }
}
