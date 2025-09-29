@testable import NearJsonRpcTypes
import XCTest

final class RPCCompatCoverageTests: XCTestCase {
    func testRPCLiteral_object_array_roundtrip() throws {
        let lit: RPCLiteral = .object([
            "s": .string("a"),
            "b": .bool(true),
            "d": .double(1.5),
            "a": .array([.string("x"), .null]),
        ])
        let data = try JSONEncoder().encode(lit)
        let back = try JSONDecoder().decode(RPCLiteral.self, from: data)
        XCTAssertEqual(lit, back)
    }

    func testRPCParams_encode_object_and_array() throws {
        let p1: RPCParams = .object(["x": .string("y")])
        let d1 = try JSONEncoder().encode(p1)
        let o1 = try JSONSerialization.jsonObject(with: d1) as! [String: Any]
        XCTAssertEqual(o1["x"] as? String, "y")

        let p2: RPCParams = .array([.string("a"), .null, .bool(false)])
        let d2 = try JSONEncoder().encode(p2)
        let a2 = try JSONSerialization.jsonObject(with: d2) as! [Any]
        XCTAssertEqual(a2.count, 3)
    }

    func testRPCRequestID_encode_int_and_string() throws {
        let i: RPCRequestID = .int(7)
        let di = try JSONEncoder().encode(i)
        let vi = try JSONSerialization.jsonObject(with: di, options: [.fragmentsAllowed]) as! Int
        XCTAssertEqual(vi, 7)

        let s: RPCRequestID = .string("abc")
        let ds = try JSONEncoder().encode(s)
        let vs = try JSONSerialization.jsonObject(with: ds, options: [.fragmentsAllowed]) as! String
        XCTAssertEqual(vs, "abc")
    }

    func testRPCRequestEnvelope_encode_shape() throws {
        let env = RPCRequestEnvelope(id: .string("1"),
                                     method: "m",
                                     params: .object(["p": .string("v")]))
        let data = try JSONEncoder().encode(env)
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(obj["jsonrpc"] as? String, "2.0")
        XCTAssertEqual(obj["method"] as? String, "m")
        XCTAssertEqual(obj["id"] as? String, "1")
        let params = obj["params"] as! [String: Any]
        XCTAssertEqual(params["p"] as? String, "v")
    }

    func testRPCResponseEnvelope_success_and_failure() throws {
        // éxito con result como objeto
        let ok = RPCResponseEnvelope(jsonrpc: "2.0",
                                     id: .int(1),
                                     result: .object(["x": .string("v")]),
                                     error: nil)
        switch ok.result {
        case let .success(v):
            if case let .object(o) = v {
                XCTAssertEqual(o["x"], .some(.string("v")))
            } else {
                XCTFail("result no es object")
            }
        case .failure:
            XCTFail("no esperaba error")
        }

        // error
        let err = JSONRPCError(code: -32000, message: "oops", data: nil)
        let ko = RPCResponseEnvelope(jsonrpc: "2.0",
                                     id: .int(1),
                                     result: nil,
                                     error: err)
        switch ko.result {
        case .success:
            XCTFail("esperaba error")
        case let .failure(e):
            XCTAssertEqual(e.code, -32000)
            XCTAssertEqual(e.message, "oops")
        }
    }
}
