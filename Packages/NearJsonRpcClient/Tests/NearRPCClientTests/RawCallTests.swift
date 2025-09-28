import XCTest
@testable import NearJsonRpcClient

final class RawCallTests: XCTestCase {

    private func makeClient() -> NearJsonRpcClient {
        let endpoint = URL(string: "http://example.local/ignored/path")!
        let cfg = NearJsonRpcClient.Config(endpoint: endpoint)
        let urlCfg = URLSessionConfiguration.ephemeral
        urlCfg.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: urlCfg)
        return NearJsonRpcClient(cfg, session: session)
    }

    func testRawCall_success_string() async throws {
        URLProtocolMock.handler = { req in
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            let body = #"{ "jsonrpc":"2.0", "id":"x", "result":"ok" }"#.data(using: .utf8)!
            return (resp, body)
        }
        let client = makeClient()
        let r: String = try await client.rawCall(method: "echo", params: ["p"])
        XCTAssertEqual(r, "ok")
    }

    func testRawCall_envelope_error() async {
        URLProtocolMock.handler = { req in
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            let body = #"{ "jsonrpc":"2.0", "id":"x", "error": { "code": -32000, "message": "boom" } }"#.data(using: .utf8)!
            return (resp, body)
        }
        let client = makeClient()
        await XCTAssertThrowsError(try await client.rawCall(method: "m", params: ["x"]) as String)
    }

    func testRawCall_missing_result() async {
        URLProtocolMock.handler = { req in
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            let body = #"{ "jsonrpc":"2.0", "id":"x" }"#.data(using: .utf8)!
            return (resp, body)
        }
        let client = makeClient()
        await XCTAssertThrowsError(try await client.rawCall(method: "m", params: []) as String)
    }

    func testRawCall_http_error() async {
        URLProtocolMock.handler = { req in
            let resp = HTTPURLResponse(url: req.url!, statusCode: 500, httpVersion: nil, headerFields: [:])!
            return (resp, Data())
        }
        let client = makeClient()
        await XCTAssertThrowsError(try await client.rawCall(method: "m", params: []) as String)
    }
}
