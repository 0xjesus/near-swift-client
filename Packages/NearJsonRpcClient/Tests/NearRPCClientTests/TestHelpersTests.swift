@testable import NearJsonRpcClient
import NearJsonRpcTypes
import XCTest

final class TestHelpersTests: XCTestCase {
    func testJsonRpcErrorObjectInit() {
        let err = JsonRpcErrorObject(code: -32000, message: "Server error", data: .string("details"))
        XCTAssertEqual(err.code, -32000)
        XCTAssertEqual(err.message, "Server error")
        XCTAssertNotNil(err.data)
    }
    
    func testJsonRpcErrorObjectInitWithoutData() {
        let err = JsonRpcErrorObject(code: -32600, message: "Invalid request")
        XCTAssertEqual(err.code, -32600)
        XCTAssertEqual(err.message, "Invalid request")
        XCTAssertNil(err.data)
    }
    
    func testJsonRpcErrorObjectEncodeDecode() throws {
        let original = JsonRpcErrorObject(code: -32601, message: "Method not found", data: .object(["key": .string("value")]))
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JsonRpcErrorObject.self, from: encoded)
        XCTAssertEqual(decoded.code, original.code)
        XCTAssertEqual(decoded.message, original.message)
    }
}
