import Foundation
import NearJsonRpcClient
import NearJsonRpcTypes
import XCTest

/// Optional integration test that only runs when NEAR_RPC_URL is present.
final class IntegrationOptInTests: XCTestCase {
    func testClientInitIfOptIn() throws {
        guard
            let s = ProcessInfo.processInfo.environment["NEAR_RPC_URL"],
            let endpoint = URL(string: s)
        else {
            throw XCTSkip("NEAR_RPC_URL not set; skipping integration test")
        }

        // Current initializer takes an unlabeled Config parameter:
        // init(_ config: NearJsonRpcClient.Config)
        let client = NearJsonRpcClient(.init(endpoint: endpoint))

        // Sanity: object constructed
        XCTAssertFalse(String(describing: client).isEmpty)
    }
}
