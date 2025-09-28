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

    func testBlockHeader_encode_snakeCase() throws {
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
        let obj = try decodeDict(try JSONEncoder().encode(header))
        XCTAssertNotNil(obj["epoch_id"])
        XCTAssertNotNil(obj["prev_state_root"])
        XCTAssertNil(obj["epochId"])
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

    func testFunctionCallRequest_encode_and_result_decode() throws {
        let req = FunctionCallRequest(
            accountId: "acc",
            methodName: "m",
            argsBase64: "AA==",
            finality: "optimistic"
        )
        let dict = try decodeDict(try JSONEncoder().encode(req))
        XCTAssertEqual(dict["request_type"] as? String, "call_function")
        XCTAssertEqual(dict["args_base64"] as? String, "AA==")

        let resultJSON = #"{ "result":[1,2], "logs":["l"], "block_height":1, "block_hash":"bh" }"#
        let res = try JSONDecoder().decode(FunctionCallResult.self, from: Data(resultJSON.utf8))
        XCTAssertEqual(res.result, [1,2])
        XCTAssertEqual(res.logs, ["l"])
    }

    func testTxStatusRequest_encode() throws {
        let req = TxStatusRequest(txHash: "th", senderId: "sid")
        let dict = try decodeDict(try JSONEncoder().encode(req))
        XCTAssertEqual(dict["tx_hash"] as? String, "th")
        XCTAssertEqual(dict["sender_id"] as? String, "sid")
    }

    func testBlockRequest_encode() throws {
        let r1 = BlockRequest(finality: "final", blockId: nil)
        var d = try decodeDict(try JSONEncoder().encode(r1))
        XCTAssertEqual(d["finality"] as? String, "final")
        XCTAssertNil(d["block_id"])

        let r2 = BlockRequest(finality: nil, blockId: 5)
        d = try decodeDict(try JSONEncoder().encode(r2))
        XCTAssertEqual(d["block_id"] as? Int, 5)
        XCTAssertNil(d["finality"])
    }

    func testAnyCodable_decode_and_encode() throws {
        _ = try JSONEncoder().encode(AnyCodable(1))
        _ = try JSONEncoder().encode(AnyCodable("x"))
        _ = try JSONEncoder().encode(AnyCodable(true))
        _ = try JSONEncoder().encode(AnyCodable(1.5))
        _ = try JSONEncoder().encode(AnyCodable(NSNull()))
        let j = #"{ "i":1, "s":"x", "b":true, "d":1.5, "a":[1,2], "o":{"k":"v"} }"#
        _ = try JSONDecoder().decode([String: AnyCodable].self, from: Data(j.utf8))
    }

    func testJSONRPCError_encode_decode() throws {
        let e = JSONRPCError(code: -1, message: "m", data: AnyCodable("d"))
        let back = try JSONDecoder().decode(JSONRPCError.self, from: try JSONEncoder().encode(e))
        XCTAssertEqual(back.code, -1)
        XCTAssertEqual(back.message, "m")
    }
}
