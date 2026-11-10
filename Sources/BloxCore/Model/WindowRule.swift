/// What to do with a newly detected window of a given app (matched by bundle identifier).
public struct WindowRule: Equatable, Sendable {
    public var workspace: String?
    public var floating = false

    public init(workspace: String? = nil, floating: Bool = false) {
        self.workspace = workspace
        self.floating = floating
    }
}
