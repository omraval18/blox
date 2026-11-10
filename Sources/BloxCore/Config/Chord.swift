/// A hotkey such as `alt-shift-h`: zero or more modifiers plus a key name. Modifier-less chords
/// are only accepted in non-main modes (such as `resize`), where plain keys are expected.
public struct Chord: Hashable, Sendable {
    public enum Modifier: String, Sendable, CaseIterable {
        case alt, ctrl, shift, cmd
    }

    public let modifiers: Set<Modifier>
    public let key: String

    public init?(parsing text: String) {
        let parts = text.lowercased().split(separator: "-", omittingEmptySubsequences: false).map(String.init)
        let modifiers = parts.prefix { Modifier(rawValue: $0) != nil }.compactMap(Modifier.init)
        let key = parts.dropFirst(modifiers.count).joined(separator: "-")
        guard !key.isEmpty, Set(modifiers).count == modifiers.count else { return nil }
        self.modifiers = Set(modifiers)
        self.key = key
    }
}
