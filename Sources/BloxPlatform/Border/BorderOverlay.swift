import AppKit
import BloxCore
import QuartzCore

/// A click-through ring hugging the focused window, stacked directly above that window so menus and
/// other windows still cover it. It only changes when focus or the window's frame changes.
@MainActor
final class BorderOverlay {
    private let panel: NSPanel
    private let gradient = CAGradientLayer()
    private let ring = CAShapeLayer()
    private var settings = BorderSettings()
    private var windowFrame = CGRect.zero

    init() {
        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true,
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        let view = NSView()
        view.wantsLayer = true
        ring.fillRule = .evenOdd
        gradient.mask = ring
        view.layer?.addSublayer(gradient)
        panel.contentView = view
    }

    func apply(_ new: BorderSettings) {
        settings = new
        gradient.colors = new.colors.map { CGColor(
            red: $0.red,
            green: $0.green,
            blue: $0.blue,
            alpha: $0.alpha,
        ) }
        if new.colors.count == 1 {
            gradient.colors = (gradient.colors ?? []) + (gradient.colors ?? [])
        }
        let radians = new.angle * .pi / 180
        gradient.startPoint = CGPoint(x: 0.5 - cos(radians) / 2, y: 0.5 - sin(radians) / 2)
        gradient.endPoint = CGPoint(x: 0.5 + cos(radians) / 2, y: 0.5 + sin(radians) / 2)
        if new.enabled, panel.isVisible {
            layout()
        } else if !new.enabled {
            hide()
        }
    }

    /// Shows the ring around `frame` (top-left coordinates), directly above window `windowNumber`.
    func show(around frame: CGRect, above windowNumber: UInt32) {
        guard settings.enabled else { return }
        windowFrame = frame
        layout()
        panel.order(.above, relativeTo: Int(windowNumber))
    }

    func move(to frame: CGRect) {
        guard panel.isVisible else { return }
        windowFrame = frame
        layout()
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func layout() {
        let outer = windowFrame.insetBy(dx: -settings.width, dy: -settings.width)
        panel.setFrame(Displays.appKitRect(outer), display: false)
        let bounds = CGRect(origin: .zero, size: outer.size)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradient.frame = bounds
        ring.frame = bounds
        ring.path = ringPath(in: bounds)
        CATransaction.commit()
    }

    private func ringPath(in bounds: CGRect) -> CGPath {
        let inner = bounds.insetBy(dx: settings.width, dy: settings.width)
        let path = CGMutablePath()
        path.addRoundedRect(
            in: bounds,
            cornerWidth: clamp(settings.radius + settings.width, bounds),
            cornerHeight: clamp(settings.radius + settings.width, bounds),
        )
        path.addRoundedRect(
            in: inner,
            cornerWidth: clamp(settings.radius, inner),
            cornerHeight: clamp(settings.radius, inner),
        )
        return path
    }

    private func clamp(_ radius: Double, _ rect: CGRect) -> Double {
        max(0, min(radius, min(rect.width, rect.height) / 2))
    }
}
