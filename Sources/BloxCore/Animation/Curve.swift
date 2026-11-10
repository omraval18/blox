/// A CSS-style cubic bezier easing curve from (0,0) to (1,1) with two control points.
/// `y` values outside 0...1 give overshoot, as in Hyprland's bezier curves.
public struct Curve: Equatable, Sendable {
    public let x1, y1, x2, y2: Double

    init(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) {
        (self.x1, self.y1, self.x2, self.y2) = (x1, y1, x2, y2)
    }

    /// Accepts a preset name (`snappy`) or four numbers (`0.34 1.56 0.64 1`).
    public init?(parsing text: String) {
        if let preset = Self.presets[text] {
            self = preset
            return
        }
        let numbers = text.split(separator: " ").compactMap { Double($0) }
        guard numbers.count == 4, (0.0 ... 1.0).contains(numbers[0]), (0.0 ... 1.0).contains(numbers[2]),
              numbers.allSatisfy({ (-2.0 ... 3.0).contains($0) }) else { return nil }
        self.init(numbers[0], numbers[1], numbers[2], numbers[3])
    }

    public static var presetNames: [String] {
        presets.keys.sorted()
    }

    /// Eased progress for linear time `time` in 0...1.
    public func value(at time: Double) -> Double {
        let clamped = min(max(time, 0), 1)
        return Self.bezier(solve(forX: clamped), y1, y2)
    }

    private static func bezier(_ parameter: Double, _ first: Double, _ second: Double) -> Double {
        let inverse = 1 - parameter
        return 3 * inverse * inverse * parameter * first + 3 * inverse * parameter * parameter * second
            + parameter * parameter * parameter
    }

    /// Finds the bezier parameter whose x equals `target`: Newton steps, then bisection as a fallback.
    private func solve(forX target: Double) -> Double {
        var guess = target
        for _ in 0 ..< 6 {
            let error = Self.bezier(guess, x1, x2) - target
            let slope = Self.slope(guess, x1, x2)
            guard abs(error) > 1e-6, slope > 1e-6 else { break }
            guess -= error / slope
        }
        if abs(Self.bezier(guess, x1, x2) - target) < 1e-5 {
            return guess
        }
        var (low, high) = (0.0, 1.0)
        for _ in 0 ..< 30 {
            let middle = (low + high) / 2
            if Self.bezier(middle, x1, x2) < target {
                low = middle
            } else {
                high = middle
            }
        }
        return (low + high) / 2
    }

    private static func slope(_ parameter: Double, _ first: Double, _ second: Double) -> Double {
        let inverse = 1 - parameter
        return 3 * inverse * inverse * first + 6 * inverse * parameter * (second - first)
            + 3 * parameter * parameter * (1 - second)
    }
}
