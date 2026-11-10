extension Config {
    func number(_ entry: TOMLEntry, in range: ClosedRange<Double>) throws -> Double {
        guard let value = entry.value.number, range.contains(value) else {
            throw ConfigError(line: entry.line, message: "'\(entry.key)' must be a number in \(range)")
        }
        return value
    }

    func flag(_ entry: TOMLEntry) throws -> Bool {
        guard case let .bool(value) = entry.value else {
            throw ConfigError(line: entry.line, message: "'\(entry.key)' must be true or false")
        }
        return value
    }

    func layout(_ entry: TOMLEntry) throws -> LayoutKind {
        guard let kind = entry.value.string.flatMap(LayoutKind.init) else {
            let names = LayoutKind.allCases.map(\.rawValue).joined(separator: ", ")
            throw ConfigError(line: entry.line, message: "layout must be one of: \(names)")
        }
        return kind
    }

    func style(_ entry: TOMLEntry) throws -> AnimationSettings {
        guard let style = entry.value.string.flatMap(AnimationStyle.named) else {
            let names = AnimationStyle.names.joined(separator: ", ")
            throw ConfigError(line: entry.line, message: "style must be one of: \(names)")
        }
        return style
    }

    /// One or more hex colors separated by spaces, e.g. `"33ccff 00ff99"`.
    func colors(_ entry: TOMLEntry) throws -> [RGBA] {
        let colors = (entry.value.string?.split(separator: " ") ?? []).map { RGBA(hex: String($0)) }
        guard !colors.isEmpty, !colors.contains(nil) else {
            throw ConfigError(line: entry.line, message: "colors must be hex values like \"33ccff 00ff99\"")
        }
        return colors.compactMap(\.self)
    }

    /// A custom curve by name, else a preset name or four numbers.
    func curve(_ entry: TOMLEntry, _ custom: [String: Curve]) throws -> Curve {
        guard let text = entry.value.string, let curve = custom[text] ?? Curve(parsing: text) else {
            let names = (Curve.presetNames + custom.keys.sorted()).joined(separator: ", ")
            throw ConfigError(line: entry.line, message: "curve must be one of: \(names), or four numbers")
        }
        return curve
    }

    /// The `[curves]` table: `name = "x1 y1 x2 y2"`, Hyprland-style user-defined beziers.
    static func customCurves(_ entries: [TOMLEntry]) throws -> [String: Curve] {
        var curves: [String: Curve] = [:]
        for entry in entries {
            guard let curve = entry.value.string.flatMap(Curve.init) else {
                throw ConfigError(
                    line: entry.line,
                    message: "curve '\(entry.key)' must be four numbers: x1 y1 x2 y2",
                )
            }
            curves[entry.key] = curve
        }
        return curves
    }
}
