import XCTest
@testable import NearJsonRpcTypes

final class BasicTypesRoundtripTests: XCTestCase {

    func testRequestIdIntRoundtrip() throws {
        let id: RPCRequestID = .int(42)
        let enc = try JSONEncoder().encode(id)
        let dec = try JSONDecoder().decode(RPCRequestID.self, from: enc)
        if case .int(let v) = dec {
            XCTAssertEqual(v, 42)
        } else {
            XCTFail("Expected .int case")
        }
    }

    func testRequestIdStringRoundtrip() throws {
        let id: RPCRequestID = .string("abc")
        let enc = try JSONEncoder().encode(id)
        let dec = try JSONDecoder().decode(RPCRequestID.self, from: enc)
        if case .string(let v) = dec {
            XCTAssertEqual(v, "abc")
        } else {
            XCTFail("Expected .string case")
        }
    }
}
