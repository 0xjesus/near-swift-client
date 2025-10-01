@testable import NearJsonRpcClient
@testable import NearJsonRpcTypes
import XCTest

final class SendCoreTests: XCTestCase {
    // Crea una sesión que fuerza a usar URLProtocolMock sólo para este test
    private func makeClient(base: URL) -> NearJsonRpcClient {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [URLProtocolMock.self] // <- aquí enchufamos el mock
        let session = URLSession(configuration: cfg)
        return NearJsonRpcClient(.init(endpoint: base), session: session)
    }

    func testSendSuccessDecodesAccount() async throws {
        // Respuesta JSON-RPC 2.0 con "result" que matchee Account
        URLProtocolMock.handler = { req in
            let ok = """
            {"jsonrpc":"2.0","id":"1","result":{
              "amount":"1",
              "locked_amount":"0",
              "code_hash":"11111111111111111111111111111111",
              "storage_usage":0,
              "storage_paid_at":0,
              "block_height":1,
              "block_hash":"22222222222222222222222222222222"
            }}
            """.data(using: .utf8)!
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200,
                                       httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (resp, ok)
        }
        defer { URLProtocolMock.handler = nil }

        let base = URL(string: "https://rpc.test.invalid/anything")!
        let client = makeClient(base: base)

        // Usa los params que tengas en NearJsonRpcTypes (String? o enum, según tu modelo real)
        let params = ViewAccountParams(accountId: "alice.testnet", finality: .optimistic)

        let account: Account = try await client.rawCall(method: "query", params: params, decode: Account.self)
        XCTAssertEqual(account.amount, "1")
    }

    func testSendServerErrorSurfaces() async {
        // JSON-RPC error (código de negocio), con HTTP 200 (comportamiento típico de JSON-RPC)
        URLProtocolMock.handler = { req in
            let err = """
            {"jsonrpc":"2.0","id":"1","error":{"code":-32000,"message":"boom"}}
            """.data(using: .utf8)!
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200,
                                       httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (resp, err)
        }
        defer { URLProtocolMock.handler = nil }

        let base = URL(string: "https://rpc.test.invalid/anything")!
        let client = makeClient(base: base)

        let params = ViewAccountParams(accountId: "alice.testnet")

        await XCTAssertAsyncThrowsError {
            try await client.rawCall(method: "query", params: params, decode: Account.self)
        }
    }

    // Helper async para asserts de errores en funciones async
    func XCTAssertAsyncThrowsError(
        _ expression: @escaping () async throws -> some Any,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath, line: UInt = #line,
        _ errorHandler: (Error) -> Void = { _ in }
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error. " + message(), file: file, line: line)
        } catch { errorHandler(error) }
    }
}
