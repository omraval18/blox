public extension State {
    /// Workspaces for a bar: every name in `known` (the ones your config can switch to), plus any
    /// that hold windows or are on a monitor. Sorted by name, so digits come before letters.
    func overview(including known: [String] = []) -> [WorkspaceInfo] {
        let shown = Set(monitors.map(\.workspace))
        let occupied = workspaces.filter { !$0.value.windows.isEmpty }.keys
        return Set(known).union(occupied).union(shown).sorted(by: WorkspaceOrder.precedes).map { name in
            WorkspaceInfo(
                name: name,
                windows: workspaces[name]?.windows ?? [],
                isFocused: name == focusedWorkspaceName,
                isVisible: shown.contains(name),
            )
        }
    }
}
