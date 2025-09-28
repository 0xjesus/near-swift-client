import XCTest
@testable import NearJsonRpcTypes

final class RPCTypesFullCoverageTests: XCTestCase {

    func testFunctionCallRequestEncode() throws {
        let req = FunctionCallRequest(accountId: "alice", methodName: "m", argsBase64: "e30=")
        let enc = JSONEncoder(); enc.keyEncodingStrategy = .convertToSnakeCase
        let s = String(data: try enc.encode(req), encoding: .utf8)!
        XCTAssertTrue(s.contains(#""request_type":"call_function""#))
        XCTAssertTrue(s.contains(#""account_id":"alice""#))
        XCTAssertTrue(s.contains(#""method_name":"m""#))
        XCTAssertTrue(s.contains(#""args_base64":"e30=""#))
    }

    func testTxStatusAndBlockRequestEncode() throws {
        let tx = TxStatusRequest(txHash: "0xAA", senderId: "bob")
        let enc = JSONEncoder(); enc.keyEncodingStrategy = .convertToSnakeCase
        let s1 = String(data: try enc.encode(tx), encoding: .utf8)!
        XCTAssertTrue(s1.contains(#""tx_hash":"0xAA""#))
        XCTAssertTrue(s1.contains(#""sender_id":"bob""#))

        let b = BlockRequest(finality: "final", blockId: 10)
        let s2 = String(data: try enc.encode(b), encoding: .utf8)!
        XCTAssertTrue(s2.contains(#""finality":"final""#))
        XCTAssertTrue(s2.contains(#""block_id":10"#))
    }

    func testFunctionCallResultDecode() throws {
        let json = #"{"result":[1,2],"logs":["l"],"block_height":1,"block_hash":"h"}"#.data(using: .utf8)!
        let dec = JSONDecoder(); dec.keyDecodingStrategy = .convertFromSnakeCase
        let r = try dec.decode(FunctionCallResult.self, from: json)
        XCTAssertEqual(r.result, [1,2])
        XCTAssertEqual(r.logs, ["l"])
        XCTAssertEqual(r.blockHeight, 1)
        XCTAssertEqual(r.blockHash, "h")
    }

    func testBlockDecode() throws {
        let json = """
        {
          "author":"alice",
          "header":{
            "height":1,
            "epoch_id":"e",
            "prev_hash":"p",
            "prev_state_root":"r",
            "timestamp":0,
            "timestamp_nanosec":"0",
            "random_value":"rv",
            "gas_price":"0",
            "total_supply":"0",
            "challenges_root":"cr"
          },
          "chunks":[
            {
              "chunk_hash":"ch",
              "prev_block_hash":"pb",
              "height_created":1,
              "height_included":1,
              "shard_id":0,
              "gas_used":0,
              "gas_limit":0
            }
          ]
        }
        """.data(using: .utf8)!
        let dec = JSONDecoder(); dec.keyDecodingStrategy = .convertFromSnakeCase
        let block = try dec.decode(Block.self, from: json)
        XCTAssertEqual(block.header.epochId, "e")
        XCTAssertEqual(block.chunks.count, 1)
        XCTAssertEqual(block.chunks.first?.chunkHash, "ch")
    }
}
