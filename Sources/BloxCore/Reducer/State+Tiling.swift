import CoreGraphics

extension State {
    /// Frames for a workspace's tiled windows inside `area`, honouring learned minimum sizes.
    func tileFrames(_ workspace: Workspace, in area: CGRect) -> [CGRect] {
        let gap = settings.gaps.inner
        let minimums = workspace.tiled.map { id in
            let size = minSizes[id] ?? .zero
            return size == .zero ? size : CGSize(width: size.width + gap, height: size.height + gap)
        }
        return Tiling.frames(workspace, in: area, gaps: settings.gaps, minimums: minimums)
    }
}
