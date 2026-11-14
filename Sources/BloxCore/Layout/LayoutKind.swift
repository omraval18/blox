public enum LayoutKind: String, Sendable, CaseIterable {
    case dwindle, tiles, primary, monocle

    var algorithm: any LayoutAlgorithm {
        switch self {
        case .dwindle: DwindleLayout()
        case .tiles: TilesLayout()
        case .primary: PrimaryLayout()
        case .monocle: MonocleLayout()
        }
    }
}
