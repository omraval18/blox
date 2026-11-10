extension Config {
    func binding(_ entry: TOMLEntry, mode: String) throws -> Binding {
        guard let chord = Chord(parsing: entry.key), mode != Self.mainMode || !chord.modifiers.isEmpty else {
            throw ConfigError(line: entry.line, message: "invalid key chord '\(entry.key)'")
        }
        let commands = Command.sequence(parsing: entry.value.string ?? "")
        guard !commands.isEmpty else {
            throw ConfigError(line: entry.line, message: "invalid command for '\(entry.key)'")
        }
        return Binding(chord: chord, commands: commands)
    }

    /// `"workspace B"`, `"float"`, or both: `"workspace T float"`.
    func rule(_ entry: TOMLEntry) throws -> WindowRule {
        let invalid = ConfigError(
            line: entry.line,
            message: "rule for '\(entry.key)' must be 'workspace <name>' and/or 'float'",
        )
        var rule = WindowRule()
        var words = ArraySlice(entry.value.string?.split(separator: " ") ?? [])
        while let word = words.popFirst() {
            switch word {
            case "float": rule.floating = true
            case "workspace":
                guard let name = words.popFirst() else { throw invalid }
                rule.workspace = String(name)
            default:
                throw invalid
            }
        }
        return rule
    }
}
