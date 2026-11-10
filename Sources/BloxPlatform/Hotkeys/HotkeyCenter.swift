import BloxCore
import Carbon

/// Global hotkeys through Carbon's RegisterEventHotKey: delivered by the system only when a
/// registered chord is pressed, with no event tap and no Input Monitoring permission.
@MainActor
public final class HotkeyCenter {
    fileprivate let onHotkey: @MainActor (Int) -> Void
    /// Bit patterns of the Carbon `EventHotKeyRef` handles, so no unsafe type is stored.
    private var registered: [Int] = []

    public init(onHotkey: @escaping @MainActor (Int) -> Void) {
        self.onHotkey = onHotkey
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed),
        )
        let context = unsafe Unmanaged.passUnretained(self).toOpaque()
        unsafe InstallEventHandler(GetApplicationEventTarget(), hotkeyHandler, 1, &eventType, context, nil)
    }

    /// Replaces all registrations. Binding `index` refers to the position in `chords`.
    /// Returns the chords the system refused (already taken by another app, or unknown key).
    @discardableResult
    public func register(_ chords: [Chord]) -> [Chord] {
        for handle in registered {
            if let reference = unsafe OpaquePointer(bitPattern: handle) {
                unsafe _ = UnregisterEventHotKey(reference)
            }
        }
        registered = []
        return chords.enumerated().compactMap { index, chord in
            register(chord, id: UInt32(index)) ? nil : chord
        }
    }

    private func register(_ chord: Chord, id: UInt32) -> Bool {
        guard let code = KeyCodes.code(for: chord.key) else { return false }
        var reference: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x424C_4F58), id: id)
        let status = unsafe RegisterEventHotKey(
            code, KeyCodes.carbonModifiers(chord.modifiers), hotKeyID, GetApplicationEventTarget(), 0,
            &reference,
        )
        guard status == noErr, let reference = unsafe reference else { return false }
        registered.append(Int(bitPattern: reference))
        return true
    }
}

private func hotkeyHandler(
    _: EventHandlerCallRef?,
    _ event: EventRef?,
    _ context: UnsafeMutableRawPointer?,
) -> OSStatus {
    var hotKeyID = EventHotKeyID()
    let size = MemoryLayout<EventHotKeyID>.size
    let status = unsafe GetEventParameter(
        event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, size, nil,
        &hotKeyID,
    )
    guard status == noErr, let context = unsafe context else { return OSStatus(eventNotHandledErr) }
    let center = unsafe Unmanaged<HotkeyCenter>.fromOpaque(context).takeUnretainedValue()
    let index = Int(hotKeyID.id)
    MainActor.assumeIsolated { center.onHotkey(index) }
    return noErr
}
