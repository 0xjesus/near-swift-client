// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NearJsonRpcClient",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .watchOS(.v8),
        .tvOS(.v15),
    ],
    products: [
        .library(name: "NearJsonRpcClient", targets: ["NearJsonRpcClient"]),
    ],
    dependencies: [
        .package(path: "../NearJsonRpcTypes"),
    ],
    targets: [
        .target(
            name: "NearJsonRpcClient",
            dependencies: ["NearJsonRpcTypes"]
        ),
        .testTarget(
            name: "NearJsonRpcClientTests",
            dependencies: ["NearJsonRpcClient"]
        ),
    ]
)
