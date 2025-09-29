import NearJsonRpcTypes
import XCTest

/// Decoding samples to exercise snake_case → camelCase across nested structures.
/// These are minimal fixtures (not full protocol responses) to keep the test robust.
final class DecodingFixturesTests: XCTestCase {
    struct BlockHeader: Codable, Equatable {
        let height: Int
        let epochId: String
        let hash: String
    }

    struct Block: Codable, Equatable {
        let author: String
        let header: BlockHeader
    }

    func testDecodeBlockLikeStructure() throws {
        let json = """
        {
          "author": "node.pool.near",
          "header": {
            "height": 123456,
            "epoch_id": "9hJm...abc",
            "hash": "6N5L...xyz"
          }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let blk = try decoder.decode(Block.self, from: json)
        XCTAssertEqual(blk.author, "node.pool.near")
        XCTAssertEqual(blk.header.height, 123_456)
        XCTAssertEqual(blk.header.epochId, "9hJm...abc")
        XCTAssertEqual(blk.header.hash, "6N5L...xyz")
    }

    struct GasPrice: Codable, Equatable {
        let gasPrice: String
    }

    func testDecodeGasPriceLikeStructure() throws {
        let json = """
        { "gas_price": "100000000" }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let gp = try decoder.decode(GasPrice.self, from: json)
        XCTAssertEqual(gp.gasPrice, "100000000")
    }
}
