// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "LlamaBar",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(name: "LlamaBar"),
        .testTarget(name: "LlamaBarTests", dependencies: ["LlamaBar"]),
    ],
    swiftLanguageModes: [.v5]
)
