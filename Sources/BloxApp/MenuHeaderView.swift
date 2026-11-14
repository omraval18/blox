import AppKit

/// Top of the menu: the focused workspace's name set large, with its window and app counts, and
/// the active mode when it is not the main one.
final class MenuHeaderView: NSView {
    private let caption: NSTextField
    private let name: NSTextField
    private let windows: NSTextField
    private let detail: NSTextField

    init(row: WorkspaceRow?, mode: String?) {
        let count = row?.info.windows.count ?? 0
        let apps = row?.apps.count ?? 0
        caption = MenuStyle.label("Workspace", MenuStyle.caption, .secondaryLabelColor)
        name = MenuStyle.label(row?.info.name ?? "–", MenuStyle.display, .labelColor)
        windows = MenuStyle.label(Self.plural(count, "window"), MenuStyle.emphasis, .labelColor)
        detail = MenuStyle.label(
            mode.map { "\($0) mode" } ?? Self.plural(apps, "app"),
            MenuStyle.caption,
            mode == nil ? .secondaryLabelColor : .controlAccentColor,
        )
        [windows, detail].forEach { $0.alignment = .right }
        super.init(frame: NSRect(x: 0, y: 0, width: MenuStyle.width, height: 62))
        [caption, name, windows, detail].forEach(addSubview)
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
        let right = bounds.width - MenuStyle.inset
        caption.frame = NSRect(x: MenuStyle.inset, y: 8, width: 120, height: 14)
        name.frame = NSRect(x: MenuStyle.inset - 1, y: 22, width: 160, height: 34)
        windows.frame = NSRect(x: right - 120, y: 24, width: 120, height: 17)
        detail.frame = NSRect(x: right - 120, y: 41, width: 120, height: 14)
    }

    private static func plural(_ count: Int, _ noun: String) -> String {
        "\(count) \(noun)\(count == 1 ? "" : "s")"
    }
}
