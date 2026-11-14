import Foundation

/// Waits for the Accessibility permission to be granted, so a fresh install or a rebuilt binary
/// (which macOS treats as a new app) starts working without a relaunch. Event-driven: the system
/// posts a notification whenever any app's trust changes.
@MainActor
public final class AccessibilityGrantWatcher {
    private var token: (any NSObjectProtocol)?

    public init(onGrant: @escaping @MainActor () -> Void) {
        token = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("com.apple.accessibility.api"),
            object: nil,
            queue: .main,
        ) { [weak self] _ in
            Task { @MainActor in
                // The notification can arrive a moment before the new trust is visible.
                try? await Task.sleep(for: .milliseconds(500))
                self?.finishIfGranted(onGrant)
            }
        }
    }

    private func finishIfGranted(_ onGrant: @MainActor () -> Void) {
        guard AccessibilityPermission.isGranted, let token else { return }
        DistributedNotificationCenter.default().removeObserver(token)
        self.token = nil
        onGrant()
    }
}
