import XCTest
@testable import NearJsonRpcTypes

final class NearJsonRpcTypesSanityTests: XCTestCase {
    func testAliasesPresent() {
        _ = ProtocolConfig.self
        _ = GenesisConfig.self
        XCTAssertTrue(true)
    }
}
