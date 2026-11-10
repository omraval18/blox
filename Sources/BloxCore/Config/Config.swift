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
        switch (table, entry.key) {
        case ("gaps", "inner"): settings.gaps.inner = try number(entry, in: 0 ... 200)
        case ("gaps", "outer"): settings.gaps.outer = try number(entry, in: 0 ... 200)
        case ("layout", "default"): settings.defaultLayout = try layout(entry)
        case ("layout", "ratio"): settings.defaultRatio = try number(entry, in: Tiling.ratioRange)
        case ("focus", "mouse-follows"): settings.mouseFollowsFocus = try flag(entry)
        case ("animation", "style"): settings.animation = try style(entry)
        case ("animation", "enabled"): settings.animation.enabled = try flag(entry)
        case ("animation", "duration"): settings.animation.duration = try number(entry, in: 0.05 ... 1)
        case ("animation", "curve"): settings.animation.curve = try curve(entry, curves)
        case ("border", "enabled"): settings.border.enabled = try flag(entry)
        case ("border", "width"): settings.border.width = try number(entry, in: 1 ... 20)
        case ("border", "radius"): settings.border.radius = try number(entry, in: 0 ... 40)
        case ("border", "angle"): settings.border.angle = try number(entry, in: 0 ... 360)
        case ("border", "colors"): settings.border.colors = try colors(entry)
        case ("rules", _): settings.rules[entry.key] = try rule(entry)
        default:
            guard let mode = Self.modeName(forTable: table) else {
                throw ConfigError(line: entry.line, message: "unknown setting '\(table).\(entry.key)'")
            }
            try modes[mode, default: []].append(binding(entry, mode: mode))
        }
    }

    private static func modeName(forTable table: String) -> String? {
        if table == "bindings" {
            return mainMode
        }
        return table.hasPrefix("mode.") ? String(table.dropFirst(5)) : nil
    }
}
