import BloxCore
import QuartzCore

/// Glides windows to new frames. A display link runs only while something is moving, and progress
/// follows the clock, so a slow app drops frames instead of making the animation lag behind.
@MainActor
final class FrameAnimator {
    /// More simultaneous movers than this snap: per-frame Accessibility calls would not keep up.
    private static let maxAnimated = 8

    private var tracks: [WindowID: AnimationTrack] = [:]
    /// The frame last applied to each window (mid-animation: the interpolated one).
    private var current: [WindowID: CGRect] = [:]
    private let clock = DisplayClock()
    private var writer = FrameWriter()
    /// Called whenever a window's frame is set, so overlays can follow it.
    var onFrame: (@MainActor (WindowID, CGRect) -> Void)?
    /// Called once a window has been given its final frame.
    var onSettled: (@MainActor (AXWindow, CGRect) -> Void)?

    init() {
        clock.onTick = { [weak self] link in self?.tick(link) }
    }

    /// Frame and per-app answer times, for `blox stats`.
    var stats: AnimationStats {
        writer.stats
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
        if let start {
            writer.place(window, start)
            current[id] = start
            onFrame?(id, start)
        }
        guard let timing, let from = current[id], from != frame,
              tracks.count < Self.maxAnimated || tracks[id] != nil, clock.start() else {
            tracks.removeValue(forKey: id)
            arrive(window, at: frame, finish)
            return
        }
        tracks[id] = AnimationTrack(
            window: window,
            from: from,
            to: frame,
            start: CACurrentMediaTime(),
            timing: timing,
            finish: finish,
        )
    }

    /// The frame last applied (mid-animation: the interpolated one).
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

    /// An app quit: drop what was measured about it.
    func forgetApp(_ pid: pid_t) {
        writer.forgetApp(pid)
    }

    func forget(_ id: WindowID) {
        tracks.removeValue(forKey: id)
        current.removeValue(forKey: id)
    }

    private func arrive(_ window: AXWindow, at frame: CGRect, _ finish: AnimationTrack.Finish) {
        let id = window.id
        switch finish {
        case .settle:
            writer.place(window, frame)
            current[id] = frame
            onFrame?(id, frame)
            CATransaction.flush()
            onSettled?(window, frame)
        case .park:
            writer.park(window)
            current.removeValue(forKey: id)
        }
    }

    /// Progress is measured at the moment the frame will be shown, not when this callback runs.
    /// Each window's overlay is updated and pushed to the screen right after that window moved,
    /// not after every app has answered: asking an app to move blocks until it does.
    private func tick(_ link: CADisplayLink) {
        let began = CACurrentMediaTime()
        let steps = tracks.compactMap { id, track in step(id, track, at: link.targetTimestamp) }
        for (track, frame) in steps {
            writer.step(track.window, to: frame, resizing: track.from.size != track.to.size)
            onFrame?(track.window.id, frame)
            CATransaction.flush()
        }
        writer.frameDone(work: CACurrentMediaTime() - began, interval: link.targetTimestamp - link.timestamp)
        if tracks.isEmpty {
            clock.stop()
        }
    }

    /// The frame `track` should show at `time`, or nil when it has nothing new to show (it landed, or
    /// the frame repeats: frames are whole points, so the tail of an ease-out often does).
    private func step(_ id: WindowID, _ track: AnimationTrack, at time: CFTimeInterval)
        -> (track: AnimationTrack, frame: CGRect)? {
        let (frame, done) = track.position(at: time)
        guard !done else {
            tracks.removeValue(forKey: id)
            arrive(track.window, at: track.to, track.finish)
            return nil
        }
        guard frame != current[id] else { return nil }
        current[id] = frame
        return (track, frame)
    }
}
