import XCTest
@testable import NearJsonRpcTypes

final class RPCTypesEncodingDecodingTests: XCTestCase {

    private func decodeDict(_ data: Data) throws -> [String: Any] {
        try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    func testAccount_decodeLocked_then_encodeSnakeCase() throws {
        let json = """
        {
          "amount": "10",
          "locked": "5",
          "code_hash": "h",
          "storage_usage": 1,
          "storage_paid_at": 2,
          "block_height": 3,
          "block_hash": "bh"
        }
        """.data(using: .utf8)!
        let acc = try JSONDecoder().decode(Account.self, from: json)
        let obj = try decodeDict(try JSONEncoder().encode(acc))
        XCTAssertEqual(obj["amount"] as? String, "10")
        XCTAssertEqual(obj["locked_amount"] as? String, "5")
        XCTAssertEqual(obj["code_hash"] as? String, "h")
    }

    func testAccount_decode_without_locked_defaults_zero() throws {
        let json = """
        {
          "amount": "1",
          "code_hash": "h",
          "storage_usage": 0,
          "storage_paid_at": 0,
          "block_height": 0,
          "block_hash": "bh"
        }
        """.data(using: .utf8)!
        let acc = try JSONDecoder().decode(Account.self, from: json)
        let obj = try decodeDict(try JSONEncoder().encode(acc))
        XCTAssertEqual(obj["locked_amount"] as? String, "0")
    }

    func testBlockHeader_encode_snakeCase_and_decode_tolerant() throws {
        let header = BlockHeader(
            height: 1,
            epochId: "e",
            prevHash: "ph",
            prevStateRoot: "psr",
            timestamp: 0,
            timestampNanosec: "0",
            randomValue: "rv",
            gasPrice: "0",
            totalSupply: "0",
            challengesRoot: "cr"
        )
        // encode → snake_case
        let obj = try decodeDict(try JSONEncoder().encode(header))
        XCTAssertNotNil(obj["epoch_id"])
        XCTAssertNotNil(obj["prev_state_root"])
        XCTAssertNil(obj["epochId"])

        // decode tolerant (epoch_id)
        let json = #"{ "height":1, "epoch_id":"e", "prev_hash":"ph", "prev_state_root":"psr", "timestamp":0, "timestamp_nanosec":"0", "random_value":"rv", "gas_price":"0", "total_supply":"0", "challenges_root":"cr" }"#
        let back = try JSONDecoder().decode(BlockHeader.self, from: Data(json.utf8))
        XCTAssertEqual(back.epochId, "e")
    }

    func testChunkHeader_decode_snake_and_encode_snake() throws {
        let j = """
        {
          "chunk_hash":"ch",
          "prev_block_hash":"pbh",
          "height_created":10,
          "height_included":11,
          "shard_id":1,
          "gas_used":0,
          "gas_limit":0
        }
        """.data(using: .utf8)!
        let h = try JSONDecoder().decode(ChunkHeader.self, from: j)
        XCTAssertEqual(h.chunkHash, "ch")
        XCTAssertEqual(h.prevBlockHash, "pbh")

        let obj = try decodeDict(try JSONEncoder().encode(h))
        XCTAssertNotNil(obj["chunk_hash"])
        XCTAssertNotNil(obj["prev_block_hash"])
        XCTAssertNil(obj["prevBlockHash"])
    }

    func testJSONRPCError_encode_decode() throws {
        let e = JSONRPCError(code: -1, message: "m", data: AnyCodable("d"))
        let back = try JSONDecoder().decode(JSONRPCError.self, from: try JSONEncoder().encode(e))
        XCTAssertEqual(back.code, -1)
        XCTAssertEqual(back.message, "m")
    }
}
