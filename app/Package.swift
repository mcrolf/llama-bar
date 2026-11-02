// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "LlamaBar",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.10.1"),
    ],
    targets: [
        .executableTarget(
            name: "LlamaBar",
            dependencies: [.product(name: "Sparkle", package: "Sparkle")],
            // bin/build-app puts Sparkle.framework in Contents/Frameworks.
            linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]
        ),
        .testTarget(name: "LlamaBarTests", dependencies: ["LlamaBar"]),
    ],
    swiftLanguageModes: [.v5]
)
