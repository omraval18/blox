enum WorkspaceSlide {
    /// A `slide` hint when exactly one monitor now shows a different workspace; none for a monitor
    /// swap or a display change, which have no natural direction.
    static func effects(from old: State, to new: State) -> [Effect] {
        guard old.monitors.count == new.monitors.count else { return [] }
        let changed = zip(old.monitors, new.monitors).filter { $0.workspace != $1.workspace }
        guard changed.count == 1, let (before, after) = changed.first else { return [] }
        return [.slide(WorkspaceOrder.precedes(before.workspace, after.workspace) ? .left : .right)]
    }
}
