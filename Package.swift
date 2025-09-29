// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "near-swift-client",
    platforms: [.iOS(.v14), .macOS(.v11)],
    products: [
        .library(name: "NearJsonRpcTypes", targets: ["NearJsonRpcTypes"]),
        .library(name: "NearJsonRpcClient", targets: ["NearJsonRpcClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "NearJsonRpcTypes",
            path: "Packages/NearJsonRpcTypes/Sources"
        ),
        .target(
            name: "NearJsonRpcClient",
            dependencies: ["NearJsonRpcTypes"],
            path: "Packages/NearJsonRpcClient/Sources"
        ),
        .testTarget(
            name: "NearJsonRpcTypesTests",
            dependencies: ["NearJsonRpcTypes"],
            path: "Packages/NearJsonRpcTypes/Tests"
        ),
        .testTarget(
            name: "NearJsonRpcClientTests",
            dependencies: ["NearJsonRpcClient", "NearJsonRpcTypes"],
            path: "Packages/NearJsonRpcClient/Tests"
        ),
    ]
)
