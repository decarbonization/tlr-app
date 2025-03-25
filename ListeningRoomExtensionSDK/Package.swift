// swift-tools-version:6.0.0
import PackageDescription

let package = Package(
    name: "ListeningRoomExtensionSDK",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ListeningRoomExtensionSDK",
                 targets: ["ListeningRoomExtensionSDK"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "ListeningRoomExtensionSDK",
                dependencies: []),
        .testTarget(name: "ListeningRoomExtensionSDKTests",
                    dependencies: ["ListeningRoomExtensionSDK"]),
    ]
)
