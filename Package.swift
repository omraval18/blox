// swift-tools-version: 6.2

import PackageDescription

let strict: [SwiftSetting] = [
    .strictMemorySafety(),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .treatAllWarnings(as: .error),
]

let package = Package(
    name: "Blox",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "blox", targets: ["BloxCLI"]),
        .executable(name: "BloxApp", targets: ["BloxApp"]),
    ],
    targets: [
        // Pure logic. Must never import AppKit/ApplicationServices (see .swiftlint.yml).
        .target(name: "BloxCore", swiftSettings: strict),
        // The only place that touches the OS: AX, hotkeys, displays, overlays.
        .target(name: "BloxPlatform", dependencies: ["BloxCore"], swiftSettings: strict),
        // Wire protocol shared by the app and the CLI.
        .target(name: "BloxIPC", swiftSettings: strict),
        // Composition root. Wires adapters into the core; contains no logic.
        .executableTarget(
            name: "BloxApp",
            dependencies: ["BloxCore", "BloxPlatform", "BloxIPC"],
            swiftSettings: strict,
        ),
        .executableTarget(name: "BloxCLI", dependencies: ["BloxIPC"], swiftSettings: strict),
        .testTarget(name: "BloxCoreTests", dependencies: ["BloxCore"], swiftSettings: strict),
    ],
)
