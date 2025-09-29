@testable import NearJsonRpcTypes
import XCTest

final class JSONValueCoverageTests: XCTestCase {
    func testJSONValueEncodeDecodePrimitivesAndContainers() throws {
        let original: JSONValue = .object([
            "s": .string("hello"),
            "n": .number(1.5),
            "b": .bool(true),
            "a": .array([.number(1), .null, .string("ok")]),
            "o": .object(["k": .string("v")]),
            "z": .null,
        ])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        XCTAssertEqual(decoded, original)
    }
}
