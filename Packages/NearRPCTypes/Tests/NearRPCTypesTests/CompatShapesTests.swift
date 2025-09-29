@testable import NearJsonRpcTypes
import XCTest

final class CompatShapesTests: XCTestCase {
    func testAccount_decode_locked_amount_locked_lockedAmount() throws {
        let snake = #"""
        {"amount":"1","locked_amount":"2","code_hash":"h","storage_usage":1,"storage_paid_at":10,"block_height":100,"block_hash":"bh"}
        """#.data(using: .utf8)!

        let legacy = #"""
        {"amount":"1","locked":"2","code_hash":"h","storage_usage":1,"storage_paid_at":10,"block_height":100,"block_hash":"bh"}
        """#.data(using: .utf8)!

        let camel = #"""
        {"amount":"1","lockedAmount":"2","codeHash":"h","storageUsage":1,"storagePaidAt":10,"blockHeight":100,"blockHash":"bh"}
        """#.data(using: .utf8)!

        let d = JSONDecoder()
        let a1 = try d.decode(Account.self, from: snake)
        let a2 = try d.decode(Account.self, from: legacy)
        let a3 = try d.decode(Account.self, from: camel)
        XCTAssertEqual(a1.lockedAmount, "2")
        XCTAssertEqual(a2.lockedAmount, "2")
        XCTAssertEqual(a3.lockedAmount, "2")

        // encode vuelve a snake_case
        let e = JSONEncoder(); e.outputFormatting = [.sortedKeys]
        let out = try String(decoding: e.encode(a3), as: UTF8.self)
        XCTAssertTrue(out.contains(#""locked_amount":"2""#))
    }

    func testBlockHeader_decode_epoch_id_or_epochId() throws {
        let snake = #"""
        {"height":10,"epoch_id":"e","prev_hash":"p","prev_state_root":"ps","timestamp":1,"timestamp_nanosec":"1","random_value":"r","gas_price":"0","total_supply":"0","challenges_root":"c"}
        """#.data(using: .utf8)!
        let camel = #"""
        {"height":10,"epochId":"e","prevHash":"p","prevStateRoot":"ps","timestamp":1,"timestampNanosec":"1","randomValue":"r","gasPrice":"0","totalSupply":"0","challengesRoot":"c"}
        """#.data(using: .utf8)!

        let d = JSONDecoder()
        let h1 = try d.decode(BlockHeader.self, from: snake)
        let h2 = try d.decode(BlockHeader.self, from: camel)
        XCTAssertEqual(h1.epochId, "e")
        XCTAssertEqual(h2.epochId, "e")

        let e = JSONEncoder(); e.outputFormatting = [.sortedKeys]
        let out = try String(decoding: e.encode(h2), as: UTF8.self)
        XCTAssertTrue(out.contains(#""epoch_id":"e""#))
    }
}
