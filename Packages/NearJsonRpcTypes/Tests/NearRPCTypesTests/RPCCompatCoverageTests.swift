import XCTest
@testable import NearJsonRpcTypes

final class RPCCompatCoverageTests: XCTestCase {

    func testRPCLiteralCodableAllVariants() throws {
        let values: [RPCLiteral] = [
            .int(1),
            .bool(true),
            .double(3.14),
            .string("s"),
            .array([.int(2), .string("x"), .null]),
            .object(["k": .int(3), "arr": .array([.bool(false)])]),
            .null
        ]
        let enc = JSONEncoder(), dec = JSONDecoder()
        for v in values {
            let data = try enc.encode(v)
            let back = try dec.decode(RPCLiteral.self, from: data)
            XCTAssertEqual(back, v)
        }
    }

    func testRPCParamsObjectAndArray() throws {
        let obj = RPCParams.object(["a": .int(1), "b": .string("x")])
        let arr = RPCParams.array([.int(1), .string("y")])
        let enc = JSONEncoder(), dec = JSONDecoder()
        XCTAssertEqual(try dec.decode(RPCParams.self, from: try enc.encode(obj)), obj)
        XCTAssertEqual(try dec.decode(RPCParams.self, from: try enc.encode(arr)), arr)
    }

    func testRPCRequestEnvelopeRoundtrip_IntId() throws {
        let env = RPCRequestEnvelope(id: .int(42), method: "method", params: .object(["k": .string("v")]))
        let data = try JSONEncoder().encode(env)
        let back = try JSONDecoder().decode(RPCRequestEnvelope.self, from: data)
        XCTAssertEqual(back.id, .int(42))
        guard case .object(let o) = back.params else { return XCTFail() }
        XCTAssertEqual(o["k"], .string("v"))
    }

    func testRPCRequestEnvelopeRoundtrip_StringId() throws {
        let env = RPCRequestEnvelope(id: .string("abc"), method: "m", params: .array([.int(1), .bool(true)]))
        let data = try JSONEncoder().encode(env)
        let back = try JSONDecoder().decode(RPCRequestEnvelope.self, from: data)
        XCTAssertEqual(back.id, .string("abc"))
        guard case .array(let a) = back.params, a.count == 2 else { return XCTFail() }
    }

    func testRPCResponseEnvelope_SuccessAndError() throws {
        // success
        let okJSON = #"{ "jsonrpc":"2.0", "id": 1, "result": { "x": 1 } }"#
        let ok = try JSONDecoder().decode(RPCResponseEnvelope.self, from: Data(okJSON.utf8))
        switch ok.result {
        case .success(let v):
            if case .object(let o) = v {
                XCTAssertNotNil(o["x"])
            } else { XCTFail() }
        case .failure:
            XCTFail()
        }

        // error
        let errJSON = #"{ "jsonrpc":"2.0", "id": "1", "error": { "code": -32000, "message": "boom" } }"#
        let bad = try JSONDecoder().decode(RPCResponseEnvelope.self, from: Data(errJSON.utf8))
        switch bad.result {
        case .success: XCTFail()
        case .failure(let e):
            XCTAssertEqual(e.code, -32000)
            XCTAssertEqual(e.message, "boom")
        }
    }
}
