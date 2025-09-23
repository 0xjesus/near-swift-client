import XCTest
@testable import NearJsonRpcTypes

final class CaseConversionTests: XCTestCase {
    struct Snake: Codable, Equatable {
        let block_hash: String
        let epoch_id: String
    }
    struct Camel: Codable, Equatable {
        let blockHash: String
        let epochId: String
    }

    func testSnakeToCamelDecoding() throws {
        let json = #"{"block_hash":"abc","epoch_id":"def"}"#
        let data = Data(json.utf8)
        let dec = NearJSONDecoder()
        let obj = try dec.decode(Camel.self, from: data)
        XCTAssertEqual(obj.blockHash, "abc")
        XCTAssertEqual(obj.epochId, "def")
    }

    func testCamelToSnakeEncoding() throws {
        let obj = Camel(blockHash: "abc", epochId: "def")
        let enc = NearJSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        let data = try enc.encode(obj)
        let out = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(out.contains(#""block_hash":"abc""#))
        XCTAssertTrue(out.contains(#""epoch_id":"def""#))
    }
}
