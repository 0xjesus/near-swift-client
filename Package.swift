// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "near-swift-sdk",
    platforms: [.iOS(.v14), .macOS(.v11)],
    products: [
        .library(name: "NearJsonRpcTypes", targets: ["NearJsonRpcTypes"]),
        .library(name: "NearJsonRpcClient", targets: ["NearJsonRpcClient"]),
    ],
    dependencies: [
        // Opcional para pruebas de concurrencia/async, pero Swift estándar basta
    ],
    targets: [
        .target(
            name: "NearJsonRpcTypes",
            path: "Packages/NearJsonRpcTypes/Sources",
            resources: []
        ),
        .target(
            name: "NearJsonRpcClient",
            dependencies: ["NearJsonRpcTypes"],
            path: "Packages/NearJsonRpcClient/Sources",
            resources: []
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
