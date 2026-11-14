import AppKit

/// One workspace in the menu: a name badge, its apps' icons and names, and a window count.
/// The badge is solid accent on the focused workspace and tinted when shown on another display.
final class WorkspaceRowView: NSView {
    private static let maxIcons = 3
    private let row: WorkspaceRow
    private let names: NSTextField
    private let count: NSTextField
    private let icons: [NSImageView]

    var isHighlighted = false {
        didSet {
            guard isHighlighted != oldValue else { return }
            applyColors()
            needsDisplay = true
        }
    }

    init(_ row: WorkspaceRow) {
        self.row = row
        let appNames = row.appNames
        names = MenuStyle.label(
            appNames.isEmpty ? "Empty" : appNames.joined(separator: ", "),
            MenuStyle.body,
            .labelColor,
        )
        count = MenuStyle.label(
            row.info.windows.isEmpty ? "" : "\(row.info.windows.count)",
            MenuStyle.figure,
            .tertiaryLabelColor,
        )
        count.alignment = .right
        icons = row.apps.prefix(Self.maxIcons).map { pid in
            NSImageView(image: NSRunningApplication(processIdentifier: pid)?.icon ?? NSImage())
        }
        super.init(frame: NSRect(x: 0, y: 0, width: MenuStyle.width, height: 34))
        ([names, count] + icons).forEach(addSubview)
        setAccessibilityLabel("Workspace \(row.info.name), \(names.stringValue)")
        applyColors()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }

    override func layout() {
        super.layout()
        let mid = bounds.midY
        for (index, icon) in icons.enumerated() {
            icon.frame = NSRect(x: 48 + CGFloat(index) * 19, y: mid - 8, width: 16, height: 16)
        }
        let textX = 48 + CGFloat(icons.count) * 19 + (icons.isEmpty ? 0 : 3)
        count.frame = NSRect(x: bounds.maxX - MenuStyle.inset - 28, y: mid - 8, width: 28, height: 16)
        names.frame = NSRect(x: textX, y: mid - 8.5, width: count.frame.minX - textX - 8, height: 17)
    }

    override func draw(_: NSRect) {
        if isHighlighted {
            NSColor.selectedContentBackgroundColor.setFill()
            NSBezierPath(roundedRect: bounds.insetBy(dx: 5, dy: 0), xRadius: 6, yRadius: 6).fill()
        }
        let badge = NSRect(x: MenuStyle.inset, y: bounds.midY - 11, width: 24, height: 22)
        badgeFill.setFill()
        NSBezierPath(roundedRect: badge, xRadius: 6, yRadius: 6).fill()
        let name = NSAttributedString(
            string: row.info.name,
            attributes: [.font: MenuStyle.badge, .foregroundColor: badgeText],
        )
        let size = name.size()
        name.draw(at: NSPoint(x: badge.midX - size.width / 2, y: badge.midY - size.height / 2))
    }

    private var badgeFill: NSColor {
        if row.info.isFocused {
            return isHighlighted ? .white : .controlAccentColor
        }
        if isHighlighted {
            return .white.withAlphaComponent(0.2)
        }
        return row.info.isVisible ? .controlAccentColor.withAlphaComponent(0.18) : .quaternaryLabelColor
    }

    private var badgeText: NSColor {
        if row.info.isFocused {
            return isHighlighted ? .selectedContentBackgroundColor : .white
        }
        if isHighlighted {
            return .selectedMenuItemTextColor
        }
        return row.info.isVisible ? .controlAccentColor : .secondaryLabelColor
    }

    private func applyColors() {
        let resting: NSColor = row.apps.isEmpty ? .tertiaryLabelColor : .labelColor
        names.textColor = isHighlighted ? .selectedMenuItemTextColor : resting
        names.font = row.info.isFocused ? MenuStyle.emphasis : MenuStyle.body
        count.textColor = isHighlighted ? .selectedMenuItemTextColor : .tertiaryLabelColor
    }

    override func mouseUp(with _: NSEvent) {
        guard let item = enclosingMenuItem, let menu = unsafe item.menu else { return }
        menu.cancelTracking()
        menu.performActionForItem(at: menu.index(of: item))
    }
}
