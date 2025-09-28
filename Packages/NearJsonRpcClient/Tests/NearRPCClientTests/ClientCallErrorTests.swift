import XCTest
@testable import NearJsonRpcClient

final class ClientCallErrorTests: XCTestCase {
    func testClientInitWithCustomHeadersAndTimeout() throws {
        let base = URL(string: "https://rpc.testnet.near.org")!
        let client = NearJsonRpcClient(.init(endpoint: base,
                                             headers: ["X-Test":"1"],
                                             timeout: 1))
        _ = client
    }
}
