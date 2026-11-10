@testable import BloxCore
import Testing

struct WindowIDTests {
    @Test func `equal I ds are equal`() {
        #expect(WindowID(7) == WindowID(7))
        #expect(WindowID(7) != WindowID(8))
    }
}
