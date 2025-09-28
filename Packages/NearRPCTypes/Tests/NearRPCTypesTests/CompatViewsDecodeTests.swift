import XCTest
@testable import NearJsonRpcTypes

final class CompatViewsDecodeTests: XCTestCase {

    func testBlockView_header_epochId_or_epoch_id() throws {
        let camel = #"""
        {"author":"alice","header":{"height":1,"epochId":"E","prevHash":"p","prevStateRoot":"s","timestamp":1,"timestampNanosec":"1","randomValue":"r","gasPrice":"0","totalSupply":"0","challengesRoot":"c"},"chunks":[]}
        """#.data(using: .utf8)!

        let snake = #"""
        {"author":"alice","header":{"height":1,"epoch_id":"E","prev_hash":"p","prev_state_root":"s","timestamp":1,"timestamp_nanosec":"1","random_value":"r","gas_price":"0","total_supply":"0","challenges_root":"c"},"chunks":[]}
        """#.data(using: .utf8)!

        let d = JSONDecoder()
        let v1 = try d.decode(BlockView.self, from: camel)
        let v2 = try d.decode(BlockView.self, from: snake)
        XCTAssertEqual(v1.header.epochId, "E")
        XCTAssertEqual(v2.header.epochId, "E")
    }

    func testViewAccountResult_locked_variants() throws {
        let camel = #"""
        {"amount":"1","lockedAmount":"2","codeHash":"h","storageUsage":1,"storagePaidAt":0,"blockHeight":10,"blockHash":"bh"}
        """#.data(using: .utf8)!
        let legacy = #"""
        {"amount":"1","locked":"2","code_hash":"h","storage_usage":1,"storage_paid_at":0,"block_height":10,"block_hash":"bh"}
        """#.data(using: .utf8)!

        let d = JSONDecoder()
        let a1 = try d.decode(ViewAccountResult.self, from: camel)
        let a2 = try d.decode(ViewAccountResult.self, from: legacy)
        XCTAssertEqual(a1.lockedAmount, "2")
        XCTAssertEqual(a2.lockedAmount, "2")
    }
}
