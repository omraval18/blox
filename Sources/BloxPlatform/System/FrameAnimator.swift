import BloxCore
import QuartzCore

/// Glides windows to new frames. A display link runs only while something is moving, and progress
/// follows the clock, so a slow app drops frames instead of making the animation lag behind.
@MainActor
final class FrameAnimator {
    /// More simultaneous movers than this snap: per-frame Accessibility calls would not keep up.
    private static let maxAnimated = 8

    private var tracks = Tracks()
    /// The frame last applied to each window (mid-animation: the interpolated one).
    private var current: [WindowID: CGRect] = [:]
    private let clock = DisplayClock()
    /// Performs the Accessibility calls and measures them (`blox stats`).
    let writer = FrameWriter()
    /// Called whenever a window's frame is set, so overlays can follow it.
    var onFrame: (@MainActor (WindowID, CGRect) -> Void)?
    /// Called once a window has been given its final frame.
    var onSettled: (@MainActor (AXWindow, CGRect) -> Void)?

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
        if let start {
            writer.place(window, start)
            shown(id, start)
        }
        guard let timing, let from = current[id], from != frame,
              tracks.count < Self.maxAnimated || tracks[id] != nil, clock.start() else {
            tracks.remove(id)
            arrive(window, at: frame, finish)
            return
        }
        // Windows sliding off to be parked keep their size anyway.
        let (glide, first) = finish.isSettle ? writer.begin(window, from: from, to: frame) : (.blend, nil)
        first.map { shown(id, $0) }
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

    func forget(_ id: WindowID) {
        tracks.remove(id)
        current.removeValue(forKey: id)
    }

    private func shown(_ id: WindowID, _ frame: CGRect) {
        current[id] = frame
        onFrame?(id, frame)
    }

    private func arrive(_ window: AXWindow, at frame: CGRect, _ finish: AnimationTrack.Finish) {
        switch finish {
        case .settle:
            writer.place(window, frame)
            shown(window.id, frame)
            CATransaction.flush()
            onSettled?(window, frame)
        case .park:
            writer.park(window)
            current.removeValue(forKey: window.id)
        }
    }

    /// Progress is measured at the moment the frame will be shown, not when this callback runs.
    /// Each window's overlay is updated and pushed to the screen right after that window moved,
    /// not after every app has answered: asking an app to move blocks until it does. A frame that
    /// repeats (frames are whole points, so the tail of an ease-out often does) is skipped.
    private func tick(_ link: CADisplayLink) {
        let began = CACurrentMediaTime()
        let (moving, landed) = tracks.advance(to: link.targetTimestamp)
        landed.forEach { arrive($0.window, at: $0.to, $0.finish) }
        for (track, frame) in moving where frame != current[track.window.id] {
            current[track.window.id] = frame
            writer.step(track.window, to: frame, resizing: track.resizesEachStep)
            onFrame?(track.window.id, frame)
            CATransaction.flush()
        }
        writer.frameDone(work: CACurrentMediaTime() - began, interval: link.targetTimestamp - link.timestamp)
        if tracks.isEmpty {
            clock.stop()
        }
    }
}
