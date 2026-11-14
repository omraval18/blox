extension Config {
    /// Applies a key of one of the settings tables; false when `table` is not one of them.
    mutating func applySetting(_ entry: TOMLEntry, in table: String, curves: [String: Curve]) throws -> Bool {
        switch table {
        case "gaps": try applyGaps(entry)
        case "layout": try applyLayout(entry)
        case "focus": try applyFocus(entry)
        case "border": try applyBorder(entry)
        case "animation": try applyAnimation(entry, curves)
        case "animation.open": try applyOpen(entry, curves)
        case "animation.workspaces": try applyWorkspaces(entry, curves)
        default: return false
        }
        return true
    }

    func unknown(_ entry: TOMLEntry, in table: String) -> ConfigError {
        ConfigError(line: entry.line, message: "unknown setting '\(table).\(entry.key)'")
    }

    private mutating func applyGaps(_ entry: TOMLEntry) throws {
        let range = 0.0 ... 200
        switch entry.key {
        case "inner": settings.gaps.inner = try number(entry, in: range)
        case "outer": settings.gaps.outer = try number(entry, in: range)
        case "outer-top": settings.gaps.outerTop = try number(entry, in: range)
        case "outer-bottom": settings.gaps.outerBottom = try number(entry, in: range)
        case "outer-left": settings.gaps.outerLeft = try number(entry, in: range)
        case "outer-right": settings.gaps.outerRight = try number(entry, in: range)
        case "smart": settings.gaps.smart = try flag(entry)
        default: throw unknown(entry, in: "gaps")
        }
    }

    private mutating func applyLayout(_ entry: TOMLEntry) throws {
        switch entry.key {
        case "default": settings.defaultLayout = try layout(entry)
        case "ratio": settings.defaultRatio = try number(entry, in: Tiling.ratioRange)
        default: throw unknown(entry, in: "layout")
        }
    }

    private mutating func applyFocus(_ entry: TOMLEntry) throws {
        guard entry.key == "mouse-follows" else { throw unknown(entry, in: "focus") }
        settings.mouseFollowsFocus = try flag(entry)
    }

    private mutating func applyBorder(_ entry: TOMLEntry) throws {
        switch entry.key {
        case "enabled": settings.border.enabled = try flag(entry)
        case "width": settings.border.width = try number(entry, in: 1 ... 20)
        case "radius": settings.border.radius = try number(entry, in: 0 ... 40)
        case "angle": settings.border.angle = try number(entry, in: 0 ... 360)
        case "colors": settings.border.colors = try colors(entry)
        case "inactive": settings.border.inactiveColors = try colors(entry)
        default: throw unknown(entry, in: "border")
        }
    }

    private mutating func applyAnimation(_ entry: TOMLEntry, _ curves: [String: Curve]) throws {
        switch entry.key {
        case "style": try settings.animation.applyPreset(style(entry))
        case "enabled": settings.animation.enabled = try flag(entry)
        case "duration": settings.animation.duration = try number(entry, in: Self.durations)
        case "curve": settings.animation.curve = try curve(entry, curves)
        default: throw unknown(entry, in: "animation")
        }
    }

    private mutating func applyOpen(_ entry: TOMLEntry, _ curves: [String: Curve]) throws {
        switch entry.key {
        case "style": settings.animation.open.style = try parse(
                entry,
                Entrance.init,
                "off, slide, popin [percent]",
            )
        case "duration": settings.animation.open.duration = try number(entry, in: Self.durations)
        case "curve": settings.animation.open.curve = try curve(entry, curves)
        default: throw unknown(entry, in: "animation.open")
        }
    }

    private mutating func applyWorkspaces(_ entry: TOMLEntry, _ curves: [String: Curve]) throws {
        switch entry.key {
        case "style": settings.animation.workspaces.style = try parse(
                entry,
                WorkspaceMotion.init,
                "off, slide, slidevert",
            )
        case "duration": settings.animation.workspaces.duration = try number(entry, in: Self.durations)
        case "curve": settings.animation.workspaces.curve = try curve(entry, curves)
        default: throw unknown(entry, in: "animation.workspaces")
        }
    }

    private static let durations = 0.05 ... 1.0

    private func parse<Value>(
        _ entry: TOMLEntry,
        _ make: (String) -> Value?,
        _ choices: String,
    ) throws -> Value {
        guard let value = entry.value.string.flatMap(make) else {
            throw ConfigError(line: entry.line, message: "'\(entry.key)' must be one of: \(choices)")
        }
        return value
    }
}
