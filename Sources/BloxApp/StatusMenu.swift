import AppKit
import BloxCore

/// The menu bar item: the current workspace's name, and a menu listing every workspace with the
/// apps in it (like AeroSpace's tray).
/// Rebuilt only when something it shows changes; idle otherwise.
@MainActor
final class StatusMenu: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let onReload: @MainActor () -> Void
    private let onOpenConfig: @MainActor () -> Void
    private let onSwitch: @MainActor (String) -> Void
    private var rows: [WorkspaceRow] = []
    private var mode = Config.mainMode
    private var error: String?

    init(
        onReload: @escaping @MainActor () -> Void,
        onOpenConfig: @escaping @MainActor () -> Void,
        onSwitch: @escaping @MainActor (String) -> Void,
    ) {
        self.onReload = onReload
        self.onOpenConfig = onOpenConfig
        self.onSwitch = onSwitch
        super.init()
        rebuild()
    }

    func update(rows newRows: [WorkspaceRow]) {
        guard newRows != rows else { return }
        rows = newRows
        rebuild()
    }

    /// Shows a config problem in the menu and flags the icon; `nil` clears it.
    func setError(_ message: String?) {
        guard message != error else { return }
        error = message
        rebuild()
    }

    /// The bar shows the active mode, so it is obvious when keys are rebound (e.g. `resize`).
    func setMode(_ name: String) {
        guard name != mode else { return }
        mode = name
        rebuild()
    }

    private func rebuild() {
        let current = rows.first { $0.info.isFocused }?.info.name ?? "▦"
        item.button?
            .title = current + (mode == Config.mainMode ? "" : " · \(mode)") + (error == nil ? "" : " !")
        item.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        if let error {
            let line = NSMenuItem(title: "Config error: \(error)", action: nil, keyEquivalent: "")
            line.isEnabled = false
            menu.addItem(line)
            menu.addItem(.separator())
        }
        for row in rows {
            menu.addItem(workspaceItem(row))
        }
        if !rows.isEmpty {
            menu.addItem(.separator())
        }
        menu.addItem(entry("Reload Config", #selector(reload)))
        menu.addItem(entry("Open Config", #selector(openConfig)))
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Blox", action: #selector(NSApplication.terminate), keyEquivalent: "q")
        return menu
    }

    private func workspaceItem(_ row: WorkspaceRow) -> NSMenuItem {
        let apps = row.apps.isEmpty ? "" : " — " + row.apps.joined(separator: ", ")
        let line = entry(row.info.name + apps, #selector(pick(_:)))
        line.representedObject = row.info.name
        line.state = row.info.isFocused ? .on : .off
        return line
    }

    private func entry(_ title: String, _ action: Selector) -> NSMenuItem {
        let entry = NSMenuItem(title: title, action: action, keyEquivalent: "")
        entry.target = self
        return entry
    }

    @objc private func pick(_ sender: NSMenuItem) {
        (sender.representedObject as? String).map(onSwitch)
    }

    @objc private func reload() {
        onReload()
    }

    @objc private func openConfig() {
        onOpenConfig()
    }
}
