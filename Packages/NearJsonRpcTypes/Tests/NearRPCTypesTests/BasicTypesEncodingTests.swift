import XCTest
@testable import NearJsonRpcTypes

final class BasicTypesEncodingTests: XCTestCase {
    func testU128Roundtrip() throws {
        let v = U128("340282366920938463463374607431768211455") // 2^128-1
        let d = try JSONEncoder().encode(v)
        let back = try JSONDecoder().decode(U128.self, from: d)
        XCTAssertEqual(back, v)
    }

    func testU64Roundtrip() throws {
        let v = U64("18446744073709551615") // 2^64-1 textual
        let d = try JSONEncoder().encode(v)
        let back = try JSONDecoder().decode(U64.self, from: d)
        XCTAssertEqual(back.value, v.value)
    }

    func testBlockReferenceRoundtrip() throws {
        let a: BlockReference = .blockId(.height(42))
        let b = try JSONDecoder().decode(BlockReference.self, from: JSONEncoder().encode(a))
        XCTAssertEqual(b, a)

        let c: BlockReference = .finality(.final)
        let d = try JSONDecoder().decode(BlockReference.self, from: JSONEncoder().encode(c))
        XCTAssertEqual(d, c)
    }

    func testAccessKeyPermissionRoundtrip() throws {
        let ak1 = AccessKey(nonce: 1, permission: .fullAccess)
        let back1 = try JSONDecoder().decode(AccessKey.self, from: JSONEncoder().encode(ak1))
        XCTAssertEqual(back1, ak1)

        let perm = FunctionCallPermission(allowance: "0", receiverId: "bob.testnet", methodNames: ["m"])
        let ak2 = AccessKey(nonce: 2, permission: .functionCall(perm))
        let back2 = try JSONDecoder().decode(AccessKey.self, from: JSONEncoder().encode(ak2))
        XCTAssertEqual(back2, ak2)
    }
}
