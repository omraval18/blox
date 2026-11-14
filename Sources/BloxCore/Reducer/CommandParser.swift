extension Command {
    /// Parses user-facing command text such as `focus left` or `resize 0.05`.
    /// Used for hotkey bindings, the CLI and config, so every entry point speaks one language.
    public init?(parsing text: String) {
        let text = text.trimmed
        if text.hasPrefix("exec "), text.count > 5 {
            self = .exec(String(text.dropFirst(5)).trimmed)
            return
        }
        let words = text.split(separator: " ").map(String.init)
        let parsed: Command? = switch words.count {
        case 1: Self.parse(words[0])
        case 2: Self.parse(words[0], argument: words[1])
        default: nil
        }
        guard let parsed else { return nil }
        self = parsed
    }

    /// Parses `a ; b ; c` into several commands. Empty if any part is invalid.
    public static func sequence(parsing text: String) -> [Command] {
        let commands = text.split(separator: " ; ").map { Command(parsing: String($0)) }
        return commands.contains(nil) ? [] : commands.compactMap(\.self)
    }

    private static func parse(_ word: String) -> Command? {
        switch word {
        case "toggle-floating": .toggleFloating
        case "fullscreen": .toggleFullscreen
        case "close": .close
        case "balance": .balance
        case "retile": .retile
        case "reload-config": .reloadConfig
        case "workspace-back-and-forth": .workspaceBackAndForth
        case "move-workspace-to-monitor": .moveWorkspaceToMonitor
        default: nil
        }
    }

    private static func parse(_ word: String, argument: String) -> Command? {
        switch word {
        case "focus": Direction(rawValue: argument).map(focus)
        case "move": Direction(rawValue: argument).map(move)
        case "workspace": .switchWorkspace(argument)
        case "move-to-workspace": .moveToWorkspace(argument)
        case "layout": LayoutKind(rawValue: argument).map(setLayout)
        case "resize": Double(argument).map(resize)
        case "mode": .setMode(argument)
        case "animation": .setAnimation(argument)
        default: nil
        }
    }
}
