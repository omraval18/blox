public struct Config: Equatable, Sendable {
    public struct Binding: Equatable, Sendable {
        public let chord: Chord
        public let commands: [Command]
    }

    public static let mainMode = "main"

    public var settings = Settings()
    /// Hotkeys per mode. `main` comes from `[bindings]`; other modes from `[mode.<name>]`.
    public var modes: [String: [Binding]] = [:]

    public init() {}

    /// Parses and validates config text. Unknown sections and keys are errors so typos surface.
    public init(parsing text: String) throws {
        let tables = try TOMLParser.parse(text)
        let curves = try Self.customCurves(tables["curves"] ?? [])
        for (name, entries) in tables.sorted(by: { $0.key < $1.key }) where name != "curves" {
            // `style` first, so explicit animation keys override it.
            for entry in entries.sorted(by: { $0.key == "style" && $1.key != "style" }) {
                try apply(entry, in: name, curves: curves)
            }
        }
    }

    private mutating func apply(_ entry: TOMLEntry, in table: String, curves: [String: Curve]) throws {
        if try applySetting(entry, in: table, curves: curves) {
            return
        }
        if table == "rules" {
            settings.rules[entry.key] = try rule(entry)
        } else if let mode = Self.modeName(forTable: table) {
            try modes[mode, default: []].append(binding(entry, mode: mode))
        } else {
            throw unknown(entry, in: table)
        }
    }

    private static func modeName(forTable table: String) -> String? {
        if table == "bindings" {
            return mainMode
        }
        return table.hasPrefix("mode.") ? String(table.dropFirst(5)) : nil
    }
}
