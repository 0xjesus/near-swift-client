// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NearQuickStart",
    platforms: [.macOS(.v11)],
    dependencies: [
        .package(path: "../../") // local root; when users consume, point to git URL
    ],
    targets: [
        .executableTarget(
            name: "NearQuickStart",
            dependencies: [
                .product(name: "NearJsonRpcClient", package: "near-swift-client"),
                .product(name: "NearJsonRpcTypes", package: "near-swift-client")
            ]
        )
    ]
)
