import AppKit

/// Factories for the menu's items. Workspace rows and the footer commands target the menu.
extension StatusMenu {
    func viewItem(_ view: NSView) -> NSMenuItem {
        let entry = NSMenuItem()
        entry.view = view
        return entry
    }

    /// Typing a workspace's name while the menu is open switches to it.
    func workspaceItem(_ row: WorkspaceRow) -> NSMenuItem {
        let key = row.info.name.count == 1 ? row.info.name.lowercased() : ""
        let entry = NSMenuItem(title: row.info.name, action: #selector(pick(_:)), keyEquivalent: key)
        entry.keyEquivalentModifierMask = []
        entry.target = self
        entry.representedObject = row.info.name
        entry.view = WorkspaceRowView(row)
        return entry
    }

    func command(
        _ title: String,
        _ symbol: String,
        _ key: String,
        _ action: Selector,
        target: AnyObject? = nil,
    ) -> NSMenuItem {
        let entry = NSMenuItem(title: title, action: action, keyEquivalent: key)
        entry.target = target ?? self
        entry.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        return entry
    }
}
