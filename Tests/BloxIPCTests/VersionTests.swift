@testable import BloxIPC
import Foundation
import Testing

struct VersionTests {
    @Test func `version constant matches version file`() throws {
        let file = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("VERSION")
        let contents = try String(contentsOf: file, encoding: .utf8)
        #expect(contents.trimmingCharacters(in: .whitespacesAndNewlines) == bloxVersion)
    }
}
