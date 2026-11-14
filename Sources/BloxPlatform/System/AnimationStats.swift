import BloxCore
import Foundation

/// Always-on animation counters, cheap enough to keep: they change only inside display-link ticks
/// that run anyway, so an idle Blox does no work for them.
struct AnimationStats {
    /// What one animation step asked of an app: a resize makes it lay out its window again, a
    /// move is nearly free.
    enum Step: CaseIterable {
        case resizing
        case moving
    }

    private(set) var frames = 0
    private(set) var lateFrames = 0
    /// How long each app (by pid) takes to answer one step of each kind.
    private var paces: [pid_t: [Step: Pace]] = [:]

    mutating func frame(work: Double, interval: Double) {
        frames += 1
        if Pace.isLate(work: work, interval: interval) {
            lateFrames += 1
        }
    }

    mutating func answered(_ pid: pid_t, _ step: Step, in seconds: Double) {
        if paces[pid]?[step] == nil {
            paces[pid, default: [:]][step] = Pace(first: seconds)
        } else {
            paces[pid]?[step]?.add(seconds)
        }
    }

    func pace(of pid: pid_t, _ step: Step) -> Pace? {
        paces[pid]?[step]
    }

    /// The app quit: its numbers go with it.
    mutating func drop(_ pid: pid_t) {
        paces.removeValue(forKey: pid)
    }

    /// One line for the frame counts, then one per app, slowest resize first.
    func summary(naming name: (pid_t) -> String) -> String {
        let late = frames == 0 ? 0 : Double(lateFrames) * 100 / Double(frames)
        let head = "frames \(frames), late \(lateFrames) (\(Self.decimal(late, 1))%)"
        let apps = paces.sorted { ($0.value[.resizing]?.average ?? 0) > ($1.value[.resizing]?.average ?? 0) }
        return ([head] + apps.map { pid, paces in
            "\(name(pid)) (pid \(pid)): " + Step.allCases.map { Self.describe($0, paces[$0]) }
                .joined(separator: ", ")
        }).joined(separator: "\n")
    }

    private static func describe(_ step: Step, _ pace: Pace?) -> String {
        let label = step == .resizing ? "resize" : "move"
        guard let pace else { return "\(label) -" }
        return "\(label) \(decimal(pace.average * 1000, 2)) ms (\(pace.samples) steps)"
    }

    private static func decimal(_ value: Double, _ digits: Int) -> String {
        value.formatted(.number.precision(.fractionLength(digits)).grouping(.never))
    }
}
