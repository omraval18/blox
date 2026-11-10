import Foundation

/// Location of the Unix domain socket the app listens on and the CLI connects to.
public enum SocketPath {
    public static func `default`(user: String = NSUserName()) -> String {
        "/tmp/blox-\(user).sock"
    }
}
