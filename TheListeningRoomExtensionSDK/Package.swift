// swift-tools-version:6.0.0
import PackageDescription

let package = Package(
    name: "TheListeningRoomExtensionSDK",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "TheListeningRoomExtensionSDK",
                 targets: ["TheListeningRoomExtensionSDK"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "TheListeningRoomExtensionSDK",
                dependencies: []),
        .testTarget(name: "TheListeningRoomExtensionSDKTests",
                    dependencies: ["TheListeningRoomExtensionSDK"]),
    ]
)
