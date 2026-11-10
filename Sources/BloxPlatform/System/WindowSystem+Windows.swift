import AppKit
import ApplicationServices
import BloxCore

extension WindowSystem {
    func adopt(_ element: AXUIElement) {
        guard let window = AXWindow(element), windows[window.id] == nil, window.isTileable else { return }
        windows[window.id] = window
        // New windows glide from wherever the app opened them to their tile.
        window.frame.map { animator.record(window.id, $0) }
        ids[element] = window.id
        observers[window.pid]?.watch(element)
        let app = NSRunningApplication(processIdentifier: window.pid)?.bundleIdentifier ?? ""
        onCommand(.windowAppeared(window.id, app: app))
    }

    /// Localized name of the app owning a window, for the workspace bar.
    public func appName(of id: WindowID) -> String? {
        windows[id].flatMap { NSRunningApplication(processIdentifier: $0.pid)?.localizedName }
    }

    func release(_ element: AXUIElement) {
        guard let id = ids.removeValue(forKey: element) else { return }
        windows.removeValue(forKey: id)
        parked.removeValue(forKey: id)
        animator.forget(id)
        border.remove(id)
        onCommand(.windowDisappeared(id))
    }

    func handle(_ event: AXEvent) {
        switch event {
        case let .created(element), let .restored(element): adopt(element)
        case let .destroyed(element), let .minimized(element): release(element)
        case let .focused(element):
            adopt(element)
            ids[element].map { onCommand(.focusChanged($0)) }
        }
    }
}
