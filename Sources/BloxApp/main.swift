import BloxPlatform
import Foundation

guard AccessibilityPermission.isGranted else {
    FileHandle.standardError.write(Data("Accessibility permission is required.\n".utf8))
    exit(1)
}
