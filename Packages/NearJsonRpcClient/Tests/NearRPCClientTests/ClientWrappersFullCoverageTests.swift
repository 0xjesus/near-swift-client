@testable import NearJsonRpcClient
@testable import NearJsonRpcTypes
import XCTest

final class ClientWrappersFullCoverageTests: XCTestCase {
    private func makeClient() -> NearJsonRpcClient {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: cfg)
        return NearJsonRpcClient(.init(endpoint: URL(string: "https://rpc.testnet.near.org")!), session: session)
    }

    func testBroadcastTxAsyncCoverage() async throws {
        URLProtocolMock.handler = { req in
            let out = ["jsonrpc": "2.0", "id": "1", "result": "0xTXHASH"]
            let body = try JSONSerialization.data(withJSONObject: out)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (resp, body)
        }
        let hash = try await makeClient().broadcastTxAsync(base64: "AA==")
        XCTAssertEqual(hash, "0xTXHASH")
    }

    func testBroadcastTxCommitCoverage() async throws {
        URLProtocolMock.handler = { req in
            let result: [String: Any] = ["status": [:], "transaction": [:], "transaction_outcome": [:], "receipts_outcome": []]
            let out = ["jsonrpc": "2.0", "id": "1", "result": result]
            let body = try JSONSerialization.data(withJSONObject: out)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (resp, body)
        }
        _ = try await makeClient().broadcastTxCommit(base64: "AA==")
    }

    func testGenesisConfigCoverage() async throws {
        URLProtocolMock.handler = { req in
            let out = ["jsonrpc": "2.0", "id": "1", "result": ["protocol_version": 1]]
            let body = try JSONSerialization.data(withJSONObject: out)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (resp, body)
        }
        _ = try await makeClient().getGenesisConfig()
    }

    func testNextLightClientBlockNilCoverage() async throws {
        URLProtocolMock.handler = { req in
            let result = ["inner_lite": [:], "inner_rest_hash": "h", "prev_block_hash": "p"]
            let out = ["jsonrpc": "2.0", "id": "1", "result": result]
            let body = try JSONSerialization.data(withJSONObject: out)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (resp, body)
        }
        _ = try await makeClient().nextLightClientBlock(lastKnownHash: nil)
    }

    func testNextLightClientBlockWithHashCoverage() async throws {
        URLProtocolMock.handler = { req in
            let out = ["jsonrpc": "2.0", "id": "1", "result": NSNull()]
            let body = try JSONSerialization.data(withJSONObject: out)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (resp, body)
        }
        let result = try await makeClient().nextLightClientBlock(lastKnownHash: "hash")
        XCTAssertNil(result)
    }

    func testHTTPErrorHandling() async throws {
        URLProtocolMock.handler = { req in
            let resp = HTTPURLResponse(url: req.url!, statusCode: 500, httpVersion: nil, headerFields: [:])!
            return (resp, Data())
        }
        do {
            _ = try await makeClient().getGenesisConfig()
            XCTFail("Expected error")
        } catch {
            // Expected HTTP error
        }
    }

    func testJSONRPCErrorHandling() async throws {
        URLProtocolMock.handler = { req in
            let err = ["jsonrpc": "2.0", "id": "1", "error": ["code": -32000, "message": "Server error"]]
            let body = try JSONSerialization.data(withJSONObject: err)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (resp, body)
        }
        do {
            _ = try await makeClient().broadcastTxAsync(base64: "AA==")
            XCTFail("Expected error")
        } catch {
            // Expected JSON-RPC error
        }
    }

    func testStatusCoverage() async throws {
        URLProtocolMock.handler = { req in
            let result = ["version": ["version": "1.0", "build": "abc"], "chain_id": "testnet"]
            let out = ["jsonrpc": "2.0", "id": "1", "result": result]
            let body = try JSONSerialization.data(withJSONObject: out)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (resp, body)
        }
        _ = try await makeClient().status()
    }

    func testNetworkInfoCoverage() async throws {
        URLProtocolMock.handler = { req in
            let result = ["active_peers": [], "num_active_peers": 0, "peer_max_count": 40]
            let out = ["jsonrpc": "2.0", "id": "1", "result": result]
            let body = try JSONSerialization.data(withJSONObject: out)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (resp, body)
        }
        _ = try await makeClient().networkInfo()
    }

    func testGasPriceDefaultCoverage() async throws {
        URLProtocolMock.handler = { req in
            let result = ["gas_price": "100000000"]
            let out = ["jsonrpc": "2.0", "id": "1", "result": result]
            let body = try JSONSerialization.data(withJSONObject: out)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (resp, body)
        }
        _ = try await makeClient().gasPrice()
    }

    func testCallMethodGenericCoverage() async throws {
        URLProtocolMock.handler = { req in
            let result = ["test": "value"]
            let out = ["jsonrpc": "2.0", "id": "1", "result": result]
            let body = try JSONSerialization.data(withJSONObject: out)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (resp, body)
        }
        struct TestResult: Decodable {
            let test: String
        }
        let result: TestResult = try await makeClient().call(method: "test_method", params: ["key": "value"])
        XCTAssertEqual(result.test, "value")
    }

    func testCallMethodWithNilParamsCoverage() async throws {
        URLProtocolMock.handler = { req in
            let result = ["data": "response"]
            let out = ["jsonrpc": "2.0", "id": "1", "result": result]
            let body = try JSONSerialization.data(withJSONObject: out)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (resp, body)
        }
        struct Response: Decodable {
            let data: String
        }
        let _: Response = try await makeClient().call(method: "no_params_method", params: [String: String]?.none)
    }

    func testBlockCoverage() async throws {
        URLProtocolMock.handler = { req in
            let result: [String: Any] = [
                "author": "alice.near",
                "header": [
                    "height": 100,
                    "epoch_id": "epoch123",
                    "prev_hash": "prev123",
                    "prev_state_root": "state123",
                    "timestamp": 1_000_000,
                    "timestamp_nanosec": "1000000000",
                    "random_value": "random123",
                    "gas_price": "100000000",
                    "total_supply": "1000000000000000000000000",
                    "challenges_root": "challenges123",
                ],
                "chunks": [],
            ]
            let out = ["jsonrpc": "2.0", "id": "1", "result": result]
            let body = try JSONSerialization.data(withJSONObject: out)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (resp, body)
        }
        let params = Components.Schemas.RpcBlockRequest.case2(.init(finality: .final))
        _ = try await makeClient().block(params)
    }

    func testChunkCoverage() async throws {
        URLProtocolMock.handler = { req in
            let result = ["header": [:]]
            let out = ["jsonrpc": "2.0", "id": "1", "result": result]
            let body = try JSONSerialization.data(withJSONObject: out)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (resp, body)
        }
        let params = Components.Schemas.RpcChunkRequest(value2: .init(chunk_id: "ABC123"))
        _ = try await makeClient().chunk(params)
    }

    func testAccountChangesCoverage() async throws {
        URLProtocolMock.handler = { req in
            let result = ["block_hash": "hash", "changes": []]
            let out = ["jsonrpc": "2.0", "id": "1", "result": result]
            let body = try JSONSerialization.data(withJSONObject: out)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (resp, body)
        }
        let blockId = Components.Schemas.BlockId(value1: 100)
        let value1 = Components.Schemas.RpcStateChangesInBlockByTypeRequest.Case1Payload.Value1Payload(block_id: blockId)
        let value2 = Components.Schemas.RpcStateChangesInBlockByTypeRequest.Case1Payload.Value2Payload(
            account_ids: ["alice"],
            changes_type: .account_changes
        )
        let params = Components.Schemas.RpcStateChangesInBlockByTypeRequest.case1(.init(value1: value1, value2: value2))
        _ = try await makeClient().accountChanges(params)
    }
}
