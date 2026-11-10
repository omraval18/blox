import Foundation

enum Shell {
    /// Runs `line` with /bin/sh without waiting. Config bindings are user-authored, like a shell rc.
    static func run(_ line: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", line]
        try? process.run()
    }
}
