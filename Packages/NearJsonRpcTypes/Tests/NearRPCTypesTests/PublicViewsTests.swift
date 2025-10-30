@testable import NearJsonRpcTypes
import XCTest

final class PublicViewsTests: XCTestCase {
    func testNearGasPriceViewInit() throws {
        let view = NearGasPriceView(gasPrice: "100", blockHeight: 123, blockHash: "abc")
        XCTAssertEqual(view.gasPrice, "100")
        XCTAssertEqual(view.blockHeight, 123)
        XCTAssertEqual(view.blockHash, "abc")
    }

    func testNearGasPriceViewEncodeDecode() throws {
        let view = NearGasPriceView(gasPrice: "200", blockHeight: 456, blockHash: "def")
        let enc = JSONEncoder()
        let data = try enc.encode(view)
        let dec = JSONDecoder()
        let decoded = try dec.decode(NearGasPriceView.self, from: data)
        XCTAssertEqual(decoded, view)
    }

    func testNearEpochValidatorInfoInit() throws {
        let info = NearEpochValidatorInfo(
            epochHeight: 100,
            epochStartHeight: 200,
            currentValidators: .array([]),
            nextValidators: .null,
            currentProposals: .object([:]),
            prevEpochKickout: .string("test")
        )
        XCTAssertEqual(info.epochHeight, 100)
        XCTAssertEqual(info.epochStartHeight, 200)
    }

    func testNearEpochValidatorInfoEncodeDecode() throws {
        let info = NearEpochValidatorInfo(epochHeight: 300)
        let data = try JSONEncoder().encode(info)
        let decoded = try JSONDecoder().decode(NearEpochValidatorInfo.self, from: data)
        XCTAssertEqual(decoded, info)
    }
}
