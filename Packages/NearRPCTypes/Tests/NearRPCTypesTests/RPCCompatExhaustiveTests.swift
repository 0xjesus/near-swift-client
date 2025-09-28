import XCTest
@testable import NearJsonRpcTypes

final class RPCCompatExhaustiveTests: XCTestCase {
    func testRPCLiteralAllCasesRoundtrip() throws {
        let v: RPCLiteral = .object([
            "i": .int(1),
            "s": .string("x"),
            "b": .bool(true),
            "d": .double(1.5),
            "a": .array([.null, .string("y")]),
            "z": .null
        ])
        let data = try JSONEncoder().encode(v)
        let back = try JSONDecoder().decode(RPCLiteral.self, from: data)
        XCTAssertEqual(back, v)
    }

    func testRPCParamsObjectAndArrayRoundtrip() throws {
        let o: RPCParams = .object(["k": .string("v")])
        let a: RPCParams = .array([.int(1), .string("2")])
        XCTAssertTrue(String(data: try JSONEncoder().encode(o), encoding: .utf8)!.hasPrefix("{"))
        XCTAssertTrue(String(data: try JSONEncoder().encode(a), encoding: .utf8)!.hasPrefix("["))
    }

    func testRPCEnvelopesSuccessAndError() throws {
        let ok = RPCResponseEnvelope(jsonrpc: "2.0", id: .int(1), result: .string("ok"), error: nil)
        let okData = try JSONEncoder().encode(ok)
        let okBack = try JSONDecoder().decode(RPCResponseEnvelope.self, from: okData)
        if case .success(let r) = okBack.result { XCTAssertEqual(r, .string("ok")) } else { XCTFail() }

        let err = RPCError(code: -32000, message: "boom", data: nil)
        let er = RPCResponseEnvelope(jsonrpc: "2.0", id: .string("1"), result: nil, error: err)
        let erData = try JSONEncoder().encode(er)
        let erBack = try JSONDecoder().decode(RPCResponseEnvelope.self, from: erData)
        if case .failure(let e) = erBack.result { XCTAssertEqual(e.code, -32000) } else { XCTFail() }
    }
}
