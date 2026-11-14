import CoreGraphics

extension State {
    /// Frames for a workspace's tiled windows inside `area`, honouring learned minimum sizes.
    func tileFrames(_ workspace: Workspace, in area: CGRect) -> [CGRect] {
        let gaps = settings.gaps.smart && workspace.tiled.count == 1 ? Gaps() : settings.gaps
        let gap = gaps.inner
        let minimums = workspace.tiled.map { id in
            let size = minSizes[id] ?? .zero
            return size == .zero ? size : CGSize(width: size.width + gap, height: size.height + gap)
        }
        return Tiling.frames(workspace, in: area, gaps: gaps, minimums: minimums)
    }
}
