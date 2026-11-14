@testable import BloxCore
import CoreGraphics
import Testing

struct GlideTests {
    private let full = CGRect(x: 0, y: 0, width: 1000, height: 800)
    private let right = CGRect(x: 509, y: 0, width: 491, height: 800)
    private let left = CGRect(x: 0, y: 0, width: 491, height: 800)

    @Test func `unknown and quick apps resize every frame, slow ones once`() {
        #expect(ResizeMode(averageResizeStep: nil) == .everyFrame)
        #expect(ResizeMode(averageResizeStep: 0.004) == .everyFrame)
        #expect(ResizeMode(averageResizeStep: ResizeMode.slowResizeStep) == .once)
        #expect(ResizeMode(averageResizeStep: 0.022) == .once)
    }

    @Test func `a glide picks its shape from the mode and the change of size`() {
        #expect(Glide(from: full, to: right, mode: .everyFrame) == .blend)
        #expect(Glide(from: left, to: right, mode: .once) == .blend)
        #expect(Glide(from: full, to: right, mode: .once) == .shrinkFirst)
        #expect(Glide(from: right, to: full, mode: .once) == .growLast)
    }

    @Test func `only a blend of different sizes resizes each step`() {
        #expect(Glide.blend.resizesEachStep(from: full, to: right))
        #expect(!Glide.blend.resizesEachStep(from: left, to: right))
        #expect(!Glide.shrinkFirst.resizesEachStep(from: full, to: right))
        #expect(!Glide.growLast.resizesEachStep(from: right, to: full))
    }

    @Test func `a shrinking window takes its final size first, then only moves`() {
        let glide = Glide.shrinkFirst
        #expect(glide.startFrame(from: full, to: right) == CGRect(origin: full.origin, size: right.size))
        let frames = progressSteps.map { glide.frame(from: full, to: right, progress: $0) }
        #expect(frames.allSatisfy { $0.size == right.size })
        #expect(frames.last == right)
        #expect(frames.map(\.minX) == frames.map(\.minX).sorted())
    }

    @Test func `a growing window moves at its old size and grows on arrival`() {
        let glide = Glide.growLast
        #expect(glide.startFrame(from: right, to: full) == nil)
        let frames = progressSteps.map { glide.frame(from: right, to: full, progress: $0) }
        #expect(frames.allSatisfy { $0.size == right.size })
        #expect(frames.last?.origin == full.origin)
    }

    @Test(arguments: [Glide.blend, .shrinkFirst, .growLast])
    func `no step is larger than the start or end on either axis`(glide: Glide) {
        for (from, to) in [(full, right), (right, full), (left, right), (full, left)] {
            let width = max(from.width, to.width), height = max(from.height, to.height)
            let frames = progressSteps.map { glide.frame(from: from, to: to, progress: $0) }
            #expect(frames.allSatisfy { $0.width <= width && $0.height <= height })
        }
    }

    @Test func `a blend is the plain interpolation`() {
        #expect(Glide.blend.frame(from: full, to: right, progress: 0.5) == full.interpolated(
            to: right,
            progress: 0.5,
        ))
        #expect(Glide.blend.startFrame(from: full, to: right) == nil)
    }

    private var progressSteps: [Double] {
        (0 ... 20).map { Double($0) / 20 }
    }
}
