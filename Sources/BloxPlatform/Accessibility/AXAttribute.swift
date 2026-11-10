import ApplicationServices

/// Typed access to Accessibility attributes. The only place that calls the AX C API for values.
enum AXAttribute {
    static func value(_ element: AXUIElement, _ attribute: String) -> CFTypeRef? {
        var result: CFTypeRef?
        let status = unsafe AXUIElementCopyAttributeValue(element, attribute as CFString, &result)
        return status == .success ? result : nil
    }

    static func string(_ element: AXUIElement, _ attribute: String) -> String? {
        value(element, attribute) as? String
    }

    /// Missing or non-boolean attributes read as false.
    static func flag(_ element: AXUIElement, _ attribute: String) -> Bool {
        value(element, attribute) as? Bool ?? false
    }

    static func element(_ element: AXUIElement, _ attribute: String) -> AXUIElement? {
        guard let raw = value(element, attribute),
              CFGetTypeID(raw) == AXUIElementGetTypeID() else { return nil }
        return unsafe unsafeDowncast(raw, to: AXUIElement.self)
    }

    static func elements(_ element: AXUIElement, _ attribute: String) -> [AXUIElement] {
        value(element, attribute) as? [AXUIElement] ?? []
    }

    private static func axValue(_ element: AXUIElement, _ attribute: String) -> AXValue? {
        guard let raw = value(element, attribute), CFGetTypeID(raw) == AXValueGetTypeID() else { return nil }
        return unsafe unsafeDowncast(raw, to: AXValue.self)
    }

    static func point(_ element: AXUIElement, _ attribute: String) -> CGPoint? {
        var result = CGPoint.zero
        guard let ax = axValue(element, attribute),
              unsafe AXValueGetValue(ax, .cgPoint, &result) else { return nil }
        return result
    }

    static func size(_ element: AXUIElement, _ attribute: String) -> CGSize? {
        var result = CGSize.zero
        guard let ax = axValue(element, attribute),
              unsafe AXValueGetValue(ax, .cgSize, &result) else { return nil }
        return result
    }

    @discardableResult
    static func set(_ element: AXUIElement, _ attribute: String, point: CGPoint) -> Bool {
        var point = point
        guard let ax = unsafe AXValueCreate(.cgPoint, &point) else { return false }
        return AXUIElementSetAttributeValue(element, attribute as CFString, ax) == .success
    }

    @discardableResult
    static func set(_ element: AXUIElement, _ attribute: String, size: CGSize) -> Bool {
        var size = size
        guard let ax = unsafe AXValueCreate(.cgSize, &size) else { return false }
        return AXUIElementSetAttributeValue(element, attribute as CFString, ax) == .success
    }

    @discardableResult
    static func set(_ element: AXUIElement, _ attribute: String, bool: Bool) -> Bool {
        AXUIElementSetAttributeValue(element, attribute as CFString, bool as CFBoolean) == .success
    }

    static func isSettable(_ element: AXUIElement, _ attribute: String) -> Bool {
        var settable: DarwinBoolean = false
        let status = unsafe AXUIElementIsAttributeSettable(element, attribute as CFString, &settable)
        return status == .success && settable.boolValue
    }
}
