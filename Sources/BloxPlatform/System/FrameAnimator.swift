import BloxCore
import QuartzCore

/// Glides windows to new frames. A display link runs only while something is moving, and progress
/// follows the clock, so a slow app drops frames instead of making the animation lag behind.
@MainActor
final class FrameAnimator {
    /// More simultaneous movers than this snap: per-frame Accessibility calls would not keep up.
    private static let maxAnimated = 8

    private var tracks = Tracks()
    /// The frame last asked of each window (mid-animation: the interpolated one).
    private var current: [WindowID: CGRect] = [:]
    private let clock = DisplayClock()
    /// Hands frames to each app's channel and keeps what they measure (`blox stats`).
    let writer = FrameWriter()

    init() {
        clock.onTick = { [weak self] link in self?.tick(link) }
    }

    /// Moves `window` to `frame`, gliding with `timing` or snapping when it is nil. With `start`, the
    /// window is first put there (a window arriving from offscreen or from a smaller size).
    func move(
        _ window: AXWindow,
        to frame: CGRect,
        timing: Timing?,
        from start: CGRect? = nil,
        finish: AnimationTrack.Finish = .settle,
    ) {
        let id = window.id
        // One hold across the whole move, so the app's setting is read at most once for it.
        writer.hold(window.pid)
        defer { writer.release(window.pid) }
        start.map { put(window, at: $0) }
        guard let timing, let from = current[id], from != frame,
              tracks.count < Self.maxAnimated || tracks[id] != nil, clock.start() else {
            tracks.remove(id).map { writer.release($0.window.pid) }
            arrive(window, at: frame, finish)
            return
        }
        if tracks[id] == nil {
            writer.hold(window.pid)
        }
        // Windows sliding off to be parked keep their size anyway.
        let (glide, first) = finish.isSettle ? writer.begin(window, from: from, to: frame) : (.blend, nil)
        first.map { current[id] = $0 }
        tracks.add(AnimationTrack(
            window: window,
            from: from,
            to: frame,
            start: CACurrentMediaTime(),
            timing: timing,
            finish: finish,
            glide: glide,
        ))
    }

    /// The frame last asked for (mid-animation: the interpolated one).
    func frame(of id: WindowID) -> CGRect? {
        current[id]
    }

    /// Where the window is heading (or sits), without asking the app.
    func target(of id: WindowID) -> CGRect? {
        tracks[id]?.to ?? current[id]
    }

    /// Where a window that is moving right now will end up; nil when it is not moving.
    func destination(of id: WindowID) -> CGRect? {
        tracks[id]?.to
    }

    func record(_ id: WindowID, _ frame: CGRect) {
        current[id] = frame
    }

    func forget(_ id: WindowID) {
        tracks.remove(id).map { writer.release($0.window.pid) }
        current.removeValue(forKey: id)
    }

    private func put(_ window: AXWindow, at frame: CGRect) {
        writer.place(window, frame)
        current[window.id] = frame
    }

    private func arrive(_ window: AXWindow, at frame: CGRect, _ finish: AnimationTrack.Finish) {
        switch finish {
        case .settle:
            writer.settle(window, frame)
            current[window.id] = frame
        case .park:
            writer.park(window)
            current.removeValue(forKey: window.id)
        }
    }

    /// Progress is measured at the moment the frame will be shown, not when this callback runs.
    /// Steps are only submitted here; each app's channel applies them at its own pace. A frame that
    /// repeats (frames are whole points, so the tail of an ease-out often does) is skipped.
    private func tick(_ link: CADisplayLink) {
        let began = CACurrentMediaTime()
        let (moving, landed) = tracks.advance(to: link.targetTimestamp)
        for track in landed {
            arrive(track.window, at: track.to, track.finish)
            writer.release(track.window.pid)
        }
        for (track, frame) in moving where frame != current[track.window.id] {
            current[track.window.id] = frame
            writer.step(track.window, to: frame, resizing: track.resizesEachStep)
        }
        writer.frameDone(work: CACurrentMediaTime() - began, interval: link.targetTimestamp - link.timestamp)
        if tracks.isEmpty {
            clock.stop()
        }
    }
}
