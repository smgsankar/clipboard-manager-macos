// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ClipboardManager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ClipboardManager",
            targets: ["ClipboardManager"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ClipboardManager",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("ServiceManagement"),
                .linkedLibrary("sqlite3")
            ]
        ),
        .testTarget(
            name: "ClipboardManagerTests",
            dependencies: ["ClipboardManager"]
        )
    ]
)
