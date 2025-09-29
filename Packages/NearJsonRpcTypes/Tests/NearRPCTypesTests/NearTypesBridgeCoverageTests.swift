import XCTest
@testable import NearJsonRpcTypes

final class NearTypesBridgeCoverageTests: XCTestCase {

    func testViewAccountResult_variants_decode_and_reencode() throws {
        // locked_amount (legacy) + otros campos
        let json = #"{ "amount":"10", "locked_amount":"7", "storage_paid_at":1, "storage_usage":2 }"#
        let r = try JSONDecoder().decode(ViewAccountResult.self, from: Data(json.utf8))

        // 1) Decodificación: que existan y sean coherentes
        XCTAssertNotNil(r.amount)
        XCTAssertNotNil(r.locked)
        XCTAssertEqual(r.storagePaidAt, 1)
        XCTAssertEqual(r.storageUsage, 2)

        // 2) Re-encode y validar por contenido (evita asumir la representación interna de U128)
        let encoded = try JSONEncoder().encode(r)
        let s = String(data: encoded, encoding: .utf8)!
        XCTAssertTrue(s.contains(#""amount":"10""#), "encoded=\(s)")
        XCTAssertTrue(s.contains(#""locked":"7""#), "encoded=\(s)")
    }

    func testViewStateResult_encoding_contains_values_and_proof() throws {
        // proof es [JSONValue], no [[String:String]]
        let s = ViewStateResult(
            values: [StateItem(key: "a", value: "b")],
            proof: [.object(["k": .string("v")])]
        )
        let data = try JSONEncoder().encode(s)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertNotNil(dict["values"])
        XCTAssertNotNil(dict["proof"])
    }
}
