import BloxIPC
import Darwin

let arguments = CommandLine.arguments.dropFirst()
guard !arguments.isEmpty else {
    print("usage: blox <command>   e.g. blox focus left | blox workspace 2 | blox status")
    exit(2)
}

do {
    let reply = try SocketClient.send(arguments.joined(separator: " "))
    print(reply)
    exit(reply.hasPrefix("error") ? 1 : 0)
} catch {
    print("error: \(error)")
    exit(1)
}
