import AppKit

/// Shared metrics and type scale for the menu's custom views, so they line up with native items.
@MainActor
enum MenuStyle {
    static let width: CGFloat = 300
    /// Left edge of content, matching where native menu items start their icons.
    static let inset: CGFloat = 14

    static let display = NSFont.systemFont(ofSize: 28, weight: .bold)
    static let caption = NSFont.systemFont(ofSize: 11, weight: .medium)
    static let body = NSFont.systemFont(ofSize: 13, weight: .regular)
    static let emphasis = NSFont.systemFont(ofSize: 13, weight: .semibold)
    static let badge = NSFont.systemFont(ofSize: 12, weight: .semibold)
    static let figure = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)

    static func label(_ text: String, _ font: NSFont, _ color: NSColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = font
        label.textColor = color
        label.lineBreakMode = .byTruncatingTail
        return label
    }
}
