import Darwin

/// Where the app listens and the CLI connects. Per-user, and the socket file is mode 0600.
public enum SocketPath {
    public static var `default`: String {
        "/tmp/blox-\(getuid()).sock"
    }
}
