import AppKit
import BloxCore
import QuartzCore

/// One click-through ring along the inside edge of one window, stacked directly above that window so menus
/// and
/// other windows still cover it. It changes only when its window moves or its style does.
@MainActor
final class Ring {
    private let panel: RingPanel
    private let gradient = CAGradientLayer()
    private let shape = CAShapeLayer()
    private var style = BorderSettings()
    private var windowFrame = CGRect.zero
    private(set) var isActive = false

    init() {
        panel = RingPanel(
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
        shape.fillRule = .evenOdd
        gradient.mask = shape
        view.layer?.addSublayer(gradient)
        panel.contentView = view
    }

    /// Applies colors for the active or inactive look.
    func configure(_ settings: BorderSettings, active: Bool) {
        style = settings
        isActive = active
        let colors = active ? settings.colors : settings.inactiveColors
        let cgColors = colors.map { CGColor(red: $0.red, green: $0.green, blue: $0.blue, alpha: $0.alpha) }
        gradient.colors = cgColors.count == 1 ? cgColors + cgColors : cgColors
        let radians = settings.angle * .pi / 180
        gradient.startPoint = CGPoint(x: 0.5 - cos(radians) / 2, y: 0.5 - sin(radians) / 2)
        gradient.endPoint = CGPoint(x: 0.5 + cos(radians) / 2, y: 0.5 + sin(radians) / 2)
        if panel.isVisible {
            layout()
        }
    }

    /// Shows the ring around `frame` (top-left coordinates), directly above window `windowNumber`.
    func show(around frame: CGRect, above windowNumber: UInt32) {
        windowFrame = frame
        layout()
        panel.order(.above, relativeTo: Int(windowNumber))
    }

    /// Puts the ring back above its window after the app reordered its windows.
    func raise(above windowNumber: UInt32) {
        panel.order(.above, relativeTo: Int(windowNumber))
    }

    func move(to frame: CGRect) {
        windowFrame = frame
        layout()
    }

    func close() {
        panel.orderOut(nil)
    }

    /// The ring is drawn inside the window's edge, as Hyprland does, so it never depends on gaps and
    /// stays visible on windows that touch the screen edge.
    private func layout() {
        panel.setFrame(Displays.appKitRect(windowFrame), display: false)
        let bounds = CGRect(origin: .zero, size: windowFrame.size)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradient.frame = bounds
        shape.frame = bounds
        shape.path = ringPath(in: bounds)
        CATransaction.commit()
    }

    private func ringPath(in bounds: CGRect) -> CGPath {
        let inner = bounds.insetBy(dx: style.width, dy: style.width)
        let path = CGMutablePath()
        let outerRadius = clamp(style.radius, bounds)
        let innerRadius = clamp(style.radius - style.width, inner)
        path.addRoundedRect(in: bounds, cornerWidth: outerRadius, cornerHeight: outerRadius)
        path.addRoundedRect(in: inner, cornerWidth: innerRadius, cornerHeight: innerRadius)
        return path
    }

    private func clamp(_ radius: Double, _ rect: CGRect) -> Double {
        max(0, min(radius, min(rect.width, rect.height) / 2))
    }
}
