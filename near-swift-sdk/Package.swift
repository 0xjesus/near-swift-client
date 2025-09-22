// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "near-swift-sdk",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
        .macCatalyst(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces
        .library(
            name: "NearRPCTypes",
            targets: ["NearRPCTypes"]),
        .library(
            name: "NearRPCClient",
            targets: ["NearRPCClient"]),
    ],
    dependencies: [
        // OpenAPI Generator and Runtime
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.0"),
        
        // Additional dependencies for testing
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        // Types target - contains generated code only
        .target(
            name: "NearRPCTypes",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")
            ],
            path: "Sources/NearRPCTypes",
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        
        // Client target - depends on types
        .target(
            name: "NearRPCClient",
            dependencies: [
                "NearRPCTypes",
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession")
            ],
            path: "Sources/NearRPCClient"
        ),
        
        // Test targets
        .testTarget(
            name: "NearRPCTypesTests",
            dependencies: ["NearRPCTypes"],
            path: "Tests/NearRPCTypesTests"
        ),
        .testTarget(
            name: "NearRPCClientTests",
            dependencies: ["NearRPCClient"],
            path: "Tests/NearRPCClientTests",
            resources: [.process("Resources")]
        ),
    ]
)
