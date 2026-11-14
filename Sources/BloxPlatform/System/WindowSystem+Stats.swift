import AppKit

public extension WindowSystem {
    /// Animation counters since launch, one line per measured app, for `blox stats`.
    var animationStats: String {
        animator.writer.stats.summary { pid in
            NSRunningApplication(processIdentifier: pid)?.localizedName ?? "unknown"
        }
    }
}
