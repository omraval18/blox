enum WorkspaceOrder {
    /// Numbers in numeric order, then names alphabetically: 1 2 ... 10 A B.
    static func precedes(_ first: String, _ second: String) -> Bool {
        switch (Int(first), Int(second)) {
        case let (low?, high?): low < high
        case (_?, nil): true
        case (nil, _?): false
        case (nil, nil): first < second
        }
    }
}
