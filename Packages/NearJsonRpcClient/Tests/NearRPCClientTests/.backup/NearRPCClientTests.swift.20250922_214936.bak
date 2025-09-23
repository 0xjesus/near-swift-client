import XCTest
@testable import NearRPCClient
import NearRPCTypes
import OpenAPIRuntime
import HTTPTypes

// Transportador HTTP actualizado
actor HTTPTransport: ClientTransport {
    func send(_ request: HTTPRequest, body: OpenAPIRuntime.HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, OpenAPIRuntime.HTTPBody?) {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(request.path ?? ""))
        urlRequest.httpMethod = request.method.rawValue
        for header in request.headerFields {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.name.rawName)
        }
        if let body {
            urlRequest.httpBody = try await Data(collecting: body, upTo: .max)
        }
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpURLResponse = response as? HTTPURLResponse else {
            throw URLError(.cannotParseResponse)
        }
        var headerFields = HTTPFields()
        for (key, value) in httpURLResponse.allHeaderFields {
            guard let name = HTTPField.Name(String(describing: key)) else { continue }
            headerFields[name] = String(describing: value)
        }
        let httpResponse = HTTPResponse(status: .init(code: httpURLResponse.statusCode), headerFields: headerFields)
        return (httpResponse, data.isEmpty ? nil : .init(data))
    }
}

final class NearRPCClientTests: XCTestCase {
    func testFetchStatusFromTestnet() async throws {
        print("🧪 Iniciando prueba de integración final...")
        
        // CORRECCIÓN FINAL: Le decimos que Client está DENTRO de NearRPCTypes
        let client = NearRPCTypes.Client(
            transport: HTTPTransport()
        )
        
        print("📡 Llamando al método 'status' en la testnet...")
        
        let response = try await client.status(body: .json(.init(jsonrpc: "2.0", id: "dontcare", method: "status", params: .case1(["finality", "final"]))))

        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let statusResult):
                print("✅ ¡Respuesta recibida!")
                print("   - Chain ID: \(statusResult.result.chainId)")
                print("   - Último bloque: #\(statusResult.result.syncInfo.latestBlockHeight)")
                XCTAssertEqual(statusResult.result.chainId, "testnet")
            }
        case .badRequest, .internalServerError, .undocumented:
            XCTFail("La petición falló. Respuesta: \(response)")
        }
    }
}
