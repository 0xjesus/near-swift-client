import XCTest
@testable import NearJsonRpcClient

final class ClientIntegrationTests: XCTestCase {
    func testStatusAndBlock() async throws {
        guard let endpoint = ProcessInfo.processInfo.environment["NEAR_RPC_ENDPOINT"], let url = URL(string: endpoint) else {
            throw XCTSkip("NEAR_RPC_ENDPOINT no definido")
        }
        let client = NearJsonRpcClient(.init(endpoint: url))
        // status no tiene params ([]). Devolvemos JSONValue para smoke test
        let _: JSONValue = try await client.call(method: "status", params: [String]()) // docs: status. :contentReference[oaicite:21]{index=21}
        let block = try await client.block(.init(finality: .final))
        XCTAssertNotNil(block.header?.height)
    }
}
