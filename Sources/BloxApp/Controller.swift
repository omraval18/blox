import AppKit
import BloxCore
import BloxIPC
import BloxPlatform
import Foundation
import OSLog

/// Owns the state and connects the pieces: events in, reducer, effects out.
@MainActor
final class Controller {
    private let log = Logger(subsystem: "blox", category: "controller")
    private let configFile = ConfigFile()
    private var state = State()
    private var config = Config()
    private var watcher: ConfigWatcher?
    private var server: SocketServer?
    private lazy var system = WindowSystem { [weak self] in self?.dispatch($0) }
    private lazy var menu = StatusMenu(
        onReload: { [weak self] in _ = self?.reloadConfig() },
        onOpenConfig: { [weak self] in self?.openConfig() },
        onSwitch: { [weak self] in self?.dispatch(.switchWorkspace($0)) },
    )
    private lazy var hotkeys = HotkeyCenter { [weak self] in self?.runBinding($0) }

    func start() {
        _ = menu
        _ = reloadConfig()
        state = State(settings: config.settings)
        system.settings = state.settings
        system.start()
        watcher = ConfigWatcher(directory: configFile.directory) { [weak self] in _ = self?.reloadConfig() }
        server = startServer()
    }

    func stop() {
        server?.stop()
        system.restoreParked()
    }

    func dispatch(_ command: Command) {
        if case .reloadConfig = command {
            _ = reloadConfig()
            return
        }
        if case let .setMode(name) = command, config.modes[name] == nil {
            return
        }
        let previousMode = state.mode
        let (next, effects) = reduce(state, command)
        state = next
        system.settings = next.settings
        system.execute(effects)
        system.setFocused(next.focusedWindow)
        menu.update(rows: workspaceRows())
        if next.mode != previousMode {
            registerBindings()
        }
    }

    var summary: String {
        state.summary
    }

    /// Reloads the config file. On error the previous config stays active and the message is returned.
    func reloadConfig() -> String? {
        do {
            config = try Config(parsing: configFile.read())
        } catch {
            log.error("config: \(error)")
            menu.setError("\(error)")
            return "\(error)"
        }
        menu.setError(nil)
        if config.modes[state.mode] == nil {
            state.mode = Config.mainMode
        }
        dispatch(.updateSettings(config.settings))
        registerBindings()
        return nil
    }

    private func registerBindings() {
        let refused = hotkeys.register(activeBindings.map(\.chord))
        refused.forEach { log.error("hotkey unavailable: \($0.key)") }
        menu.setMode(state.mode)
    }

    private var activeBindings: [Config.Binding] {
        config.modes[state.mode] ?? []
    }

    private func workspaceRows() -> [WorkspaceRow] {
        state.overview(including: config.workspaceNames).map { info in
            var seen = Set<String>()
            let apps = info.windows.compactMap { system.appName(of: $0) }.filter { seen.insert($0).inserted }
            return WorkspaceRow(info: info, apps: apps)
        }
    }

    private func openConfig() {
        NSWorkspace.shared.open(URL(fileURLWithPath: configFile.path))
    }

    private func runBinding(_ index: Int) {
        guard activeBindings.indices.contains(index) else { return }
        activeBindings[index].commands.forEach(dispatch)
    }

    private func startServer() -> SocketServer? {
        do {
            return try SocketServer.start(path: SocketPath.default) { [weak self] request in
                await self?.handle(request) ?? "error: shutting down"
            }
        } catch {
            log.error("ipc: \(error)")
            return nil
        }
    }
}
