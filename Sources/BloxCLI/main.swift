import BloxIPC
import Darwin

let usage = """
usage: blox <command>

  focus|move left|right|up|down     move focus, or swap the focused window
  workspace <name>                  switch workspace
  move-to-workspace <name>          send the focused window to a workspace
  layout dwindle|primary|monocle    change the workspace layout
  resize <delta>                    grow (+) or shrink (-) the main split, e.g. resize 0.05
  toggle-floating                   float or tile the focused window
  retile                            re-apply the layout
  status                            show monitors and workspaces
  reload                            reload the config file
  version                           version of the running app
  --version                         version of this CLI
"""

let arguments = CommandLine.arguments.dropFirst()
switch arguments.first {
case nil, "-h", "--help":
    print(usage)
    exit(arguments.isEmpty ? 2 : 0)
case "--version":
    print(bloxVersion)
    exit(0)
default:
    break
}

do {
    let reply = try SocketClient.send(arguments.joined(separator: " "))
    print(reply)
    exit(reply.hasPrefix("error") ? 1 : 0)
} catch {
    print("error: \(error)")
    exit(1)
}
