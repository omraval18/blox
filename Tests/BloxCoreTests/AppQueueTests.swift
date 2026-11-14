@testable import BloxCore
import CoreGraphics
import Testing

struct AppQueueTests {
    private let one = WindowID(1)
    private let frame = CGRect(x: 0, y: 0, width: 400, height: 300)

    /// Takes work until the channel would go idle, reporting the setting as `switchedOff`.
    private func drain(_ queue: inout AppQueue, switchedOff: Bool) -> [AppQueue.Work] {
        var done: [AppQueue.Work] = []
        while let work = queue.next() {
            done.append(work)
            if work == .suspendInterface {
                queue.checked(switchedOff: switchedOff)
            }
        }
        return done
    }

    @Test func `only a submit to an idle channel wakes it`() {
        var queue = AppQueue()
        let first = queue.submit(.move(frame), for: one)
        let second = queue.submit(.move(frame), for: one)
        _ = drain(&queue, switchedOff: false)
        let afterIdle = queue.submit(.settle(frame), for: one)
        #expect(first && !second && afterIdle)
    }

    @Test func `a snap checks the setting, applies, and restores it`() {
        var queue = AppQueue()
        _ = queue.submit(.place(frame), for: one)
        let work = drain(&queue, switchedOff: true)
        #expect(work == [.suspendInterface, .step(one, .place(frame)), .restoreInterface])
        #expect(!queue.needsRestore)
    }

    @Test func `a held animation keeps the setting off until released`() {
        var queue = AppQueue()
        queue.hold()
        _ = queue.submit(.move(frame), for: one)
        #expect(drain(&queue, switchedOff: true) == [.suspendInterface, .step(one, .move(frame))])
        _ = queue.submit(.settle(frame), for: one)
        #expect(drain(&queue, switchedOff: true) == [.step(one, .settle(frame))])
        #expect(queue.needsRestore)
        let woke = queue.release()
        #expect(woke)
        #expect(drain(&queue, switchedOff: true) == [.restoreInterface])
    }

    @Test func `an app with the setting off is never written to, and is read again next time`() {
        var queue = AppQueue()
        queue.hold()
        _ = queue.submit(.move(frame), for: one)
        #expect(drain(&queue, switchedOff: false) == [.suspendInterface, .step(one, .move(frame))])
        let woke = queue.release()
        #expect(!woke)
        _ = queue.submit(.move(frame), for: one)
        #expect(drain(&queue, switchedOff: false).first == .suspendInterface)
    }

    @Test func `a forgotten window loses its waiting steps`() {
        var queue = AppQueue()
        _ = queue.submit(.move(frame), for: one)
        queue.forget(one)
        #expect(drain(&queue, switchedOff: false) == [.forget(one)])
    }

    @Test func `a closed queue takes no more work but remembers a pending restore`() {
        var queue = AppQueue()
        queue.hold()
        _ = queue.submit(.move(frame), for: one)
        _ = drain(&queue, switchedOff: true)
        queue.close()
        let woke = queue.submit(.move(frame), for: one)
        let next = queue.next()
        let released = queue.release()
        #expect(!woke && next == nil && !released)
        #expect(queue.needsRestore)
    }
}
