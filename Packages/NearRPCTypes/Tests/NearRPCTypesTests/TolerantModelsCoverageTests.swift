import XCTest
@testable import NearJsonRpcTypes

final class TolerantModelsCoverageTests: XCTestCase {

    private func decode<T: Decodable>(_ json: String, as type: T.Type) throws -> T {
        let data = Data(json.utf8)
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        return try dec.decode(T.self, from: data)
    }

    private func encodeJSON<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        return try JSONSerialization.jsonObject(with: data) as! [String: Any]
    }

    func testAccount_decode_locked_amount_locked_lockedAmount() throws {
        let j1 = #"{"amount":"1","locked_amount":"0","code_hash":"c","storage_usage":0,"storage_paid_at":1,"block_height":2,"block_hash":"h"}"#
        _ = try decode(j1, as: Account.self)

        let j2 = #"{"amount":"1","locked":"0","code_hash":"c","storage_usage":0,"storage_paid_at":1,"block_height":2,"block_hash":"h"}"#
        _ = try decode(j2, as: Account.self)

        let j3 = #"{"amount":"1","lockedAmount":"0","code_hash":"c","storage_usage":0,"storage_paid_at":1,"block_height":2,"block_hash":"h"}"#
        _ = try decode(j3, as: Account.self)
    }

    func testAccount_encode_uses_snake_case() throws {
        let j = #"{"amount":"1","lockedAmount":"0","code_hash":"c","storage_usage":0,"storage_paid_at":1,"block_height":2,"block_hash":"h"}"#
        let acc = try decode(j, as: Account.self)
        let obj = try encodeJSON(acc)
        XCTAssertNotNil(obj["locked_amount"])
        XCTAssertNil(obj["lockedAmount"])
    }

    func testBlockHeader_decode_epochId_and_epoch_id() throws {
        let camel = #"{"height":1,"epochId":"e","prev_hash":"ph","prev_state_root":"psr","timestamp":123,"timestamp_nanosec":"123000000","random_value":"rv","gas_price":"0","total_supply":"1","challenges_root":"cr"}"#
        _ = try decode(camel, as: BlockHeader.self)

        let snake = #"{"height":1,"epoch_id":"e","prev_hash":"ph","prev_state_root":"psr","timestamp":123,"timestamp_nanosec":"123000000","random_value":"rv","gas_price":"0","total_supply":"1","challenges_root":"cr"}"#
        _ = try decode(snake, as: BlockHeader.self)
    }

    func testBlockHeader_encode_uses_snake_case() throws {
        let camel = #"{"height":1,"epochId":"e","prev_hash":"ph","prev_state_root":"psr","timestamp":123,"timestamp_nanosec":"123000000","random_value":"rv","gas_price":"0","total_supply":"1","challenges_root":"cr"}"#
        let header = try decode(camel, as: BlockHeader.self)
        let obj = try encodeJSON(header)
        XCTAssertNotNil(obj["epoch_id"])
        XCTAssertNil(obj["epochId"])
        XCTAssertNotNil(obj["prev_hash"])
        XCTAssertNotNil(obj["prev_state_root"])
        XCTAssertNotNil(obj["timestamp_nanosec"])
    }

    func testBlock_and_ChunkHeader_roundtrip() throws {
        let blockJSON = #"""
        {
          "author":"alice.near",
          "header":{
            "height":10,"epochId":"e",
            "prev_hash":"ph","prev_state_root":"psr",
            "timestamp":123,"timestamp_nanosec":"123000000",
            "random_value":"rv","gas_price":"0","total_supply":"1","challenges_root":"cr"
          },
          "chunks":[
            {
              "chunk_hash":"ch","prev_block_hash":"pbh",
              "height_created":10,"height_included":10,
              "shard_id":0,"gas_used":0,"gas_limit":0
            }
          ]
        }
        """#
        let b = try decode(blockJSON, as: Block.self)
        XCTAssertEqual(b.chunks.count, 1)
        let obj = try encodeJSON(b.chunks[0])
        XCTAssertNotNil(obj["chunk_hash"])
        XCTAssertNotNil(obj["prev_block_hash"])
        XCTAssertNotNil(obj["height_created"])
        XCTAssertNotNil(obj["height_included"])
        XCTAssertNotNil(obj["shard_id"])
        XCTAssertNotNil(obj["gas_used"])
        XCTAssertNotNil(obj["gas_limit"])
    }

    func testFunctionCallRequest_encoding_keys() throws {
        let req = FunctionCallRequest(
            accountId: "a.near",
            methodName: "m",
            argsBase64: "e30=",
            finality: "optimistic",
            blockId: nil
        )
        let obj = try encodeJSON(req)
        XCTAssertEqual(obj["request_type"] as? String, "call_function")
        XCTAssertEqual(obj["account_id"] as? String, "a.near")
        XCTAssertEqual(obj["method_name"] as? String, "m")
        XCTAssertEqual(obj["args_base64"] as? String, "e30=")
    }

    func testTxStatusRequest_encoding_keys() throws {
        let req = TxStatusRequest(txHash: "0xabc", senderId: "a.near")
        let obj = try encodeJSON(req)
        XCTAssertEqual(obj["tx_hash"] as? String, "0xabc")
        XCTAssertEqual(obj["sender_id"] as? String, "a.near")
    }

    func testBlockRequest_encoding_keys() throws {
        let r1 = BlockRequest(finality: "final", blockId: nil)
        let o1 = try encodeJSON(r1)
        XCTAssertEqual(o1["finality"] as? String, "final")
        XCTAssertNil(o1["block_id"])

        let r2 = BlockRequest(finality: nil, blockId: 123)
        let o2 = try encodeJSON(r2)
        XCTAssertEqual(o2["block_id"] as? UInt64, 123)
        XCTAssertNil(o2["finality"])
    }

    func testJSONRPCRequest_wraps_params() throws {
        let params = ViewAccountRequest(accountId: "a.near", finality: "optimistic", blockId: nil)
        let env = JSONRPCRequest(id: "1", method: "query", params: params)
        let obj = try encodeJSON(env)
        XCTAssertEqual(obj["jsonrpc"] as? String, "2.0")
        XCTAssertEqual(obj["id"] as? String, "1")
        XCTAssertEqual(obj["method"] as? String, "query")
        XCTAssertNotNil(obj["params"])
    }

    func testJSONRPCResponse_success_with_Account_camel() throws {
        let json = #"""
        {
          "jsonrpc":"2.0","id":"1",
          "result":{
            "amount":"1","lockedAmount":"0","code_hash":"c",
            "storage_usage":0,"storage_paid_at":1,"block_height":2,"block_hash":"h"
          }
        }
        """#
        let dec = JSONDecoder()
        let resp = try dec.decode(JSONRPCResponse<Account>.self, from: Data(json.utf8))
        XCTAssertNotNil(resp.result)
        XCTAssertNil(resp.error)
    }

    func testJSONRPCResponse_error_object_with_data() throws {
        let json = #"""
        {
          "jsonrpc":"2.0","id":"1",
          "error": { "code": -32000, "message": "boom", "data": { "details": 42 } }
        }
        """#
        let dec = JSONDecoder()
        let resp = try dec.decode(JSONRPCResponse<Account>.self, from: Data(json.utf8))
        XCTAssertNil(resp.result)
        XCTAssertNotNil(resp.error)
        XCTAssertEqual(resp.error?.code, -32000)
    }
}
