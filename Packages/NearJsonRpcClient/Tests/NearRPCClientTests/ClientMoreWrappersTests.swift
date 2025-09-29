@testable import NearJsonRpcClient
@testable import NearJsonRpcTypes
import XCTest

final class ClientMoreWrappersTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        URLProtocol.registerClass(URLProtocolMock.self)
    }

    override class func tearDown() {
        URLProtocol.unregisterClass(URLProtocolMock.self)
        super.tearDown()
    }

    private func makeClient(base: URL) -> NearJsonRpcClient {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: cfg)
        return NearJsonRpcClient(.init(endpoint: base), session: session)
    }

    func testValidatorsCurrentEncodesNull() async throws {
        let base = URL(string: "https://rpc.test.invalid")!
        let client = makeClient(base: base)

        URLProtocolMock.handler = { req in
            let body = try XCTUnwrap(req.httpBody)
            let obj = try JSONSerialization.jsonObject(with: body) as! [String: Any]
            let arr = obj["params"] as? [Any]
            XCTAssertEqual(arr?.count, 1)
            XCTAssertTrue(arr?.first is NSNull)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            let out = #"{"jsonrpc":"2.0","id":"1","result":{"currentValidators":[]}}"#.data(using: .utf8)!
            return (resp, out)
        }

        _ = try await client.validators(.current) as EpochValidatorInfo
    }

    func testNextLightClientBlock_withHash_and_withoutHash() async throws {
        let base = URL(string: "https://rpc.test.invalid")!
        let client = makeClient(base: base)

        // Con hash
        URLProtocolMock.handler = { req in
            let body = try XCTUnwrap(req.httpBody)
            let obj = try JSONSerialization.jsonObject(with: body) as! [String: Any]
            let params = obj["params"] as? [Any]
            XCTAssertEqual((params?.first as? String), "H")
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            let out = #"{"jsonrpc":"2.0","id":"1","result":{"hash":"aa","prev_hash":"bb"}}"#.data(using: .utf8)!
            return (resp, out)
        }
        let a = try await client.nextLightClientBlock(lastKnownHash: "H")
        XCTAssertEqual(a?.hash, "aa")

        // Sin hash (params: [])
        URLProtocolMock.handler = { req in
            let body = try XCTUnwrap(req.httpBody)
            let obj = try JSONSerialization.jsonObject(with: body) as! [String: Any]
            let params = obj["params"] as? [Any]
            XCTAssertEqual(params?.count, 0)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            let out = #"{"jsonrpc":"2.0","id":"1","result":{"hash":"cc","prev_hash":"dd"}}"#.data(using: .utf8)!
            return (resp, out)
        }
        let b = try await client.nextLightClientBlock(lastKnownHash: nil)
        XCTAssertEqual(b?.prevHash, "dd")
    }

    func testBroadcastLegacyAndProtocolConfig() async throws {
        let base = URL(string: "https://rpc.test.invalid")!
        let client = makeClient(base: base)

        // broadcast_tx_async
        URLProtocolMock.handler = { req in
            let body = try XCTUnwrap(req.httpBody)
            let obj = try JSONSerialization.jsonObject(with: body) as! [String: Any]
            XCTAssertEqual(obj["method"] as? String, "broadcast_tx_async")
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            let out = #"{"jsonrpc":"2.0","id":"1","result":"HASH"}"#.data(using: .utf8)!
            return (resp, out)
        }
        let hash: String = try await client.broadcastTxAsync(base64: "BASE64")
        XCTAssertEqual(hash, "HASH")

        // broadcast_tx_commit
        URLProtocolMock.handler = { req in
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            let out = #"{"jsonrpc":"2.0","id":"1","result":{"status":null}}"#.data(using: .utf8)!
            return (resp, out)
        }
        _ = try await client.broadcastTxCommit(base64: "BASE64") as FinalExecutionOutcome

        // EXPERIMENTAL_protocol_config
        URLProtocolMock.handler = { req in
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            let out = #"{"jsonrpc":"2.0","id":"1","result":{"min_gas_price":"0"}}"#.data(using: .utf8)!
            return (resp, out)
        }
        _ = try await client.getProtocolConfig(.init(finality: .final)) as ProtocolConfig
    }
}
