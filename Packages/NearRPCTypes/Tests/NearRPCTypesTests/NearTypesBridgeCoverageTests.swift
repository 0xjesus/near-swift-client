import XCTest
@testable import NearJsonRpcTypes

final class NearTypesBridgeCoverageTests: XCTestCase {

    func testViewAccountResult_tolerant_decode() throws {
        let json = #"{ "amount":"10", "locked_amount":"7", "storage_paid_at":1, "storage_usage":2 }"#
        let r = try JSONDecoder().decode(ViewAccountResult.self, from: Data(json.utf8))
        XCTAssertEqual(r.amount, "10")
        XCTAssertEqual(r.locked, "7")
        XCTAssertEqual(r.storagePaidAt, 1)
        XCTAssertEqual(r.storageUsage, 2)
    }

    func testViewStateResult_roundtrip() throws {
        let s = ViewStateResult(
            values: [StateItem(key: "a", value: "b")],
            proof: [["k": "v"]]
        )
        let data = try JSONEncoder().encode(s)
        let back = try JSONDecoder().decode(ViewStateResult.self, from: data)
        XCTAssertEqual(back.values.count, 1)
        XCTAssertEqual(back.proof?.count, 1)
    }

    func testViewCodeResult_roundtrip() throws {
        let c = ViewCodeResult(codeBase64: "AA==", hash: "deadbeef")
        let data = try JSONEncoder().encode(c)
        let back = try JSONDecoder().decode(ViewCodeResult.self, from: data)
        XCTAssertEqual(back.codeBase64, "AA==")
        XCTAssertEqual(back.hash, "deadbeef")
    }
}
