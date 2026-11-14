import CoreGraphics

/// How a new window arrives (Hyprland's `windowsIn`).
public enum Entrance: Equatable, Sendable {
    case off
    /// Glide from wherever the app opened the window.
    case slide
    /// Grow from the centre of its tile, starting at this fraction of its size.
    case popin(Double)

    /// `off`, `slide`, `popin` or `popin <percent>` (Hyprland's default percent is 80).
    public init?(parsing text: String) {
        let words = text.split(separator: " ").map(String.init)
        switch (words.first, words.count) {
        case ("off", 1): self = .off
        case ("slide", 1): self = .slide
        case ("popin", 1): self = .popin(0.8)
        case ("popin", 2):
            guard let percent = Double(words[1]), (1 ... 100).contains(percent) else { return nil }
            self = .popin(percent / 100)
        default: return nil
        }
    }

    /// Where a `popin` starts, or nil when the window should glide from where it is.
    public func startFrame(for target: CGRect) -> CGRect? {
        guard case let .popin(scale) = self else { return nil }
        let size = CGSize(width: target.width * scale, height: target.height * scale)
        return CGRect(
            x: target.midX - size.width / 2,
            y: target.midY - size.height / 2,
            width: size.width,
            height: size.height,
        ).pixelAligned
    }
}
