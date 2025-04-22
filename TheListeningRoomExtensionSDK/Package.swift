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
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
    ],
    targets: [
        .target(name: "TheListeningRoomExtensionSDK",
                dependencies: [
                    .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                ]),
        .testTarget(name: "TheListeningRoomExtensionSDKTests",
                    dependencies: [
                        "TheListeningRoomExtensionSDK",
                        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                    ]),
    ]
)
