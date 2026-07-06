// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Bottler",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Bottler",
            path: "Sources/Bottler"
        )
    ]
)
