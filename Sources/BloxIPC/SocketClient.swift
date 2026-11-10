import Darwin

public enum SocketClient {
    /// Sends one request line and returns the reply.
    public static func send(_ request: String, path: String = SocketPath.default) throws -> String {
        let descriptor = try POSIXSocket.connect(path: path)
        defer { close(descriptor) }
        POSIXSocket.setTimeout(descriptor, seconds: 3)
        POSIXSocket.write(descriptor, request + "\n")
        return POSIXSocket.readAll(descriptor).trimmingNewline
    }
}

private extension String {
    var trimmingNewline: String {
        hasSuffix("\n") ? String(dropLast()) : self
    }
}
