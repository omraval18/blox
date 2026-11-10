import AppKit
import BloxCore
import QuartzCore

/// Glides windows to new frames. A display link runs only while something is moving, and progress
/// follows the clock, so a slow app drops frames instead of making the animation lag behind.
@MainActor
final class FrameAnimator: NSObject {
    private struct Track {
        let window: AXWindow
        let from: CGRect
        let to: CGRect
        let start: CFTimeInterval
        let settings: AnimationSettings
    }

    /// More simultaneous movers than this snap: per-frame Accessibility calls would not keep up.
    private static let maxAnimated = 6

    private var tracks: [WindowID: Track] = [:]
    private var current: [WindowID: CGRect] = [:]
    private var link: CADisplayLink?

    func move(_ window: AXWindow, to frame: CGRect, using settings: AnimationSettings) {
        let id = window.id
        guard settings.enabled, let from = current[id], from != frame,
              tracks.count < Self.maxAnimated || tracks[id] != nil, startClock() else {
            tracks.removeValue(forKey: id)
            window.setFrame(frame)
            current[id] = frame
            return
        }
        tracks[id] = Track(
            window: window,
            from: from,
            to: frame,
            start: CACurrentMediaTime(),
            settings: settings,
        )
    }

    func record(_ id: WindowID, _ frame: CGRect) {
        current[id] = frame
    }

    func forget(_ id: WindowID) {
        tracks.removeValue(forKey: id)
        current.removeValue(forKey: id)
    }

    private func startClock() -> Bool {
        if link != nil {
            return true
        }
        guard let created = NSScreen.main?.displayLink(target: self, selector: #selector(tick))
        else { return false }
        created.add(to: .main, forMode: .common)
        link = created
        return true
    }

    @objc private func tick() {
        let now = CACurrentMediaTime()
        for (id, track) in tracks {
            let progress = (now - track.start) / track.settings.duration
            guard progress < 1 else {
                track.window.setFrame(track.to)
                current[id] = track.to
                tracks.removeValue(forKey: id)
                continue
            }
            let eased = track.settings.curve.value(at: progress)
            let frame = track.from.interpolated(to: track.to, progress: eased)
            track.window.setStep(frame, resizing: track.from.size != track.to.size)
            current[id] = frame
        }
        if tracks.isEmpty {
            link?.invalidate()
            link = nil
        }
    }
}
