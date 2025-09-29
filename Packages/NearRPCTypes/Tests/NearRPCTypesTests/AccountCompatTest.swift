@testable import NearJsonRpcTypes
import XCTest

final class AccountCompatTests: XCTestCase {
    func testDecodeAccountLockedAmount() throws {
        let data = #"""
        {"jsonrpc":"2.0","result":{
          "amount":"1","locked_amount":"2","code_hash":"h",
          "storage_usage":0,"storage_paid_at":0,"block_height":1,"block_hash":"b"
        }}
        """#.data(using: .utf8)!
        let dec = JSONDecoder(); dec.keyDecodingStrategy = .convertFromSnakeCase
        let env = try dec.decode(JSONRPCResponse<Account>.self, from: data)
        XCTAssertEqual(env.result?.lockedAmount, "2")
    }

    func testDecodeAccountLocked() throws {
        let data = #"""
        {"jsonrpc":"2.0","result":{
          "amount":"1","locked":"2","code_hash":"h",
          "storage_usage":0,"storage_paid_at":0,"block_height":1,"block_hash":"b"
        }}
        """#.data(using: .utf8)!
        let dec = JSONDecoder(); dec.keyDecodingStrategy = .convertFromSnakeCase
        let env = try dec.decode(JSONRPCResponse<Account>.self, from: data)
        XCTAssertEqual(env.result?.lockedAmount, "2")
    }
}
