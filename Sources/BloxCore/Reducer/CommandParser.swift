extension Command {
    /// Parses user-facing command text such as `focus left` or `resize +0.05`.
    /// Used for hotkey bindings, the CLI and config, so every entry point speaks one language.
    public init?(parsing text: String) {
        let words = text.split(separator: " ").map(String.init)
        let parsed: Command? = switch words.count {
        case 1: Self.parse(words[0])
        case 2: Self.parse(words[0], argument: words[1])
        default: nil
        }
        guard let parsed else { return nil }
        self = parsed
    }

    private static func parse(_ word: String) -> Command? {
        switch word {
        case "toggle-floating": .toggleFloating
        case "retile": .retile
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
        default: nil
        }
    }
}
