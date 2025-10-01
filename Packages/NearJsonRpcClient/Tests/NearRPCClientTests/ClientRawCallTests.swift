@testable import NearJsonRpcClient
@testable import NearJsonRpcTypes
import XCTest

final class ClientRawCallTests: XCTestCase {
    private func makeClient() -> NearJsonRpcClient {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: cfg)
        return NearJsonRpcClient(.init(endpoint: URL(string: "https://rpc.testnet.near.org")!), session: session)
    }

    func testRawCallWithParams() async throws {
        URLProtocolMock.handler = { req in
            let result = ["test": "value"]
            let out = ["jsonrpc": "2.0", "id": "1", "result": result]
            let body = try JSONSerialization.data(withJSONObject: out)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (resp, body)
        }
        struct Params: Encodable {
            let key: String
        }
        struct Result: Decodable {
            let test: String
        }
        let result: Result = try await makeClient().rawCall(method: "custom", params: Params(key: "value"))
        XCTAssertEqual(result.test, "value")
    }

    func testRawCallWithNilParams() async throws {
        URLProtocolMock.handler = { req in
            let result = ["data": 123]
            let out = ["jsonrpc": "2.0", "id": "1", "result": result]
            let body = try JSONSerialization.data(withJSONObject: out)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (resp, body)
        }
        struct Result: Decodable {
            let data: Int
        }
        let result: Result = try await makeClient().rawCall(method: "test", params: Optional<[String: String]>.none)
        XCTAssertEqual(result.data, 123)
    }
}
