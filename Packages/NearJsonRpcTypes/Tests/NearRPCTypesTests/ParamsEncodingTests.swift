@testable import NearJsonRpcTypes
import XCTest

final class ParamsEncodingTests: XCTestCase {
    func testObjectParamsEncode() throws {
        let params: RPCParams = .object(["key": .string("value")])
        let data = try JSONEncoder().encode(params)
        let out = String(data: data, encoding: .utf8)!
        // Formato mínimo válido
        XCTAssertTrue(out.contains(#""key":"value""#))
        XCTAssertTrue(out.hasPrefix("{"))
    }

    func testArrayParamsEncode() throws {
        let params: RPCParams = .array([.int(1), .string("two")])
        let data = try JSONEncoder().encode(params)
        let out = String(data: data, encoding: .utf8)!
        XCTAssertTrue(out.contains(#"[1,"two"]"#))
        XCTAssertTrue(out.hasPrefix("["))
    }
}
