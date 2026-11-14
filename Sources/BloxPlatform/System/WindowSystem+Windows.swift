import AppKit
import ApplicationServices
import BloxCore

extension WindowSystem {
    func adopt(_ element: AXUIElement) {
        guard let window = AXWindow(element), windows[window.id] == nil, window.isTileable,
              let app = NSRunningApplication(processIdentifier: window.pid), !app.isHidden else { return }
        windows[window.id] = window
        newWindows.insert(window.id)
        // New windows glide from wherever the app opened them to their tile.
        realFrame(of: window).map { animator.record(window.id, $0) }
        ids[element] = window.id
        observers[window.pid]?.watch(element)
        onCommand(.windowAppeared(window.id, app: app.bundleIdentifier ?? ""))
    }

    /// Adopts a window that is not ready yet (no standard role or resizable size for a moment after
    /// creation) once more shortly afterwards.
    private func adoptSoon(_ element: AXUIElement) {
        adopt(element)
        guard ids[element] == nil else { return }
        Task {
            try? await Task.sleep(for: .milliseconds(250))
            adopt(element)
        }
    }

    /// Follows focus to a window. A window that went native fullscreen leaves tiling until it returns.
    func reportFocus(_ element: AXUIElement) {
        if let id = ids[element], windows[id]?.isFullScreen == true {
            return release(element)
        }
        adopt(element)
        ids[element].map {
            onCommand(.focusChanged($0))
            restackBorder($0)
        }
    }

    /// Where a window really is, from the window server (~0.1 ms, no round trip to its app, so a
    /// slow or hung app cannot stall it); Accessibility only when the window server has no answer.
    func realFrame(of window: AXWindow) -> CGRect? {
        WindowServer.bounds(of: window.id) ?? window.frame
    }

    /// Process owning a window, for the workspace menu's app names and icons.
    public func owner(of id: WindowID) -> pid_t? {
        windows[id]?.pid
    }

    func release(_ element: AXUIElement) {
        guard let id = ids.removeValue(forKey: element) else { return }
        windows.removeValue(forKey: id).map { animator.writer.forget(id, of: $0.pid) }
        parked.removeValue(forKey: id)
        refusesParking.remove(id)
        newWindows.remove(id)
        animator.forget(id)
        border.remove(id)
        onCommand(.windowDisappeared(id))
    }

    func handle(_ event: AXEvent) {
        switch event {
        case let .created(element), let .restored(element): adoptSoon(element)
        case let .destroyed(element), let .minimized(element): release(element)
        case let .focused(element): reportFocus(element)
        case let .reshaped(element): ids[element].map(reshaped)
        }
    }
}
