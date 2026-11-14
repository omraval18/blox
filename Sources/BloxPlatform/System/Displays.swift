import AppKit
import BloxCore

enum Displays {
    /// Usable area of each screen, converted from AppKit's bottom-left origin to the top-left
    /// global space that Accessibility and BloxCore use.
    static func monitors() -> [Monitor] {
        guard let primaryHeight = NSScreen.screens.first?.frame.height else { return [] }
        return NSScreen.screens.compactMap { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32
            else {
                return nil
            }
            let visible = screen.visibleFrame
            let frame = CGRect(
                x: visible.minX,
                y: primaryHeight - visible.maxY,
                width: visible.width,
                height: visible.height,
            )
            return Monitor(id: number, frame: frame)
        }
    }

    /// Converts a top-left-origin rect (Accessibility space) to AppKit's bottom-left space.
    static func appKitRect(_ rect: CGRect) -> CGRect {
        let height = NSScreen.screens.first?.frame.height ?? 0
        return CGRect(x: rect.minX, y: height - rect.maxY, width: rect.width, height: rect.height)
    }

    /// The screen holding the centre of `rect`, in top-left space: what a sliding window leaves.
    static func screen(containing rect: CGRect) -> CGRect {
        let center = appKitRect(rect)
        let point = CGPoint(x: center.midX, y: center.midY)
        let screen = NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.screens.first
        return screen.map { appKitRect($0.frame) } ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
    }

    /// Whether more than a sliver of `rect` (top-left space) is on some screen. macOS keeps part of
    /// every window on screen, so "hidden" means only a sliver remains visible.
    static func isShowing(_ rect: CGRect) -> Bool {
        NSScreen.screens.contains { screen in
            let visible = appKitRect(screen.frame).intersection(rect)
            return visible.width > sliver && visible.height > sliver
        }
    }

    /// More visible than this, a window counts as showing. macOS clamps windows that leave the
    /// screen so that 40 pt stay visible.
    static let sliver = 48.0

    /// Bottom-right corner of all screens combined: where hidden windows are parked.
    static func parkingPoint() -> CGPoint {
        let height = NSScreen.screens.first?.frame.height ?? 0
        let right = NSScreen.screens.map(\.frame.maxX).max() ?? 0
        let bottom = NSScreen.screens.map { height - $0.frame.minY }.max() ?? 0
        return CGPoint(x: right - 1, y: bottom - 1)
    }
}
