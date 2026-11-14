import BloxCore
import CoreGraphics
import QuartzCore

/// The windows gliding right now, one track each.
struct Tracks {
    private var all: [WindowID: AnimationTrack] = [:]

    var count: Int {
        all.count
    }

    var isEmpty: Bool {
        all.isEmpty
    }

    subscript(id: WindowID) -> AnimationTrack? {
        all[id]
    }

    mutating func add(_ track: AnimationTrack) {
        all[track.window.id] = track
    }

    @discardableResult
    mutating func remove(_ id: WindowID) -> AnimationTrack? {
        all.removeValue(forKey: id)
    }

    /// Advances every track to `time`: the frame each moving window should take now, and the
    /// tracks that are over (removed here; they still need their final frame).
    mutating func advance(to time: CFTimeInterval)
        -> (moving: [(AnimationTrack, CGRect)], landed: [AnimationTrack]) {
        var moving: [(AnimationTrack, CGRect)] = []
        var landed: [AnimationTrack] = []
        for track in all.values {
            let (frame, done) = track.position(at: time)
            if done {
                landed.append(track)
            } else {
                moving.append((track, frame))
            }
        }
        landed.forEach { remove($0.window.id) }
        return (moving, landed)
    }
}
