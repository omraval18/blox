@testable import BloxCore
import CoreGraphics

/// Weighted random commands over a small universe, so collisions (same window, same workspace) are common.
enum RandomCommand {
    typealias Maker = @Sendable (inout SplitMix64) -> Command

    static let apps = ["", "term", "float", "chat"]
    static let workspaces = ["1", "2", "3", "a"]

    static let allMonitors = [
        Monitor(id: 1, frame: CGRect(x: 0, y: 0, width: 1000, height: 800)),
        Monitor(id: 2, frame: CGRect(x: 1000, y: 0, width: 800, height: 600)),
        Monitor(id: 3, frame: CGRect(x: -900, y: 0, width: 900, height: 700)),
    ]

    static var rules: [String: WindowRule] {
        ["float": WindowRule(floating: true), "chat": WindowRule(workspace: "2")]
    }

    static func next(using rng: inout SplitMix64) -> Command {
        let maker = makers.randomElement(using: &rng)
        return maker?(&rng) ?? .retile
    }

    static func pick<T>(_ items: [T], _ rng: inout SplitMix64) -> T {
        items[Int(rng.next() % UInt64(items.count))]
    }

    private static func window(_ rng: inout SplitMix64) -> WindowID {
        WindowID(UInt32(rng.next() % 8) + 1)
    }

    private static func monitors(_ rng: inout SplitMix64) -> [Monitor] {
        let count = Int(rng.next() % 4)
        return Array(allMonitors.shuffled(using: &rng).prefix(count))
    }

    private static func settings(_ rng: inout SplitMix64) -> Settings {
        var result = Settings()
        result.rules = rules
        result.gaps = Gaps(inner: pick([0, 8, 18], &rng), outer: pick([0, 6], &rng))
        result.defaultLayout = pick(LayoutKind.allCases, &rng)
        return result
    }

    private static let makers: [Maker] = [
        { .windowAppeared(window(&$0), app: pick(apps, &$0)) },
        { .windowAppeared(window(&$0), app: pick(apps, &$0)) },
        { .windowAppeared(window(&$0), app: pick(apps, &$0)) },
        { .windowDisappeared(window(&$0)) },
        { .focusChanged(window(&$0)) },
        { .windowSizeLimits(
            window(&$0),
            SizeLimits(minimum: CGSize(
                width: 100 + Double($0.next() % 600),
                height: 100 + Double($0.next() % 500),
            )),
        ) },
        { .windowSizeLimits(
            window(&$0),
            SizeLimits(maximum: CGSize(width: 200 + Double($0.next() % 900), height: 0)),
        ) },
        { .monitorsChanged(monitors(&$0)) },
        { .focus(pick(Direction.allCases, &$0)) },
        { .focus(pick(Direction.allCases, &$0)) },
        { .move(pick(Direction.allCases, &$0)) },
        { .move(pick(Direction.allCases, &$0)) },
        { .switchWorkspace(pick(workspaces, &$0)) },
        { .switchWorkspace(pick(workspaces, &$0)) },
        { .moveToWorkspace(pick(workspaces, &$0)) },
        { _ in .workspaceBackAndForth },
        { _ in .moveWorkspaceToMonitor },
        { .setLayout(pick(LayoutKind.allCases, &$0)) },
        { .resize(pick([-1, -0.3, -0.05, 0.05, 0.3, 1], &$0)) },
        { _ in .balance },
        { _ in .toggleFloating },
        { _ in .toggleFullscreen },
        { _ in .retile },
        { .updateSettings(settings(&$0)) },
    ]
}
