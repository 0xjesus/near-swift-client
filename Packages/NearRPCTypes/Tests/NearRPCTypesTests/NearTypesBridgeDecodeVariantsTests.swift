@testable import NearJsonRpcTypes
import XCTest

final class NearTypesBridgeDecodeVariantsTests: XCTestCase {
    func testViewAccountResult_locked_variants_decode() throws {
        // locked (moderno)
        let v1 = try JSONDecoder().decode(ViewAccountResult.self, from: Data(#"{ "amount":"1", "locked":"2" }"#.utf8))
        XCTAssertEqual(v1.amount, "1"); XCTAssertEqual(v1.locked, "2")

        // locked_amount (legacy)
        let v2 = try JSONDecoder().decode(ViewAccountResult.self, from: Data(#"{ "amount":"3", "locked_amount":"4" }"#.utf8))
        XCTAssertEqual(v2.amount, "3"); XCTAssertEqual(v2.locked, "4")

        // lockedAmount (camel)
        let v3 = try JSONDecoder().decode(ViewAccountResult.self, from: Data(#"{ "amount":"5", "lockedAmount":"6" }"#.utf8))
        XCTAssertEqual(v3.amount, "5"); XCTAssertEqual(v3.locked, "6")
    }

    func testBlockHeader_decode_and_encode_snake() throws {
        // decode snake → struct
        let json = #"""
        {
          "height": 10,
          "epoch_id": "e",
          "prev_hash": "ph",
          "prev_state_root": "psr",
          "timestamp": 1,
          "timestamp_nanosec": "1",
          "random_value": "rv",
          "gas_price": "0",
          "total_supply": "0",
          "challenges_root": "cr"
        }
        """#
        let dec = JSONDecoder()
        let h = try dec.decode(BlockHeader.self, from: Data(json.utf8))
        XCTAssertEqual(h.height, 10)
        XCTAssertEqual(h.epochId, "e")

        // encode struct → snake
        let data = try JSONEncoder().encode(h)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertNotNil(dict["epoch_id"])
        XCTAssertNil(dict["epochId"])
    }
}
