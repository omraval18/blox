#!/usr/bin/env swift
// Benchmarks the window manager that is currently running (Blox or AeroSpace) on identical work,
// so two runs can be compared. See docs/benchmarking.md for the method and its limits.
//
//   swift Scripts/bench-compare.swift blox [--sizes 0,5,10,20] [--runs 20] [--idle 10]
//   swift Scripts/bench-compare.swift aerospace
//   swift Scripts/bench-compare.swift --self-test
import CoreGraphics
import Foundation

// MARK: - Statistics

func percentile(_ sorted: [Double], _ fraction: Double) -> Double {
    guard !sorted.isEmpty else { return 0 }
    let rank = fraction * Double(sorted.count - 1)
    let low = Int(rank.rounded(.down)), high = Int(rank.rounded(.up))
    return sorted[low] + (sorted[high] - sorted[low]) * (rank - Double(low))
}

struct Summary {
    let mean, median, p95, max: Double
    init(_ values: [Double]) {
        let sorted = values.sorted()
        mean = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        median = percentile(sorted, 0.5)
        p95 = percentile(sorted, 0.95)
        max = sorted.last ?? 0
    }
    var text: String { String(format: "%6.1f %6.1f %6.1f %6.1f", mean, median, p95, max) }
}

// MARK: - Processes

@discardableResult
func shell(_ tool: String, _ arguments: [String] = []) -> (status: Int32, output: String) {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(fileURLWithPath: tool)
    process.arguments = arguments
    process.standardOutput = pipe
    process.standardError = pipe
    guard (try? process.run()) != nil else { return (-1, "") }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    return (process.terminationStatus, String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines))
}

func nowMs() -> Double { Double(DispatchTime.now().uptimeNanoseconds) / 1e6 }

func parseCPUTime(_ text: String) -> Double {
    text.split(separator: ":").reduce(0.0) { $0 * 60 + (Double($1) ?? 0) }
}

func parseFootprintMB(_ text: String) -> Double? {
    guard let range = text.range(of: #"Footprint: [0-9.]+ [KMG]B"#, options: .regularExpression) else { return nil }
    let parts = text[range].split(separator: " ")
    guard parts.count == 3, let value = Double(parts[1]) else { return nil }
    return value * ["KB": 1.0 / 1024, "MB": 1, "GB": 1024][String(parts[2])]!
}

struct Manager {
    let name: String
    let processPattern: String
    let cli: String
    let layoutA: [String], layoutB: [String]

    var pid: Int32? { Int32(shell("/usr/bin/pgrep", ["-f", processPattern]).output.split(separator: "\n").first ?? "") }

    @discardableResult
    func run(_ arguments: [String]) -> (status: Int32, output: String) { shell(cli, arguments) }

    func focusedWorkspace() -> String {
        if name == "blox" {
            let status = run(["status"]).output
            let line = status.split(separator: "\n").first { $0.hasPrefix("*") } ?? ""
            return line.components(separatedBy: "workspace ").last ?? ""
        }
        return run(["list-workspaces", "--focused"]).output
    }

    func workspaceIsEmpty(_ workspace: String) -> Bool {
        if name == "blox" {
            let status = run(["status"]).output
            return !status.contains("workspace \(workspace): ") || status.contains("workspace \(workspace): 0 tiled, 0 floating")
        }
        return run(["list-windows", "--workspace", workspace]).output.isEmpty
    }
}

func manager(named name: String) -> Manager? {
    func resolve(_ tool: String) -> String? {
        let path = shell("/usr/bin/which", [tool]).output
        return path.isEmpty ? nil : path
    }
    switch name {
    case "blox":
        return resolve("blox").map { Manager(name: name, processPattern: "Blox.app/Contents/MacOS/Blox", cli: $0, layoutA: ["layout", "monocle"], layoutB: ["layout", "dwindle"]) }
    case "aerospace":
        return resolve("aerospace").map { Manager(name: name, processPattern: "AeroSpace.app/Contents/MacOS/AeroSpace", cli: $0, layoutA: ["layout", "accordion", "horizontal", "vertical"], layoutB: ["layout", "tiles", "horizontal", "vertical"]) }
    default:
        return nil
    }
}

struct ProcessSample { let footprintMB: Double, rssMB: Double, threads: Int, cpuSeconds: Double }

func sample(_ pid: Int32) -> ProcessSample {
    let fields = shell("/bin/ps", ["-o", "rss=,time=", "-p", "\(pid)"]).output.split(separator: " ").map(String.init)
    let threads = shell("/bin/ps", ["-M", "-p", "\(pid)"]).output.split(separator: "\n").count - 1
    return ProcessSample(
        footprintMB: parseFootprintMB(shell("/usr/bin/footprint", ["\(pid)"]).output) ?? 0,
        rssMB: (Double(fields.first ?? "") ?? 0) / 1024,
        threads: threads,
        cpuSeconds: parseCPUTime(fields.last ?? ""),
    )
}

// MARK: - Windows

let screenRight = CGDisplayBounds(CGMainDisplayID()).maxX

func benchWindows() -> [Int: CGRect] {
    let list = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] ?? []
    var result: [Int: CGRect] = [:]
    for window in list where window[kCGWindowOwnerName as String] as? String == "TextEdit" && window[kCGWindowLayer as String] as? Int == 0 {
        guard let number = window[kCGWindowNumber as String] as? Int,
              let bounds = window[kCGWindowBounds as String] as? NSDictionary,
              let frame = CGRect(dictionaryRepresentation: bounds) else { continue }
        result[number] = frame
    }
    return result
}

