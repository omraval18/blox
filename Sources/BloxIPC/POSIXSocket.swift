import Darwin

/// Thin wrappers over BSD sockets. With `POSIXSocket+IO.swift`, the only code handling raw pointers.
enum POSIXSocket {
    struct Failure: Error, CustomStringConvertible {
        let description: String
    }

    static func listen(path: String) throws -> Int32 {
        let descriptor = try makeSocket()
        remove(path)
        let previousMask = umask(0o177)
        defer { umask(previousMask) }
        let status = try perform(.bind, descriptor, path: path)
        guard status == 0, Darwin.listen(descriptor, 8) == 0 else {
            close(descriptor)
            throw Failure(description: "cannot listen on \(path)")
        }
        return descriptor
    }

    static func remove(_ path: String) {
        unsafe unlink(path)
    }

    static func connect(path: String) throws -> Int32 {
        let descriptor = try makeSocket()
        let status = try perform(.connect, descriptor, path: path)
        guard status == 0 else {
            close(descriptor)
            throw Failure(description: "blox is not running (cannot connect to \(path))")
        }
        return descriptor
    }

    static func setTimeout(_ descriptor: Int32, seconds: Int) {
        var timeout = timeval(tv_sec: seconds, tv_usec: 0)
        let size = socklen_t(MemoryLayout<timeval>.size)
        unsafe setsockopt(descriptor, SOL_SOCKET, SO_RCVTIMEO, &timeout, size)
        unsafe setsockopt(descriptor, SOL_SOCKET, SO_SNDTIMEO, &timeout, size)
        var one: Int32 = 1
        unsafe setsockopt(descriptor, SOL_SOCKET, SO_NOSIGPIPE, &one, socklen_t(MemoryLayout<Int32>.size))
    }

    private static func makeSocket() throws -> Int32 {
        let descriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw Failure(description: "cannot create socket") }
        return descriptor
    }

    private enum Operation {
        case bind, connect
    }

    /// Builds a `sockaddr_un` for `path` and runs `bind` or `connect` with it.
    private static func perform(_ operation: Operation, _ descriptor: Int32, path: String) throws -> Int32 {
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        let bytes = Array(path.utf8)
        guard bytes.count < MemoryLayout.size(ofValue: address.sun_path) else {
            throw Failure(description: "socket path too long")
        }
        unsafe withUnsafeMutableBytes(of: &address.sun_path) { unsafe $0.copyBytes(from: bytes) }
        let length = socklen_t(MemoryLayout<sockaddr_un>.size)
        return unsafe withUnsafePointer(to: &address) { pointer in
            unsafe pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { generic in
                switch operation {
                case .bind: unsafe Darwin.bind(descriptor, generic, length)
                case .connect: unsafe Darwin.connect(descriptor, generic, length)
                }
            }
        }
    }
}
