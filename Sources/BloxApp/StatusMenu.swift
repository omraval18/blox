import AppKit

/// Menu bar item with the few actions that matter. Created once, idle until clicked.
@MainActor
final class StatusMenu: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let errorItem = NSMenuItem()
    private let onReload: @MainActor () -> Void
    private let onOpenConfig: @MainActor () -> Void

    init(onReload: @escaping @MainActor () -> Void, onOpenConfig: @escaping @MainActor () -> Void) {
        self.onReload = onReload
        self.onOpenConfig = onOpenConfig
        super.init()
        item.button?.title = "▦"
        let menu = NSMenu()
        errorItem.isHidden = true
        errorItem.isEnabled = false
        menu.addItem(errorItem)
        menu.addItem(entry("Reload Config", #selector(reload)))
        menu.addItem(entry("Open Config", #selector(openConfig)))
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Blox", action: #selector(NSApplication.terminate), keyEquivalent: "q")
        item.menu = menu
    }

    /// Shows a config problem in the menu and flags the icon; `nil` clears it.
    func setError(_ message: String?) {
        errorItem.title = message.map { "Config error: \($0)" } ?? ""
        errorItem.isHidden = message == nil
        item.button?.title = message == nil ? "▦" : "▦!"
    }

    private func entry(_ title: String, _ action: Selector) -> NSMenuItem {
        let entry = NSMenuItem(title: title, action: action, keyEquivalent: "")
        entry.target = self
        return entry
    }

    @objc private func reload() {
        onReload()
    }

    @objc private func openConfig() {
        onOpenConfig()
    }
}
