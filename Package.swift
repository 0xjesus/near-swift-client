// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "near-swift-sdk",
    platforms: [.macOS(.v12), .iOS(.v15)],
    products: [
        .library(name: "NearRPCTypes", targets: ["NearRPCTypes"]),
        .library(name: "NearRPCClient", targets: ["NearRPCClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "NearRPCTypes",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")
            ],
            path: "Packages/NearRPCTypes/Sources/NearRPCTypes",
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .target(
            name: "NearRPCClient",
            dependencies: ["NearRPCTypes"],
            path: "Packages/NearRPCClient/Sources/NearRPCClient"
        ),
        // --- CORRECCIÓN FINAL ---
        // Le decimos a la prueba que también depende directamente de NearRPCTypes
        .testTarget(
            name: "NearRPCClientTests",
            dependencies: ["NearRPCClient", "NearRPCTypes"],
            path: "Packages/NearRPCClient/Tests/NearRPCClientTests"
        )
    ]
)
