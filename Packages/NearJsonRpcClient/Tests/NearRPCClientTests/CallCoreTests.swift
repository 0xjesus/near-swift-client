@testable import NearJsonRpcClient
@testable import NearJsonRpcTypes
import XCTest

final class CallCoreTests: XCTestCase {
    private func makeClient(_ base: URL) -> NearJsonRpcClient {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: cfg)
        return NearJsonRpcClient(.init(endpoint: base, headers: ["X-Test": "1"], timeout: 5),
                                 session: session)
    }

    // Router JSON-RPC para los tests
    private func router(_ builder: @escaping (_ method: String, _ params: Any?) throws -> Any) {
        URLProtocolMock.handler = { req in
            // Asegura POST "/" + headers
            XCTAssertEqual(req.httpMethod, "POST")
            XCTAssertEqual(URLComponents(url: req.url!, resolvingAgainstBaseURL: false)?.path, "/")
            XCTAssertEqual(req.value(forHTTPHeaderField: "Accept"), "application/json")

            let body = try XCTUnwrap(req.httpBody)
            let obj = try JSONSerialization.jsonObject(with: body) as! [String: Any]
            let method = obj["method"] as! String
            let params = obj["params"]
            let result = try builder(method, params)

            let out: [String: Any] = ["jsonrpc": "2.0", "id": obj["id"] ?? "1", "result": result]
            let data = try JSONSerialization.data(withJSONObject: out)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!
            return (resp, data)
        }
    }

    func testCallSuccessAndHeadersAndSlash() async throws {
        let base = URL(string: "https://rpc.testnet.near.org/ignored/path")!
        let client = makeClient(base)

        router { method, params in
            switch method {
            case "block":
                // BlockView (= Block) requiere header completo + 1 chunk minimal
                return [
                    "author": "alice.testnet",
                    "header": [
                        "height": 1, "epoch_id": "e", "prev_hash": "h", "prev_state_root": "sr",
                        "timestamp": 0, "timestamp_nanosec": "0", "random_value": "r",
                        "gas_price": "0", "total_supply": "0", "challenges_root": "cr",
                    ],
                    "chunks": [[
                        "chunk_hash": "ch", "prev_block_hash": "pb",
                        "height_created": 1, "height_included": 1, "shard_id": 0,
                        "gas_used": 0, "gas_limit": 0,
                    ]],
                ]
            case "chunk": return [:] // ChunkView: todo opcional
            case "validators": return [:] // EpochValidatorInfo opcional
            case "query":
                guard let p = params as? [String: Any], let rt = p["request_type"] as? String else { return [:] }
                switch rt {
                case "view_account": return [:] // ViewAccountResult: todos opcionales
                case "view_state": return ["values": []] // requiere 'values'
                case "view_code": return ["code_base64": "", "hash": "h"] // campos requeridos
                default: return [:]
                }
            case "changes": return ["changes": []] // requerido
            case "EXPERIMENTAL_genesis_config": return ["protocol_version": 1]
            case "EXPERIMENTAL_protocol_config": return [:]
            case "send_tx": return [:]
            case "broadcast_tx_async": return "0xHASH"
            case "broadcast_tx_commit": return [:]
            case "tx": return [:]
            case "EXPERIMENTAL_light_client_proof": return [:]
            case "next_light_client_block": return ["hash": "x", "prev_hash": "y"]
            default: return [:]
            }
        }

        // Ejecuta TODAS las wrappers (líneas cubiertas)
        _ = try await client.block(.init(finality: .final))
        _ = try await client.chunk(.init(chunkId: "ch"))
        _ = try await client.validators(.current)
        _ = try await client.validators(.byEpochId("abc"))

        _ = try await client.viewAccount(.init(accountId: "alice.testnet", finality: .optimistic))
        _ = try await client.viewState(.init(accountId: "alice", finality: .final, prefixBase64: ""))
        _ = try await client.viewCode(.init(accountId: "alice", finality: .final))
        _ = try await client.accountChanges(.init(accountIds: ["alice"], finality: .final))

        _ = try await client.getGenesisConfig()
        _ = try await client.getProtocolConfig(.init(finality: .final))

        _ = try await client.sendTransaction(.init(signedTxBase64: "AA==", waitUntil: .executedOptimistic))
        _ = try await client.broadcastTxAsync(base64: "AA==")
        _ = try await client.broadcastTxCommit(base64: "AA==")
        _ = try await client.txStatus(.init(txHash: "0x", senderAccountId: "alice", waitUntil: .final))

        _ = try await client.lightClientProof(.transaction(txHash: "h", senderId: "alice", head: "head"))
        _ = try await client.nextLightClientBlock(lastKnownHash: nil)
        _ = try await client.nextLightClientBlock(lastKnownHash: "prev")
    }

    func testCallServerErrorObject() async {
        URLProtocolMock.handler = { req in
            let out = #"{ "jsonrpc":"2.0","id":"1","error":{"code":-32000,"message":"boom"} }"#.data(using: .utf8)!
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!
            return (resp, out)
        }
        let client = makeClient(URL(string: "https://rpc.testnet.near.org")!)
        await XCTAssertAsyncThrowsError {
            struct Dummy: Decodable {}
            let _: Dummy = try await client.call(method: "status", params: Int?.none)
        }
    }

    func testCallHttpErrorSurfaces() async {
        URLProtocolMock.handler = { req in
            let resp = HTTPURLResponse(url: req.url!, statusCode: 500, httpVersion: nil, headerFields: [:])!
            return (resp, Data())
        }
        let client = makeClient(URL(string: "https://rpc.mainnet.near.org/foo")!)
        await XCTAssertAsyncThrowsError {
            struct Dummy: Decodable {}
            let _: Dummy = try await client.call(method: "status", params: Int?.none)
        }
    }

    func testCallInvalidJson() async {
        URLProtocolMock.handler = { req in
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (resp, Data("not json".utf8))
        }
        let client = makeClient(URL(string: "https://rpc.mainnet.near.org")!)
        await XCTAssertAsyncThrowsError {
            struct Dummy: Decodable {}
            let _: Dummy = try await client.call(method: "status", params: Int?.none)
        }
    }

    // Helper async para asserts
    func XCTAssertAsyncThrowsError(
        _ expression: @escaping () async throws -> some Any,
        file: StaticString = #filePath, line: UInt = #line
    ) async {
        do { _ = try await expression(); XCTFail("Expected error", file: file, line: line) }
        catch { /* ok */ }
    }
}
