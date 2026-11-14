import AppKit

/// A config problem, shown as a red callout at the top of the menu until the config parses again.
final class MenuErrorView: NSView {
    private static let padding: CGFloat = 10
    private let title = MenuStyle.label(
        "Config error · previous config still active",
        MenuStyle.caption,
        .systemRed,
    )
    private let message: NSTextField

    init(_ text: String) {
        message = MenuStyle.label(text, .monospacedSystemFont(ofSize: 11, weight: .regular), .labelColor)
        message.lineBreakMode = .byWordWrapping
        message.maximumNumberOfLines = 4
        let textWidth = MenuStyle.width - 2 * (MenuStyle.inset - 4 + Self.padding)
        let height = message.sizeThatFits(NSSize(width: textWidth, height: .greatestFiniteMagnitude)).height
        super.init(frame: NSRect(x: 0, y: 0, width: MenuStyle.width, height: ceil(height) + 44))
        [title, message].forEach(addSubview)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }

    override var isFlipped: Bool {
        true
    }

    override func layout() {
        super.layout()
        let box = callout
        let width = box.width - 2 * Self.padding
        title.frame = NSRect(x: box.minX + Self.padding, y: box.minY + 8, width: width, height: 14)
        message.frame = NSRect(
            x: box.minX + Self.padding,
            y: box.minY + 25,
            width: width,
            height: box.height - 33,
        )
    }

    override func draw(_: NSRect) {
        NSColor.systemRed.withAlphaComponent(0.1).setFill()
        NSBezierPath(roundedRect: callout, xRadius: 8, yRadius: 8).fill()
    }

    private var callout: NSRect {
        bounds.insetBy(dx: MenuStyle.inset - 4, dy: 4)
    }
}
