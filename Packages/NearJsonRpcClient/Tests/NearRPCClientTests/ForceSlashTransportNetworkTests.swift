import XCTest
@testable import NearJsonRpcClient

final class ForceSlashTransportNetworkTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        URLProtocol.registerClass(URLProtocolMock.self)
    }
    override class func tearDown() {
        URLProtocol.unregisterClass(URLProtocolMock.self)
        super.tearDown()
    }

    func test_postJSON_forces_root_and_sets_headers() async throws {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: cfg)

        let t = ForceSlashTransport(baseURL: URL(string: "https://rpc.mainnet.near.org/some/path")!, session: session)

        URLProtocolMock.handler = { req in
            XCTAssertEqual(URLComponents(url: req.url!, resolvingAgainstBaseURL: false)?.path, "/")
            XCTAssertEqual(req.httpMethod, "POST")
            XCTAssertEqual(req.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(req.value(forHTTPHeaderField: "Accept"), "application/json")
            let ok = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"application/json"])!
            return (ok, Data(#"{"jsonrpc":"2.0","id":1,"result":"ok"}"#.utf8))
        }

        _ = try await t.postJSON(body: Data("{}".utf8))
    }
}
