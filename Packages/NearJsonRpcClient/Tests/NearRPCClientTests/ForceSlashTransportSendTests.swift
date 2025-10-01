@testable import NearJsonRpcClient
import XCTest
import OpenAPIRuntime
import HTTPTypes

final class ForceSlashTransportSendTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        URLProtocol.registerClass(URLProtocolMock.self)
    }

    override class func tearDown() {
        URLProtocol.unregisterClass(URLProtocolMock.self)
        super.tearDown()
    }

    func testSendMethodForcesSlash() async throws {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: cfg)
        
        let transport = ForceSlashTransport(
            baseURL: URL(string: "https://rpc.testnet.near.org/some/path")!,
            session: session
        )
        
        URLProtocolMock.handler = { req in
            XCTAssertEqual(req.url?.path, "/")
            XCTAssertEqual(req.httpMethod, "POST")
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (resp, Data(#"{"ok":true}"#.utf8))
        }
        
        var request = HTTPRequest(method: .post, scheme: "https", authority: "rpc.testnet.near.org", path: "/ignored")
        let body = HTTPBody(Data(#"{"test":"data"}"#.utf8))
        
        let (response, _) = try await transport.send(request, body: body, baseURL: URL(string: "https://rpc.testnet.near.org")!, operationID: "test")
        
        XCTAssertEqual(response.status.code, 200)
    }
}
