import AppKit
import BloxCore
import QuartzCore

/// Glides windows to new frames. A display link runs only while something is moving, and progress
/// follows the clock, so a slow app drops frames instead of making the animation lag behind.
@MainActor
final class FrameAnimator: NSObject {
    /// More simultaneous movers than this snap: per-frame Accessibility calls would not keep up.
    private static let maxAnimated = 8

    private var tracks: [WindowID: AnimationTrack] = [:]
    /// The frame last applied to each window (mid-animation: the interpolated one).
    private var current: [WindowID: CGRect] = [:]
    private var link: CADisplayLink?
    /// Called whenever a window's frame is set, so overlays can follow it.
    var onFrame: (@MainActor (WindowID, CGRect) -> Void)?
    /// Called once a window has been given its final frame.
    var onSettled: (@MainActor (AXWindow, CGRect) -> Void)?

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
            window.setFrame(start)
            current[id] = start
            onFrame?(id, start)
        }
        guard let timing, let from = current[id], from != frame,
              tracks.count < Self.maxAnimated || tracks[id] != nil, startClock() else {
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

    func forget(_ id: WindowID) {
        tracks.removeValue(forKey: id)
        current.removeValue(forKey: id)
    }

    private func arrive(_ window: AXWindow, at frame: CGRect, _ finish: AnimationTrack.Finish) {
        let id = window.id
        switch finish {
        case .settle:
            window.setFrame(frame)
            current[id] = frame
            onFrame?(id, frame)
            onSettled?(window, frame)
        case .park:
            window.move(to: Displays.parkingPoint())
            current.removeValue(forKey: id)
        }
    }

    private func startClock() -> Bool {
        if link != nil {
            return true
        }
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return false }
        let created = screen.displayLink(target: self, selector: #selector(tick))
        created.add(to: .main, forMode: .common)
        link = created
        return true
    }

    /// Progress is measured at the moment the frame will be shown, not when this callback runs.
    @objc private func tick(_ link: CADisplayLink) {
        for (id, track) in tracks {
            advance(id, track, at: link.targetTimestamp)
        }
        if tracks.isEmpty {
            link.invalidate()
            self.link = nil
        }
    }

    private func advance(_ id: WindowID, _ track: AnimationTrack, at time: CFTimeInterval) {
        let progress = max(time - track.start, 0) / track.timing.duration
        guard progress < 1 else {
            tracks.removeValue(forKey: id)
            arrive(track.window, at: track.to, track.finish)
            return
        }
        let eased = track.timing.curve.value(at: progress)
        let frame = track.from.interpolated(to: track.to, progress: eased)
        // Frames are whole points, so the tail of an ease-out often repeats one: skip the app round trip.
        guard frame != current[id] else { return }
        track.window.setStep(frame, resizing: track.from.size != track.to.size)
        current[id] = frame
        onFrame?(id, frame)
    }
}
