@testable import NearJsonRpcClient
@testable import NearJsonRpcTypes
import XCTest

final class RawCallTests: XCTestCase {
    // Envelope auxiliar SOLO para construir el body de respuesta en los mocks.
    // Debe ser Codable porque lo codificamos con JSONEncoder en los handlers.
    struct Out<T: Codable>: Codable {
        var jsonrpc: String = "2.0" // var para silenciar warning de decodificación
        var id: String = "x" // idem
        var result: T?
        var error: EncodableError?

        // Wrapper encodable del error (para no tocar JsonRpcErrorObject de producción).
        struct EncodableError: Codable {
            let code: Int
            let message: String
            let data: JSONValue?
        }

        init(result: T) {
            self.result = result
            error = nil
        }

        init(error: JsonRpcErrorObject) {
            result = nil
            self.error = EncodableError(code: error.code, message: error.message, data: error.data)
        }

        init() {
            result = nil
            error = nil
        }
    }

    func client() -> NearJsonRpcClient {
        let url = URL(string: "https://example.test")!
        let cfg = NearJsonRpcClient.Config(endpoint: url, headers: [:], timeout: 5)

        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.protocolClasses = [URLProtocolMock.self] // 👈 clave

        let session = URLSession(configuration: sessionConfig)
        return NearJsonRpcClient(cfg, session: session)
    }

    func ok(_ req: URLRequest, body: Data) -> (HTTPURLResponse, Data) {
        let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
        return (resp, body)
    }

    // MARK: - Tests

    func test_rawCall_success_returns_result() async throws {
        URLProtocolMock.handler = { req in
            // Envelope con result = 123
            let body = try JSONEncoder().encode(Out(result: 123))
            return self.ok(req, body: body)
        }

        let value: Int = try await client().rawCall(method: "m", params: [Int]())
        XCTAssertEqual(value, 123)
    }

    func test_rawCall_error_envelope_throws() async throws {
        URLProtocolMock.handler = { req in
            let err = JsonRpcErrorObject(code: -1, message: "boom", data: nil)
            let body = try JSONEncoder().encode(Out<Int>(error: err))
            return self.ok(req, body: body)
        }

        // No uses XCTAssertThrowsError con async; usa do/catch
        do {
            let _: Int = try await client().rawCall(method: "m", params: [Int]())
            XCTFail("Se esperaba throw por envelope con error")
        } catch {
            // OK
        }
    }

    func test_rawCall_missing_result_and_error_throws() async throws {
        URLProtocolMock.handler = { req in
            // ni result ni error
            let body = try JSONEncoder().encode(Out<Int>())
            return self.ok(req, body: body)
        }

        do {
            let _: Int = try await client().rawCall(method: "m", params: [Int]())
            XCTFail("Se esperaba throw por envelope sin result/error")
        } catch {
            // OK
        }
    }
}
