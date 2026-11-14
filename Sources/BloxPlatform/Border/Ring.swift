import AppKit
import BloxCore
import QuartzCore

/// One click-through ring along the inside edge of one window, stacked directly above that window so
/// menus and other windows still cover it. It changes only when its window moves or its style does.
///
/// Resizing a window every frame makes the window server reallocate its surface each time, which
/// cannot keep up with an animation. So while its window glides, the panel grows once to cover the
/// screen and only the layers move inside it (pure compositing); once the window settles, the panel
/// shrinks back to hug it.
@MainActor
final class Ring {
    private let panel: RingPanel
    private let gradient = CAGradientLayer()
    /// The ring's shape: a layer border, drawn by the GPU without rasterizing a path.
    private let outline = CALayer()
    private var style = BorderSettings()
    private var windowFrame = CGRect.zero
    /// The panel's frame in top-left space; covers `windowFrame`.
    private var panelFrame = CGRect.zero
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
        // Panels fade in and out by default; a fading ring lingers where its window just left.
        panel.animationBehavior = .none
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        let view = NSView()
        view.wantsLayer = true
        outline.borderColor = CGColor(gray: 0, alpha: 1)
        gradient.mask = outline
        view.layer?.addSublayer(gradient)
        panel.contentView = view
    }

    /// Applies colors and shape for the active or inactive look.
    func configure(_ settings: BorderSettings, active: Bool) {
        style = settings
        isActive = active
        let colors = active ? settings.colors : settings.inactiveColors
        let cgColors = colors.map { CGColor(red: $0.red, green: $0.green, blue: $0.blue, alpha: $0.alpha) }
        let radians = settings.angle * .pi / 180
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradient.colors = cgColors.count == 1 ? cgColors + cgColors : cgColors
        gradient.startPoint = CGPoint(x: 0.5 - cos(radians) / 2, y: 0.5 - sin(radians) / 2)
        gradient.endPoint = CGPoint(x: 0.5 + cos(radians) / 2, y: 0.5 + sin(radians) / 2)
        outline.borderWidth = settings.width
        CATransaction.commit()
        placeLayers()
    }

    /// Shows the ring around `frame` (top-left coordinates), directly above window `windowNumber`.
    func show(around frame: CGRect, above windowNumber: UInt32) {
        windowFrame = frame
        settle()
        panel.order(.above, relativeTo: Int(windowNumber))
    }

    /// Puts the ring back above its window after the app reordered its windows.
    func raise(above windowNumber: UInt32) {
        panel.order(.above, relativeTo: Int(windowNumber))
    }

    /// One step of a moving window: the panel grows to the screen at most once, layers do the rest.
    func move(to frame: CGRect) {
        guard frame != windowFrame || !panelFrame.contains(frame) else { return }
        windowFrame = frame
        if !panelFrame.contains(frame) {
            resizePanel(to: Displays.screen(containing: frame).union(frame).union(panelFrame))
        }
        placeLayers()
    }

    /// The window stopped moving: the panel hugs it again, so an idle ring costs only its own size.
    func settle() {
        guard panelFrame != windowFrame else { return }
        resizePanel(to: windowFrame)
        placeLayers()
    }

    func close() {
        panel.orderOut(nil)
    }

    private func resizePanel(to frame: CGRect) {
        let resized = frame.size != panelFrame.size
        panelFrame = frame
        if resized {
            panel.setFrame(Displays.appKitRect(frame), display: false)
        } else {
            panel.setFrameOrigin(Displays.appKitRect(frame).origin)
        }
    }

    /// The ring is drawn inside the window's edge, as Hyprland does, so it never depends on gaps and
    /// stays visible on windows that touch the screen edge.
    private func placeLayers() {
        // Layers have a bottom-left origin inside the panel.
        let local = CGRect(
            x: windowFrame.minX - panelFrame.minX,
            y: panelFrame.maxY - windowFrame.maxY,
            width: windowFrame.width,
            height: windowFrame.height,
        )
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradient.frame = local
        outline.frame = CGRect(origin: .zero, size: local.size)
        outline.cornerRadius = max(0, min(style.radius, min(local.width, local.height) / 2))
        CATransaction.commit()
    }
}
