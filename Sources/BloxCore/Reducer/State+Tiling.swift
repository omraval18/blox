import CoreGraphics

extension State {
    /// Frames for a workspace's tiled windows inside `area`, honouring learned size limits: the
    /// layout splits around them, then each frame is fitted to what its window will take.
    func tileFrames(_ workspace: Workspace, in area: CGRect) -> [CGRect] {
        let gaps = settings.gaps.smart && workspace.tiled.count == 1 ? Gaps() : settings.gaps
        let limits = workspace.tiled.map { sizeLimits[$0] ?? SizeLimits() }
        let tiles = Tiling.frames(
            workspace,
            in: area,
            gaps: gaps,
            limits: limits.map { $0.padded(by: gaps.inner) },
        )
        return zip(tiles, limits).map { tile, limit in limit.fitting(tile) }
    }
}
