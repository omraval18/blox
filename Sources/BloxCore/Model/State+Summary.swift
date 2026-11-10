public extension State {
    /// Human-readable overview for `blox status`.
    var summary: String {
        let screens = monitors.enumerated().map { index, monitor in
            let marker = index == focusedMonitor ? "*" : " "
            return "\(marker) monitor \(monitor.id): workspace \(monitor.workspace)"
        }
        let spaces = workspaces.values.sorted { $0.name < $1.name }.map {
            let counts = "\($0.tiled.count) tiled, \($0.floating.count) floating"
            return "  workspace \($0.name): \(counts), \($0.layout.rawValue)"
        }
        return (["mode: \(mode)"] + screens + spaces).joined(separator: "\n")
    }
}
