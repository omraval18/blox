public extension Config {
    /// Every workspace name the config can reach: from bindings and from window rules.
    var workspaceNames: [String] {
        let bound = modes.values.joined().flatMap(\.commands).compactMap { command -> String? in
            switch command {
            case let .switchWorkspace(name), let .moveToWorkspace(name): name
            default: nil
            }
        }
        return Set(bound + settings.rules.values.compactMap(\.workspace)).sorted()
    }
}
