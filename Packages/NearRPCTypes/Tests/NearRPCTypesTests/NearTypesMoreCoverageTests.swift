@testable import NearJsonRpcTypes
import XCTest

final class NearTypesMoreCoverageTests: XCTestCase {
    func testBlockHeaderEncodeSnakeCase() throws {
        let h = BlockHeader(
            height: 1,
            epochId: "e",
            prevHash: "ph",
            prevStateRoot: "psr",
            timestamp: 123,
            timestampNanosec: "123000000",
            randomValue: "rv",
            gasPrice: "1",
            totalSupply: "2",
            challengesRoot: "cr"
        )
        let data = try JSONEncoder().encode(h)
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(obj["height"] as? Int, 1)
        XCTAssertEqual(obj["epoch_id"] as? String, "e")
        XCTAssertEqual(obj["prev_hash"] as? String, "ph")
        XCTAssertEqual(obj["prev_state_root"] as? String, "psr")
        XCTAssertNotNil(obj["timestamp"])
        XCTAssertEqual(obj["timestamp_nanosec"] as? String, "123000000")
        XCTAssertEqual(obj["random_value"] as? String, "rv")
        XCTAssertEqual(obj["gas_price"] as? String, "1")
        XCTAssertEqual(obj["total_supply"] as? String, "2")
        XCTAssertEqual(obj["challenges_root"] as? String, "cr")
    }

    func testAccountDecodeMissingLockedDefaultsToZero() throws {
        let json = #"{ "amount":"5", "code_hash":"h", "storage_usage":1, "storage_paid_at":1, "block_height":10, "block_hash":"bh" }"#
        let a = try JSONDecoder().decode(Account.self, from: Data(json.utf8))
        XCTAssertEqual(a.amount, "5")
        XCTAssertEqual(a.lockedAmount, "0") // fallback del init(from:)
        XCTAssertEqual(a.codeHash, "h")
        XCTAssertEqual(a.blockHeight, 10)
        XCTAssertEqual(a.blockHash, "bh")
    }
}
