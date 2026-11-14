/// How often a gliding window is resized, decided per app from how fast it answers a resize step.
/// A resize makes the app lay out its whole window again (Chromium and Electron apps take 5 to
/// 22 ms per step); a move is nearly free.
public enum ResizeMode: Equatable, Sendable {
    case everyFrame
    case once

    /// An app that takes this long (seconds) or longer per resize step is resized once per glide.
    /// 8 ms is a whole frame at 120 Hz and half of one at 60 Hz, which leaves no room for the
    /// other windows moving in the same frame.
    public static let slowResizeStep = 0.008

    /// `averageResizeStep` is nil for an app not measured yet: it animates fully, which is how it
    /// gets measured.
    public init(averageResizeStep: Double?) {
        guard let average = averageResizeStep, average >= Self.slowResizeStep else {
            self = .everyFrame
            return
        }
        self = .once
    }
}
