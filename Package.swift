// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LimpiaNodeModules",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "LimpiaNodeModules",
            path: "Sources/LimpiaNodeModules"
        )
    ]
)
