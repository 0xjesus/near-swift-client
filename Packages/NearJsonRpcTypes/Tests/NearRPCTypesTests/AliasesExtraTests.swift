@testable import NearJsonRpcTypes
import XCTest

final class AliasesExtraTests: XCTestCase {
    func testBlockReferenceInit() throws {
        let ref = Components.Schemas.BlockReference(finality: .final)
        XCTAssertEqual(ref.finality, .final)
    }
    
    func testBlockReferenceCaseFinality() throws {
        let ref = Components.Schemas.BlockReference.case_Finality(.final)
        XCTAssertEqual(ref.finality, .final)
    }
    
    func testBlockReferenceEncode() throws {
        let ref = Components.Schemas.BlockReference(finality: .optimistic)
        let data = try JSONEncoder().encode(ref)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: String]
        XCTAssertEqual(dict["finality"], "optimistic")
    }
}
