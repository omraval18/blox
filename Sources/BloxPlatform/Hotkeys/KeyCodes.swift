import BloxCore
import Carbon

/// Key names usable in config chords, mapped to ANSI virtual key codes.
enum KeyCodes {
    static func code(for key: String) -> UInt32? {
        table[aliases[key] ?? key]
    }

    static func carbonModifiers(_ modifiers: Set<Chord.Modifier>) -> UInt32 {
        modifiers.reduce(0) { $0 | flag(for: $1) }
    }

    private static func flag(for modifier: Chord.Modifier) -> UInt32 {
        switch modifier {
        case .cmd: UInt32(cmdKey)
        case .shift: UInt32(shiftKey)
        case .alt: UInt32(optionKey)
        case .ctrl: UInt32(controlKey)
        }
    }

    private static let aliases = [
        "-": "minus", "=": "equal", ",": "comma", ".": "period", "/": "slash", ";": "semicolon",
        "'": "quote", "[": "leftbracket", "]": "rightbracket", "\\": "backslash", "`": "grave",
    ]

    private static let table: [String: UInt32] = [
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9, "b": 11,
        "q": 12, "w": 13, "e": 14, "r": 15, "y": 16, "t": 17, "o": 31, "u": 32, "i": 34, "p": 35,
        "l": 37, "j": 38, "k": 40, "n": 45, "m": 46,
        "1": 18, "2": 19, "3": 20, "4": 21, "6": 22, "5": 23, "9": 25, "7": 26, "8": 28, "0": 29,
        "equal": 24, "minus": 27, "rightbracket": 30, "leftbracket": 33, "quote": 39, "semicolon": 41,
        "backslash": 42, "comma": 43, "slash": 44, "period": 47, "grave": 50,
        "return": 36, "tab": 48, "space": 49, "delete": 51, "escape": 53,
        "left": 123, "right": 124, "down": 125, "up": 126,
    ]
}
