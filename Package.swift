// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Escoba",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Escoba",
            path: "Sources/Escoba"
        )
    ]
)
