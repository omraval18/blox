public struct ConfigError: Error, Equatable, Sendable, CustomStringConvertible {
    public let line: Int
    public let message: String

    public var description: String {
        "line \(line): \(message)"
    }
}
