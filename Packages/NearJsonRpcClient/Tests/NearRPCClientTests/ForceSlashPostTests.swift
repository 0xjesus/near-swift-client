import XCTest
@testable import NearJsonRpcClient

final class ForceSlashPostTests: XCTestCase {
    func testPostJsonForcesSlashAndMergesHeaders() async throws {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: cfg)

        URLProtocolMock.handler = { req in
            XCTAssertEqual(req.httpMethod, "POST")
            XCTAssertEqual(req.url?.path, "/")
            XCTAssertEqual(req.value(forHTTPHeaderField: "Accept"), "application/json")
            XCTAssertEqual(req.value(forHTTPHeaderField: "X-Custom"), "1")
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil,
                                       headerFields: ["Content-Type":"application/json"])!
            return (resp, Data(#"{"ok":true}"#.utf8))
        }

        let t = ForceSlashTransport(baseURL: URL(string: "https://rpc.testnet.near.org/whatever")!,
                                    session: session)
        _ = try await t.postJSON(body: Data("{}".utf8), headers: ["X-Custom":"1"])
    }
}
