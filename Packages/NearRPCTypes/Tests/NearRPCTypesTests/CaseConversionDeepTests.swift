import XCTest
import NearJsonRpcTypes

final class CaseConversionDeepTests: XCTestCase {

    struct Inner: Codable, Equatable {
        let publicKeyBase58: String
        let blockHash: String
        let gasBurnt: Int
    }

    struct Outer: Codable, Equatable {
        let signerId: String
        let actions: [Inner]
        let receiptIds: [String]
    }

    func testRoundTripSnakeCamelNested() throws {
        let outer = Outer(
            signerId: "alice.near",
            actions: [
                Inner(publicKeyBase58: "ed25519:ABC", blockHash: "HASH123", gasBurnt: 42),
                Inner(publicKeyBase58: "ed25519:DEF", blockHash: "HASH456", gasBurnt: 7)
            ],
            receiptIds: ["r1", "r2"]
        )

        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        let data = try enc.encode(outer)
        let str = String(data: data, encoding: .utf8)!
        XCTAssertTrue(str.contains(#""public_key_base58":"#))
        XCTAssertTrue(str.contains(#""block_hash":"#))
        XCTAssertTrue(str.contains(#""gas_burnt":"#))

        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        let back = try dec.decode(Outer.self, from: data)
        XCTAssertEqual(back, outer)
    }
}
