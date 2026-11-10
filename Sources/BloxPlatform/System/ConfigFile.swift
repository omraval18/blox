import BloxCore
import Foundation

/// The config on disk: `~/.config/blox/blox.toml`, created from the defaults on first run.
public struct ConfigFile: Sendable {
    public let path: String

    public init(path: String = NSHomeDirectory() + "/.config/blox/blox.toml") {
        self.path = path
    }

    public var directory: String {
        (path as NSString).deletingLastPathComponent
    }

    /// Reads the file, writing the default config first if none exists.
    public func read() throws -> String {
        if !FileManager.default.fileExists(atPath: path) {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
            try Config.defaultText.write(toFile: path, atomically: true, encoding: .utf8)
        }
        return try String(contentsOfFile: path, encoding: .utf8)
    }
}
