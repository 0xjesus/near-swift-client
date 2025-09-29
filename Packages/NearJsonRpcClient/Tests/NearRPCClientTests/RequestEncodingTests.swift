@testable import NearJsonRpcClient
import XCTest

/// Tests around the ForceSlashTransport testing helper:
/// - ensures POST "/"
/// - ensures JSON headers are merged/set
final class RequestEncodingTests: XCTestCase {
    func testDefaultHeadersAndSlashPath() throws {
        let base = URL(string: "https://rpc.testnet.near.org/some/path")!
        let transport = ForceSlashTransport(baseURL: base)

        // Body can be anything; we only validate it's set on the request.
        let body = #"{"jsonrpc":"2.0","id":1,"method":"status","params":[]}"#.data(using: .utf8)!
        let (_, req) = try transport.makeURLRequest(path: "/status", body: body, headers: [:])

        XCTAssertEqual(req.httpMethod, "POST")
        XCTAssertEqual(req.url?.path, "/") // must force slash regardless of input
        XCTAssertEqual(req.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(req.httpBody, body)
    }

    func testHeaderOverridesPreserved() throws {
        let base = URL(string: "https://rpc.mainnet.near.org")!
        let transport = ForceSlashTransport(baseURL: base)

        let body = Data("{}".utf8)
        let custom = [
            "Content-Type": "application/json; charset=utf-8",
            "Accept": "application/json, text/plain",
        ]
        let (_, req) = try transport.makeURLRequest(path: "/ignored", body: body, headers: custom)

        XCTAssertEqual(req.url?.path, "/")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Content-Type"), "application/json; charset=utf-8")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Accept"), "application/json, text/plain")
    }
}
