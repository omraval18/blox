import Darwin

extension POSIXSocket {
    static let maxRequestBytes = 4096
    static let maxReplyBytes = 1 << 20

    /// Reads until newline, EOF, timeout, or the size cap.
    static func readLine(_ descriptor: Int32) -> String {
        let data = read(descriptor, limit: maxRequestBytes) { $0.contains(UInt8(ascii: "\n")) }
        return text(data).split(separator: "\n").first.map(String.init) ?? ""
    }

    static func readAll(_ descriptor: Int32) -> String {
        text(read(descriptor, limit: maxReplyBytes) { _ in false })
    }

    static func write(_ descriptor: Int32, _ text: String) {
        let bytes = Array(text.utf8)
        var sent = 0
        while sent < bytes.count {
            let count = unsafe bytes.withUnsafeBytes { raw in
                guard let base = raw.baseAddress else { return -1 }
                return unsafe Darwin.write(descriptor, base + sent, bytes.count - sent)
            }
            guard count > 0 else { return }
            sent += count
        }
    }

    private static func read(_ descriptor: Int32, limit: Int, isComplete: ([UInt8]) -> Bool) -> [UInt8] {
        var data: [UInt8] = []
        var chunk = [UInt8](repeating: 0, count: 512)
        while data.count < limit, !isComplete(data) {
            let count = unsafe chunk.withUnsafeMutableBytes { unsafe Darwin.read(
                descriptor,
                $0.baseAddress,
                $0.count,
            ) }
            guard count > 0 else { break }
            data += chunk.prefix(count)
        }
        return data
    }

    private static func text(_ bytes: [UInt8]) -> String {
        String(decoding: bytes, as: UTF8.self)
    }
}
