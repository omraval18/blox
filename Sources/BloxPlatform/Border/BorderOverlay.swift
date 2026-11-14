import BloxCore
import CoreGraphics

/// Keeps one `Ring` per visible window: the focused window gets the active look, the others the
/// inactive look (or none, when no inactive colors are configured).
@MainActor
final class BorderOverlay {
    private var settings = BorderSettings()
    private var rings: [WindowID: Ring] = [:]
    var active: WindowID?

    func apply(_ new: BorderSettings) {
        settings = new
        guard new.enabled else { return removeAll() }
        for (id, ring) in rings {
            restyle(ring, id)
        }
    }

    /// Creates, restyles or moves the ring for `id`. A ring that just became active or was just
    /// created is also raised to sit right above its window.
    func update(_ id: WindowID, frame: CGRect) {
        guard settings.enabled, !colors(for: id).isEmpty else { return remove(id) }
        guard let ring = rings[id] else {
            let ring = Ring()
            rings[id] = ring
            restyle(ring, id)
            ring.show(around: frame, above: id.rawValue)
            return
        }
        if ring.isActive != (id == active) {
            restyle(ring, id)
            ring.show(around: frame, above: id.rawValue)
        } else {
            ring.move(to: frame)
        }
    }

    /// Its window stopped moving: shrink the ring's panel back to the window.
    func settle(_ id: WindowID) {
        rings[id]?.settle()
    }

    func raise(_ id: WindowID) {
        rings[id]?.raise(above: id.rawValue)
    }

    func remove(_ id: WindowID) {
        rings.removeValue(forKey: id)?.close()
    }

    func removeAll() {
        rings.values.forEach { $0.close() }
        rings.removeAll()
    }

    var tracked: [WindowID] {
        Array(rings.keys)
    }

    private func restyle(_ ring: Ring, _ id: WindowID) {
        ring.configure(settings, active: id == active)
    }

    private func colors(for id: WindowID) -> [RGBA] {
        id == active ? settings.colors : settings.inactiveColors
    }
}
