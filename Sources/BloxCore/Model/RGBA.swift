/// A color with 0...1 channels, parsed from `rrggbb` or `rrggbbaa` hex (optional leading `#`).
public struct RGBA: Equatable, Sendable {
    public let red, green, blue, alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        (self.red, self.green, self.blue, self.alpha) = (red, green, blue, alpha)
    }

    public init?(hex text: String) {
        let digits = text.hasPrefix("#") ? String(text.dropFirst()) : text
        guard digits.count == 6 || digits.count == 8,
              let value = UInt32(digits, radix: 16) else { return nil }
        let hasAlpha = digits.count == 8
        let shift: (Int) -> Double = { Double((value >> UInt32($0)) & 0xFF) / 255 }
        self.init(
            red: shift(hasAlpha ? 24 : 16),
            green: shift(hasAlpha ? 16 : 8),
            blue: shift(hasAlpha ? 8 : 0),
            alpha: hasAlpha ? shift(0) : 1,
        )
    }
}
