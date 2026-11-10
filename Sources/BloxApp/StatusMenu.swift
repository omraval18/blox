import AppKit

/// Menu bar item with the few actions that matter. Created once, idle until clicked.
@MainActor
final class StatusMenu: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let onReload: @MainActor () -> Void
    private let onOpenConfig: @MainActor () -> Void

    init(onReload: @escaping @MainActor () -> Void, onOpenConfig: @escaping @MainActor () -> Void) {
        self.onReload = onReload
        self.onOpenConfig = onOpenConfig
        super.init()
        item.button?.title = "▦"
        let menu = NSMenu()
        menu.addItem(entry("Reload Config", #selector(reload)))
        menu.addItem(entry("Open Config", #selector(openConfig)))
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Blox", action: #selector(NSApplication.terminate), keyEquivalent: "q")
        item.menu = menu
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
