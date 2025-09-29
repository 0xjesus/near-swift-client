import NearJsonRpcTypes
import XCTest

/// Minimal JSON-RPC error envelope decoding to validate error shape.
/// This test is intentionally module-agnostic and does not depend on internal types.
final class RPCEnvelopeErrorTests: XCTestCase {
    // Simple union to handle both string and numeric ids in JSON-RPC
    enum RPCId: Codable, Equatable {
        case string(String)
        case int(Int)

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let i = try? c.decode(Int.self) { self = .int(i); return }
            if let s = try? c.decode(String.self) { self = .string(s); return }
            throw DecodingError.typeMismatch(
                RPCId.self,
                .init(codingPath: decoder.codingPath, debugDescription: "RPC id must be int or string")
            )
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.singleValueContainer()
            switch self {
            case let .int(i): try c.encode(i)
            case let .string(s): try c.encode(s)
            }
        }
    }

    struct RPCErrorObj: Codable, Equatable {
        let code: Int
        let message: String
        let data: String?
    }

    struct RPCEnvelope<Result: Decodable>: Decodable {
        let jsonrpc: String
        let id: RPCId?
        let result: Result?
        let error: RPCErrorObj?
    }

    func testDecodeErrorEnvelope() throws {
        let json = """
        {
          "jsonrpc": "2.0",
          "id": "test-id",
          "error": {
            "code": -32000,
            "message": "Server error",
            "data": "something went wrong"
          }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        // The library uses camelCase in Swift; this matches common strategy.
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let env = try decoder.decode(RPCEnvelope<EmptyResult>.self, from: json)
        XCTAssertEqual(env.jsonrpc, "2.0")
        XCTAssertNil(env.result)
        XCTAssertNotNil(env.error)
        XCTAssertEqual(env.error?.code, -32000)
        XCTAssertEqual(env.error?.message, "Server error")
        XCTAssertEqual(env.error?.data, "something went wrong")
    }

    // Marker for "no result" envelopes
    struct EmptyResult: Codable {}
}
