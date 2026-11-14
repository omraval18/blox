import BloxCore
import CoreGraphics

/// Where windows start and end for the animated transitions: a workspace switch and a new window.
extension WindowSystem {
    /// An outgoing window's destination just past the edge of its screen.
    func slideOut(from frame: CGRect) -> (frame: CGRect, timing: Timing)? {
        guard let travel = slideTravel(for: frame),
              let timing = settings.animation.timing(of: settings.animation.workspaces)
        else { return nil }
        return (frame.offsetBy(dx: travel.dx, dy: travel.dy), timing)
    }

    /// An incoming window starts just past the edge opposite to where the outgoing ones left.
    func slideIn(to frame: CGRect) -> (start: CGRect, timing: Timing)? {
        guard let travel = slideTravel(for: frame),
              let timing = settings.animation.timing(of: settings.animation.workspaces)
        else { return nil }
        return (frame.offsetBy(dx: -travel.dx, dy: -travel.dy), timing)
    }

    func entrance(to frame: CGRect) -> (start: CGRect, timing: Timing)? {
        guard let start = settings.animation.open.style.startFrame(for: frame),
              let timing = settings.animation.timing(of: settings.animation.open) else { return nil }
        return (start, timing)
    }

    private func slideTravel(for frame: CGRect) -> CGVector? {
        guard let travel = slide,
              let exit = settings.animation.workspaces.style.exit(for: travel) else { return nil }
        let size = Displays.screenSize(containing: frame)
        return exit.offset(exit == .left || exit == .right ? size.width : size.height)
    }
}
