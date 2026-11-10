public struct Config: Equatable, Sendable {
    public struct Binding: Equatable, Sendable {
        public let chord: Chord
        public let command: Command
    }

    public var settings = Settings()
    public var bindings: [Binding] = []

    public init() {}

    /// Parses and validates config text. Unknown sections and keys are errors so typos surface.
    public init(parsing text: String) throws {
        let tables = try TOMLParser.parse(text)
        for (name, entries) in tables.sorted(by: { $0.key < $1.key }) {
            for entry in entries {
                try apply(entry, in: name)
            }
        }
    }

    private mutating func apply(_ entry: TOMLEntry, in table: String) throws {
        switch (table, entry.key) {
        case ("gaps", "inner"): settings.gaps.inner = try number(entry, in: 0 ... 200)
        case ("gaps", "outer"): settings.gaps.outer = try number(entry, in: 0 ... 200)
        case ("layout", "default"): settings.defaultLayout = try layout(entry)
        case ("layout", "ratio"): settings.defaultRatio = try number(entry, in: Tiling.ratioRange)
        case ("animation", "enabled"): settings.animation.enabled = try flag(entry)
        case ("animation", "duration"): settings.animation.duration = try number(entry, in: 0.05 ... 1)
        case ("animation", "curve"): settings.animation.curve = try curve(entry)
        case ("bindings", _): try bindings.append(binding(entry))
        default: throw ConfigError(line: entry.line, message: "unknown setting '\(table).\(entry.key)'")
        }
    }

    private func number(_ entry: TOMLEntry, in range: ClosedRange<Double>) throws -> Double {
        guard let value = entry.value.number, range.contains(value) else {
            throw ConfigError(line: entry.line, message: "'\(entry.key)' must be a number in \(range)")
        }
        return value
    }

    private func flag(_ entry: TOMLEntry) throws -> Bool {
        guard case let .bool(value) = entry.value else {
            throw ConfigError(line: entry.line, message: "'\(entry.key)' must be true or false")
        }
        return value
    }

    private func curve(_ entry: TOMLEntry) throws -> Curve {
        guard let curve = entry.value.string.flatMap(Curve.init) else {
            let names = Curve.presetNames.joined(separator: ", ")
            throw ConfigError(line: entry.line, message: "curve must be one of: \(names), or four numbers")
        }
        return curve
    }

    private func layout(_ entry: TOMLEntry) throws -> LayoutKind {
        guard let kind = entry.value.string.flatMap(LayoutKind.init) else {
            let names = LayoutKind.allCases.map(\.rawValue).joined(separator: ", ")
            throw ConfigError(line: entry.line, message: "layout must be one of: \(names)")
        }
        return kind
    }

    private func binding(_ entry: TOMLEntry) throws -> Binding {
        guard let chord = Chord(parsing: entry.key) else {
            throw ConfigError(line: entry.line, message: "invalid key chord '\(entry.key)'")
        }
        guard let command = entry.value.string.flatMap(Command.init) else {
            throw ConfigError(line: entry.line, message: "invalid command for '\(entry.key)'")
        }
        return Binding(chord: chord, command: command)
    }
}
