/// What the menu bar item can ask the app to do.
struct StatusMenuActions {
    let reload: @MainActor () -> Void
    let openConfig: @MainActor () -> Void
    let switchTo: @MainActor (String) -> Void
}
