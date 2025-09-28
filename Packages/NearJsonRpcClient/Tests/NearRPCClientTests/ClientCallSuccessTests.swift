import XCTest
@testable import NearJsonRpcClient

final class ClientCallSuccessTests: XCTestCase {
    func testClientInitConfigForm() throws {
        let base = URL(string: "https://rpc.testnet.near.org/ignored/path")!
        let client = NearJsonRpcClient(.init(endpoint: base))
        // Evita warning de variable no usada
        _ = client
    }
}
