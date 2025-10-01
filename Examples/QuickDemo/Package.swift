// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QuickDemo",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "QuickDemo",
            dependencies: [
                .product(name: "NearJsonRpcClient", package: "near-swift-client"),
                .product(name: "NearJsonRpcTypes", package: "near-swift-client")
            ]
        )
    ]
)
