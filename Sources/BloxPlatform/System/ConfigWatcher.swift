import Dispatch
import Foundation

/// Calls `onChange` shortly after anything in the config directory changes. Watching the
/// directory (not the file) survives editors that save by replacing the file.
@MainActor
public final class ConfigWatcher {
    private let source: any DispatchSourceFileSystemObject
    private var pending: DispatchWorkItem?

    public init?(directory: String, onChange: @escaping @MainActor () -> Void) {
        let descriptor = unsafe open(directory, O_EVTONLY)
        guard descriptor >= 0 else { return nil }
        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: .write,
            queue: .main,
        )
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated { self?.schedule(onChange) }
        }
        source.setCancelHandler { close(descriptor) }
        source.resume()
    }

    private func schedule(_ onChange: @escaping @MainActor () -> Void) {
        pending?.cancel()
        let item = DispatchWorkItem { MainActor.assumeIsolated(onChange) }
        pending = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: item)
    }

    deinit {
        source.cancel()
    }
}
