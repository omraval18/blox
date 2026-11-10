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
    )
    private lazy var hotkeys = HotkeyCenter { [weak self] in self?.runBinding($0) }

    func start() {
        _ = menu
        _ = reloadConfig()
        state = State(settings: config.settings)
        system.start()
        watcher = ConfigWatcher(directory: configFile.directory) { [weak self] in _ = self?.reloadConfig() }
        server = startServer()
    }

    func stop() {
        server?.stop()
        system.restoreParked()
    }

    func dispatch(_ command: Command) {
        let (next, effects) = reduce(state, command)
        state = next
        system.execute(effects)
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
        system.animation = config.settings.animation
        dispatch(.updateSettings(config.settings))
        let refused = hotkeys.register(config.bindings.map(\.chord))
        refused.forEach { log.error("hotkey unavailable: \($0.key)") }
        return nil
    }

    private func openConfig() {
        NSWorkspace.shared.open(URL(fileURLWithPath: configFile.path))
    }

    private func runBinding(_ index: Int) {
        guard config.bindings.indices.contains(index) else { return }
        dispatch(config.bindings[index].command)
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
