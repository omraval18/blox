@testable import BloxIPC
import Foundation
import Testing

struct SocketTests {
    private func temporaryPath() -> String {
        "/tmp/blox-test-\(UUID().uuidString.prefix(8)).sock"
    }

    @Test func `request gets reply`() throws {
        let path = temporaryPath()
        let server = try SocketServer.start(path: path) { "echo: \($0)" }
        defer { server.stop() }
        #expect(try SocketClient.send("focus left", path: path) == "echo: focus left")
        #expect(try SocketClient.send("workspace 2", path: path) == "echo: workspace 2")
    }

    @Test func `socket is private to the user`() throws {
        let path = temporaryPath()
        let server = try SocketServer.start(path: path) { $0 }
        defer { server.stop() }
        let mode = try FileManager.default.attributesOfItem(atPath: path)[.posixPermissions] as? Int
        #expect(mode == 0o600)
    }

    @Test func `connecting without server fails`() {
        #expect(throws: (any Error).self) { try SocketClient.send("x", path: temporaryPath()) }
    }

    @Test func `overlong path is rejected`() {
        let path = "/tmp/" + String(repeating: "a", count: 200)
        #expect(throws: (any Error).self) { try SocketServer.start(path: path) { $0 } }
    }
}
