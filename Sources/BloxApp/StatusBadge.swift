import AppKit

/// The menu bar pill showing the current workspace. A template image, so the system tints it for
/// light, dark and inactive menu bars. Filled in the main mode; outlined while another mode
/// (e.g. `resize`) has rebound the keys.
@MainActor
enum StatusBadge {
    private static let height: CGFloat = 16
    private static let font = NSFont.monospacedDigitSystemFont(ofSize: 11.5, weight: .bold)

    static func image(_ name: String, filled: Bool) -> NSImage {
        let text = NSAttributedString(
            string: name,
            attributes: [.font: font, .foregroundColor: NSColor.black],
        )
        let textSize = text.size()
        let size = NSSize(width: max(height + 2, ceil(textSize.width) + 10), height: height)
        let image = NSImage(size: size, flipped: false) { rect in
            draw(text, size: textSize, in: rect, filled: filled)
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Workspace \(name)"
        return image
    }

    private static func draw(_ text: NSAttributedString, size: NSSize, in rect: NSRect, filled: Bool) {
        let pill = NSBezierPath(roundedRect: rect.insetBy(dx: 0.75, dy: 0.75), xRadius: 4.5, yRadius: 4.5)
        NSColor.black.set()
        if filled {
            pill.fill()
            // Knock the name out of the fill so the menu bar shows through it.
            NSGraphicsContext.current?.cgContext.setBlendMode(.destinationOut)
        } else {
            pill.lineWidth = 1.5
            pill.stroke()
        }
        text.draw(at: NSPoint(x: (rect.width - size.width) / 2, y: (rect.height - size.height) / 2))
    }
}
