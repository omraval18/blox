import AppKit
import BloxCore

/// Menu bar item with the few actions that matter. Created once, idle until clicked.
@MainActor
final class StatusMenu: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let errorItem = NSMenuItem()
    private var mode = Config.mainMode
    private var hasError = false
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
        hasError = message != nil
        refreshTitle()
    }

    /// The icon shows the active mode, so it is obvious when keys are rebound (e.g. `resize`).
    func setMode(_ name: String) {
        mode = name
        refreshTitle()
    }

    private func refreshTitle() {
        item.button?.title = "▦" + (mode == Config.mainMode ? "" : " \(mode)") + (hasError ? "!" : "")
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