/// Parked windows sit at the right edge of the screen (both managers do this).
func isParked(_ frame: CGRect) -> Bool { frame.minX >= screenRight - 3 }

func wait(timeoutMs: Double, pollMs: Double = 2, until condition: () -> Bool) -> Bool {
    let start = nowMs()
    while nowMs() - start < timeoutMs {
        if condition() { return true }
        usleep(UInt32(pollMs * 1000))
    }
    return condition()
}

func openBenchWindows(_ count: Int) {
    guard count > 0 else { return }
    let before = benchWindows().count
    let script = "tell application \"TextEdit\" to repeat \(count) times\nmake new document with properties {text:\"blox-bench\"}\nend repeat"
    shell("/usr/bin/osascript", ["-e", script])
    _ = wait(timeoutMs: 8000, pollMs: 50) { benchWindows().count >= before + count }
}

func closeBenchWindows() {
    let script = """
    tell application "TextEdit"
    repeat with index from (count of documents) to 1 by -1
    if text of document index is "blox-bench" then close document index saving no
    end repeat
    end tell
    """
    shell("/usr/bin/osascript", ["-e", script])
}

// MARK: - Measurements

struct Row { let windows: Int; let idle: ProcessSample; let idleCPUPercent: Double }

func measureIdle(_ pid: Int32, seconds: Double) -> (ProcessSample, Double) {
    let first = sample(pid)
    let start = nowMs()
    sleep(UInt32(seconds))
    let last = sample(pid)
    let cpu = (last.cpuSeconds - first.cpuSeconds) / ((nowMs() - start) / 1000) * 100
    return (last, cpu)
}

struct Workload { let latencyMs: [Double], effectMs: [Double], timeouts: Int, cpuMsPerCommand: Double, peakRSS: Double }

/// Sends `commands` in turn and times the CLI round trip, and how long until the windows visibly
/// reach the state `reached` reports (read from WindowServer, not from the manager's own reply).
func measure(_ wm: Manager, pid: Int32, rounds: Int, step: (Int) -> (command: [String], reached: () -> Bool)) -> Workload {
    var latency: [Double] = [], effect: [Double] = [], timeouts = 0, peak = 0.0
    let cpuBefore = sample(pid).cpuSeconds
    for round in 0..<rounds {
        let (command, reached) = step(round)
        let start = nowMs()
        wm.run(command)
        latency.append(nowMs() - start)
        if wait(timeoutMs: 1500, until: reached) { effect.append(nowMs() - start) } else { timeouts += 1 }
        usleep(150_000)
        peak = max(peak, sample(pid).rssMB)
    }
    let cpu = sample(pid).cpuSeconds - cpuBefore
    return Workload(latencyMs: latency, effectMs: effect, timeouts: timeouts, cpuMsPerCommand: cpu * 1000 / Double(rounds), peakRSS: peak)
}

