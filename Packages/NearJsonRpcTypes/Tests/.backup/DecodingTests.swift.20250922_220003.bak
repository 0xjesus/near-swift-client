import XCTest
@testable import NearJsonRpcTypes

final class DecodingTests: XCTestCase {
    func testExecutionStatus() throws {
        let json = #"{"SuccessValue": "abcd"}"#.data(using: .utf8)!
        let s = try JSONDecoder().decode(ExecutionStatus.self, from: json)
        if case .successValue(let v) = s {
            XCTAssertEqual(v, "abcd")
        } else {
            XCTFail("Expected SuccessValue")
        }
    }

    func testBlockViewMinimal() throws {
        let json = #"{"header":{"height":123,"hash":"H"},"author":"node2","chunks":[]}"#.data(using:.utf8)!
        let b = try JSONDecoder().decode(BlockView.self, from: json)
        XCTAssertEqual(b.header?.height, 123)
        XCTAssertEqual(b.author, "node2")
    }
}
