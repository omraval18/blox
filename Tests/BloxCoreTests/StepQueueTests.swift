@testable import BloxCore
import CoreGraphics
import Testing

struct StepQueueTests {
    private let small = CGRect(x: 0, y: 0, width: 400, height: 300)
    private let big = CGRect(x: 10, y: 20, width: 800, height: 600)
    private let moved = CGRect(x: 50, y: 60, width: 800, height: 600)

    private func queue(_ steps: [FrameStep]) -> StepQueue {
        var queue = StepQueue()
        steps.forEach { queue.push($0) }
        return queue
    }

    @Test func `a newer animation step replaces a waiting one`() {
        #expect(queue([.move(small), .move(big)]).steps == [.move(big)])
        #expect(queue([.resize(small), .resize(big)]).steps == [.resize(big)])
    }

    @Test func `a move after a waiting resize keeps the resize's size`() {
        let merged = queue([.resize(small), .move(moved)]).steps
        #expect(merged == [.resize(CGRect(origin: moved.origin, size: small.size))])
    }

    @Test func `animation steps merge into a waiting whole frame`() {
        #expect(queue([.place(small), .resize(big)]).steps == [.place(big)])
        let kept = CGRect(origin: moved.origin, size: small.size)
        #expect(queue([.place(small), .move(moved)]).steps == [.place(kept)])
    }

    @Test func `a final step replaces everything waiting`() {
        #expect(queue([.place(small), .move(big), .settle(moved)]).steps == [.settle(moved)])
        #expect(queue([.settle(small), .park(.zero)]).steps == [.park(.zero)])
    }

    @Test func `a final step is never overtaken`() {
        var steps = queue([.settle(small), .move(big), .move(moved)])
        #expect(steps.steps == [.settle(small), .move(moved)])
        #expect(steps.pop() == .settle(small))
        #expect(steps.pop() == .move(moved))
        #expect(steps.pop() == nil)
        #expect(steps.isEmpty)
    }

    @Test func `a whole frame replaces waiting animation steps but not a final one`() {
        #expect(queue([.move(small), .place(big)]).steps == [.place(big)])
        #expect(queue([.settle(small), .move(moved), .place(big)]).steps == [.settle(small), .place(big)])
    }

    @Test func `a backlog never grows past two`() {
        let steps: [FrameStep] = [.settle(small), .move(big), .place(small), .resize(big), .move(moved)]
        #expect(queue(steps + steps + steps).steps.count <= 2)
    }
}
