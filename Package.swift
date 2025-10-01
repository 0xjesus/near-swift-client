// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "near-swift-client",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(name: "NearJsonRpcClient", targets: ["NearJsonRpcClient"]),
        .library(name: "NearJsonRpcTypes", targets: ["NearJsonRpcTypes"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-http-types", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "NearJsonRpcTypes",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
            ],
            path: "Packages/NearJsonRpcTypes/Sources/NearJsonRpcTypes",
            // AÑADIR ESTA LÍNEA PARA ELIMINAR EL WARNING
            exclude: ["openapi.yaml"]
        ),
        .target(
            name: "NearJsonRpcClient",
            dependencies: [
                "NearJsonRpcTypes",
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
            ],
            path: "Packages/NearJsonRpcClient/Sources/NearJsonRpcClient",
            // AÑADIR ESTA LÍNEA PARA ELIMINAR EL WARNING
            exclude: ["openapi.yaml"]
        ),
        
        // --- Targets de Prueba ---
        .testTarget(
            name: "NearJsonRpcTypesTests",
            dependencies: ["NearJsonRpcTypes"],
            path: "Packages/NearJsonRpcTypes/Tests/NearRPCTypesTests"
        ),
        .testTarget(
            name: "NearJsonRpcClientTests",
            dependencies: ["NearJsonRpcClient"],
            path: "Packages/NearJsonRpcClient/Tests/NearRPCClientTests"
        ),
    ]
)