func report(_ title: String, _ workload: Workload) {
    print("  \(title)")
    print("    CLI round trip ms   mean median    p95    max  \(Summary(workload.latencyMs).text)")
    print("    until windows move  mean median    p95    max  \(Summary(workload.effectMs).text)   (timeouts: \(workload.timeouts))")
    print(String(format: "    manager CPU per command: %.1f ms   peak RSS during run: %.1f MB", workload.cpuMsPerCommand, workload.peakRSS))
}

// MARK: - Main

func selfTest() {
    precondition(percentile([1, 2, 3, 4, 5], 0.5) == 3)
    precondition(abs(percentile([10, 20], 0.95) - 19.5) < 1e-9)
    precondition(parseCPUTime("1:02.50") == 62.5 && parseCPUTime("1:00:00.00") == 3600)
    precondition(parseFootprintMB("Blox [1]: 64-bit    Footprint: 16 MB (16384 bytes per page)") == 16)
    precondition(parseFootprintMB("Footprint: 512 KB") == 0.5)
    precondition(Summary([1, 2, 3, 100]).max == 100)
    print("self-test ok")
}

let arguments = Array(CommandLine.arguments.dropFirst())
if arguments.contains("--self-test") { selfTest(); exit(0) }

func option(_ name: String, default value: String) -> String {
    arguments.firstIndex(of: name).flatMap { arguments.indices.contains($0 + 1) ? arguments[$0 + 1] : nil } ?? value
}

guard let name = arguments.first, let wm = manager(named: name), let pid = wm.pid else {
    print("usage: swift Scripts/bench-compare.swift <blox|aerospace> [--sizes 0,5,10,20] [--runs 20] [--idle 10]\n(the manager must be running and its CLI on PATH)")
    exit(2)
}
let sizes = option("--sizes", default: "0,5,10,20").split(separator: ",").compactMap { Int($0) }
let rounds = Int(option("--runs", default: "20")) ?? 20
let idleSeconds = Double(option("--idle", default: "10")) ?? 10
let scratch = "Z"
let origin = wm.focusedWorkspace()

guard origin != scratch, wm.workspaceIsEmpty(scratch) else { print("workspace \(scratch) must be empty and not the current one; aborting"); exit(1) }
if shell("/usr/bin/pmset", ["-g", "batt"]).output.contains("Battery Power") { print("warning: on battery. Plug in for steady results.\n") }

func cleanup() {
    wm.run(["workspace", origin])
    closeBenchWindows()
    if wm.name == "blox" { wm.run(["reload"]) }
}
signal(SIGINT, SIG_IGN)
let interrupt = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
interrupt.setEventHandler { cleanup(); exit(130) }
interrupt.resume()

print("== \(wm.name) (pid \(pid)) on \(shell("/usr/sbin/sysctl", ["-n", "machdep.cpu.brand_string"]).output), macOS \(shell("/usr/bin/sw_vers", ["-productVersion"]).output)")
if wm.name == "blox" { wm.run(["animation", "off"]) }

var open = 0
for size in sizes where size >= open {
    openBenchWindows(size - open)
    open = size
    sleep(3)
    let (idle, cpu) = measureIdle(pid, seconds: idleSeconds)
    print(String(format: "\n-- %d bench windows: footprint %.1f MB, RSS %.1f MB, %d threads, idle CPU %.2f%% over %.0fs", size, idle.footprintMB, idle.rssMB, idle.threads, cpu, idleSeconds))
    guard size >= 2 else { continue }
    let ids = Array(benchWindows().keys)
    report("workspace flip (hide then show all \(size) windows)", measure(wm, pid: pid, rounds: rounds * 2) { round in
        let hide = round % 2 == 0
        return (["workspace", hide ? scratch : origin], { let frames = benchWindows(); return ids.allSatisfy { frames[$0].map(isParked) == hide } })
    })
    var snapshot = benchWindows()
    report("layout flip (re-tile all \(size) windows)", measure(wm, pid: pid, rounds: rounds * 2) { round in
        let before = snapshot
        return (round % 2 == 0 ? wm.layoutA : wm.layoutB, { let now = benchWindows(); let moved = now != before; if moved { snapshot = now }; return moved })
    })
}
cleanup()
print("\ndone")
