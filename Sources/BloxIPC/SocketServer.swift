import Darwin
import Dispatch

/// Accepts one-line requests on a Unix socket and answers each with one reply.
/// Event-driven: nothing runs while no client is connected.
public struct SocketServer: Sendable {
    public typealias Handler = @Sendable (String) async -> String

    private let source: any DispatchSourceRead

    public static func start(path: String, handler: @escaping Handler) throws -> Self {
        let descriptor = try POSIXSocket.listen(path: path)
        let queue = DispatchQueue(label: "blox.ipc")
        let source = DispatchSource.makeReadSource(fileDescriptor: descriptor, queue: queue)
        source.setEventHandler {
            let client = accept(descriptor, nil, nil)
            guard client >= 0 else { return }
            POSIXSocket.setTimeout(client, seconds: 2)
            queue.async { serve(client, handler) }
        }
        source.setCancelHandler {
            close(descriptor)
            POSIXSocket.remove(path)
        }
        source.resume()
        return Self(source: source)
    }

    public func stop() {
        source.cancel()
    }

    private static func serve(_ client: Int32, _ handler: @escaping Handler) {
        let request = POSIXSocket.readLine(client)
        Task {
            await POSIXSocket.write(client, handler(request) + "\n")
            close(client)
        }
    }
}
