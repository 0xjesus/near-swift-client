// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NearJsonRpcTypes",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .watchOS(.v8),
        .tvOS(.v15),
    ],
    products: [
        .library(name: "NearJsonRpcTypes", targets: ["NearJsonRpcTypes"]),
    ],
    targets: [
        .target(
            name: "NearJsonRpcTypes",
            dependencies: []
        ),
        .testTarget(
            name: "NearJsonRpcTypesTests",
            dependencies: ["NearJsonRpcTypes"]
        ),
    ]
)
