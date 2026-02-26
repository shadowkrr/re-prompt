// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "RePrompt",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "RePrompt",
            path: "Sources/RePrompt"
        )
    ]
)
