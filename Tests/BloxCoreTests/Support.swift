@testable import BloxCore
import CoreGraphics

let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)

func id(_ value: UInt32) -> WindowID {
    WindowID(value)
}

/// A state with one monitor showing workspace "1".
func makeState(gaps: Gaps = Gaps(), layout: LayoutKind = .dwindle) -> State {
    var settings = Settings()
    settings.gaps = gaps
    settings.defaultLayout = layout
    let state = State(settings: settings)
    return reduce(state, .monitorsChanged([Monitor(id: 1, frame: screen)])).0
}

/// Applies commands in order, returning the final state and every effect emitted.
func run(_ commands: [Command], from state: State = makeState()) -> (State, [Effect]) {
    commands.reduce((state, [Effect]())) { acc, command in
        let (next, effects) = reduce(acc.0, command)
        return (next, acc.1 + effects)
    }
}

/// A workspace holding `count` tiled windows.
func workspace(_ layout: LayoutKind, count: UInt32, ratio: Double = 0.5) -> Workspace {
    var result = Workspace(name: "t", layout: layout, ratio: ratio)
    result.tiled = (0 ..< count).map(WindowID.init)
    return result
}

func frames(of state: State) -> [CGRect] {
    let name = state.focusedWorkspaceName ?? ""
    return state.workspaces[name].map { state.tileFrames($0, in: screen) } ?? []
}
