public enum LayoutKind: String, Sendable, CaseIterable {
    case dwindle, primary, monocle

    var algorithm: any LayoutAlgorithm {
        switch self {
        case .dwindle: DwindleLayout()
        case .primary: PrimaryLayout()
        case .monocle: MonocleLayout()
        }
    }
}
