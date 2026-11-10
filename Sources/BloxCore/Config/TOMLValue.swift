enum TOMLValue: Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    var number: Double? {
        switch self {
        case let .int(value): Double(value)
        case let .double(value): value
        default: nil
        }
    }

    var string: String? {
        if case let .string(value) = self {
            value
        } else {
            nil
        }
    }
}
