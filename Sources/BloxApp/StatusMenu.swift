import AppKit
import BloxCore

/// The menu bar item: a pill with the current workspace, and a menu of the workspaces in use
/// with their apps. Its items are built only when it opens; while closed, a state change costs at
/// most a redraw of the pill.
@MainActor
final class StatusMenu: NSObject, NSMenuDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let actions: StatusMenuActions
    private var rows: [WorkspaceRow] = []
    private var mode = Config.mainMode
    private var error: String?
    private var isOpen = false

    init(actions: StatusMenuActions) {
        self.actions = actions
        super.init()
        menu.delegate = self
        menu.autoenablesItems = false
        item.menu = menu
        item.button?.imagePosition = .imageLeading
        refresh()
    }

    func update(rows newRows: [WorkspaceRow]) {
        guard newRows != rows else { return }
        rows = newRows
        refresh()
    }

    /// Shows a config problem in the menu and flags the item; `nil` clears it.
    func setError(_ message: String?) {
        guard message != error else { return }
        error = message
        refresh()
    }

    /// The bar shows the active mode, so it is obvious when keys are rebound (e.g. `resize`).
    func setMode(_ name: String) {
        guard name != mode else { return }
        mode = name
        refresh()
    }

    func menuNeedsUpdate(_: NSMenu) {
        populate()
    }

    func menuWillOpen(_: NSMenu) {
        isOpen = true
    }

    func menuDidClose(_: NSMenu) {
        isOpen = false
    }

    /// Custom row views draw their own highlight; native items are handled by the menu.
    func menu(_ menu: NSMenu, willHighlight target: NSMenuItem?) {
        for entry in menu.items {
            (entry.view as? WorkspaceRowView)?.isHighlighted = entry === target
        }
    }

    private var focusedRow: WorkspaceRow? {
        rows.first { $0.info.isFocused }
    }

    private var customMode: String? {
        mode == Config.mainMode ? nil : mode
    }

    private func refresh() {
        guard let button = item.button else { return }
        let name = focusedRow?.info.name ?? "–"
        button.image = StatusBadge.image(name, filled: customMode == nil)
        button.title = [customMode, error.map { _ in "!" }].compactMap(\.self).map { " " + $0 }.joined()
        button.setAccessibilityLabel("Blox, workspace \(name)")
        if isOpen {
            populate()
        }
    }

    private func populate() {
        menu.removeAllItems()
        if let error {
            menu.addItem(viewItem(MenuErrorView(error)))
        }
        menu.addItem(viewItem(MenuHeaderView(row: focusedRow, mode: customMode)))
        menu.addItem(.separator())
        menu.addItem(.sectionHeader(title: "Workspaces"))
        rows.forEach { menu.addItem(workspaceItem($0)) }
        menu.addItem(.separator())
        menu.addItem(command("Reload Config", "arrow.clockwise", "r", #selector(reload)))
        menu.addItem(command("Open Config…", "slider.horizontal.3", ",", #selector(openConfig)))
        menu.addItem(.separator())
        menu.addItem(command("Quit Blox", "power", "q", #selector(NSApplication.terminate), target: NSApp))
    }

    @objc func pick(_ sender: NSMenuItem) {
        (sender.representedObject as? String).map(actions.switchTo)
    }

    @objc func reload() {
        actions.reload()
    }

    @objc func openConfig() {
        actions.openConfig()
    }
}
