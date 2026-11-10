public extension State {
    /// Workspaces worth showing: those with windows, plus any currently on a monitor. Sorted by
    /// name, so digits come before letters.
    var overview: [WorkspaceInfo] {
        let shown = Set(monitors.map(\.workspace))
        return workspaces.values
            .filter { !$0.windows.isEmpty || shown.contains($0.name) }
            .sorted { $0.name < $1.name }
            .map {
                WorkspaceInfo(
                    name: $0.name,
                    windows: $0.windows,
                    isFocused: $0.name == focusedWorkspaceName,
                    isVisible: shown.contains($0.name),
                )
            }
    }
}
