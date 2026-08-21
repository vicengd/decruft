// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Decruft",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Decruft",
            path: "Sources/Decruft"
        )
    ]
)
