@testable import NearJsonRpcTypes
import XCTest

final class BasicTypesRoundtripTests: XCTestCase {
    func testRequestIdIntRoundtrip() throws {
        let id: RPCRequestID = .int(42)
        let enc = try JSONEncoder().encode(id)
        let dec = try JSONDecoder().decode(RPCRequestID.self, from: enc)
        if case let .int(v) = dec {
            XCTAssertEqual(v, 42)
        } else {
            XCTFail("Expected .int case")
        }
    }

    func testRequestIdStringRoundtrip() throws {
        let id: RPCRequestID = .string("abc")
        let enc = try JSONEncoder().encode(id)
        let dec = try JSONDecoder().decode(RPCRequestID.self, from: enc)
        if case let .string(v) = dec {
            XCTAssertEqual(v, "abc")
        } else {
            XCTFail("Expected .string case")
        }
    }
}
