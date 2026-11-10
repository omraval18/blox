import AppKit
import BloxCore

/// Draws the workspace letters for the menu bar: one pill per workspace that has windows.
/// The focused workspace is a filled pill, one visible on another monitor is outlined, the rest
/// are dimmed. A template image, so macOS recolors it for light and dark menu bars.
enum WorkspaceStrip {
    private static let height = 16.0
    private static let spacing = 3.0
    private static let padding = 6.0

    static func image(for infos: [WorkspaceInfo]) -> NSImage? {
        guard !infos.isEmpty else { return nil }
        let labels = infos.map { NSAttributedString(
            string: $0.name,
            attributes: [.font: NSFont.systemFont(ofSize: 11, weight: .semibold)],
        ) }
        let widths = labels.map { max(height, $0.size().width + padding * 2) }
        let total = widths.reduce(0, +) + spacing * Double(infos.count - 1)
        let image = NSImage(size: NSSize(width: total, height: height), flipped: false) { _ in
            var x = 0.0
            for (info, (label, width)) in zip(infos, zip(labels, widths)) {
                draw(info, label, in: NSRect(x: x, y: 0, width: width, height: height))
                x += width + spacing
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func draw(_ info: WorkspaceInfo, _ label: NSAttributedString, in rect: NSRect) {
        let pill = NSBezierPath(
            roundedRect: rect.insetBy(dx: 0.5, dy: 0.5),
            xRadius: height / 2,
            yRadius: height / 2,
        )
        let size = label.size()
        let text = NSRect(
            x: rect.midX - size.width / 2,
            y: rect.midY - size.height / 2,
            width: size.width,
            height: size.height,
        )
        NSColor.black.set()
        if info.isFocused {
            pill.fill()
            NSGraphicsContext.current?.compositingOperation = .clear
            label.draw(in: text)
            NSGraphicsContext.current?.compositingOperation = .sourceOver
        } else {
            if info.isVisible {
                pill.stroke()
            }
            dimmed(label).draw(in: text)
        }
    }

    private static func dimmed(_ label: NSAttributedString) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: label)
        let color = NSColor.black.withAlphaComponent(0.6)
        result.addAttribute(
            .foregroundColor,
            value: color,
            range: NSRange(location: 0, length: result.length),
        )
        return result
    }
}
