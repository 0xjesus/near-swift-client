@testable import NearJsonRpcTypes
import XCTest

final class NearJsonRpcTypesSanityTests: XCTestCase {
    func testAliasesPresent() {
        _ = ProtocolConfig.self
        _ = GenesisConfig.self
        XCTAssertTrue(true)
    }
}
