import XCTest
@testable import NearJsonRpcClient
@testable import NearJsonRpcTypes

final class ClientWrapperCallTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        URLProtocol.registerClass(URLProtocolMock.self)
    }
    override class func tearDown() {
        URLProtocol.unregisterClass(URLProtocolMock.self)
        super.tearDown()
    }

    func testHappyPathMocked() async throws {
        let base = URL(string: "https://rpc.testnet.near.org")!

        URLProtocolMock.handler = { req in
            // El transporte debe forzar path "/"
            XCTAssertEqual(URLComponents(url: req.url!, resolvingAgainstBaseURL: false)?.path, "/")
            let body = #"{"jsonrpc":"2.0","id":"1","result":{"ok":true}}"#.data(using: .utf8)!
            let resp = HTTPURLResponse(
                url: req.url!, statusCode: 200, httpVersion: nil,
                headerFields: ["Content-Type":"application/json"]
            )!
            return (resp, body)
        }

        // Inicializador correcto del cliente (Config)
        let client = NearJsonRpcClient(.init(endpoint: base))
        _ = client

        // TODO: cuando agregues un wrapper real (p.ej. gasPrice), invócalo aquí.
        // let out = try await client.gasPrice(params: BlockParams(...))
        // XCTAssertTrue(out.ok)
    }

    func testServerErrorMocked() async throws {
        let base = URL(string: "https://rpc.testnet.near.org")!

        URLProtocolMock.handler = { req in
            let body = #"{"jsonrpc":"2.0","id":"1","error":{"code":-32000,"message":"boom"}}"#.data(using: .utf8)!
            let resp = HTTPURLResponse(
                url: req.url!, statusCode: 200, httpVersion: nil,
                headerFields: ["Content-Type":"application/json"]
            )!
            return (resp, body)
        }

        let client = NearJsonRpcClient(.init(endpoint: base))
        _ = client

        // TODO: cuando haya wrapper público, valida que lance error:
        // await XCTAssertThrowsError(try await client.gasPrice(params: ...))
    }
}
