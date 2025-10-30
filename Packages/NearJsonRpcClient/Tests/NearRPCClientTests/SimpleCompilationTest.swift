// SimpleCompilationTest.swift
// File: Packages/NearJsonRpcClient/Tests/NearRPCClientTests/SimpleCompilationTest.swift
// Basic test to verify the client compiles and works

@testable import NearJsonRpcClient
import NearJsonRpcTypes
import OpenAPIRuntime
import XCTest

final class SimpleCompilationTest: XCTestCase {
    func testClientInitialization() {
        // Test that the client can be initialized
        let config = NearJsonRpcClient.Config(
            endpoint: URL(string: "https://rpc.testnet.near.org")!
        )
        let client = NearJsonRpcClient(config)

        XCTAssertNotNil(client)
    }

    func testBlockReferenceCreation() {
        // Test different ways to create block references

        // By finality
        let finalBlock = Components.Schemas.RpcBlockRequest.finality(.final)
        let optimisticBlock = Components.Schemas.RpcBlockRequest.finality(.optimistic)
        let nearFinalBlock = Components.Schemas.RpcBlockRequest.finality(.near_hyphen_final)

        // By height
        let blockByHeight = Components.Schemas.RpcBlockRequest.height(1_000_000)

        // By hash - CryptoHash is complex, skip for now
        // let blockByHash = Components.Schemas.RpcBlockRequest.hash("3KhAJAMwPPrJGKjsnYXnHtgTP5UXSVfQYUQSLjqkU6mp")

        // By sync checkpoint
        let genesisBlock = Components.Schemas.RpcBlockRequest.syncCheckpoint(.genesis)

        // Verify they're created
        XCTAssertNotNil(finalBlock)
        XCTAssertNotNil(optimisticBlock)
        XCTAssertNotNil(nearFinalBlock)
        XCTAssertNotNil(blockByHeight)
        XCTAssertNotNil(genesisBlock)
    }

    func testJsonRpcRequestCreation() {
        // Test that we can create a JSON-RPC request
        let blockRef = Components.Schemas.RpcBlockRequest.finality(.final)

        let request = Components.Schemas.JsonRpcRequest_for_block(
            id: "test-id",
            jsonrpc: "2.0",
            method: .block,
            params: blockRef
        )

        XCTAssertEqual(request.id, "test-id")
        XCTAssertEqual(request.jsonrpc, "2.0")
        XCTAssertEqual(request.method, .block)
    }
}

// MARK: - Integration Test (optional, requires network)

extension SimpleCompilationTest {
    func testActualRPCCall() async throws {
        // Skip if no network available
        guard ProcessInfo.processInfo.environment["ENABLE_INTEGRATION_TESTS"] == "true" else {
            throw XCTSkip("Integration tests disabled. Set ENABLE_INTEGRATION_TESTS=true to run")
        }

        let config = NearJsonRpcClient.Config(
            endpoint: URL(string: "https://rpc.testnet.near.org")!
        )
        let client = NearJsonRpcClient(config)
    }
}
