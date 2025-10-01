@testable import NearJsonRpcClient
@testable import NearJsonRpcTypes
import XCTest

final class ClientValidatorsAndGasPriceTests: XCTestCase {
    private func makeClient() -> NearJsonRpcClient {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: cfg)
        return NearJsonRpcClient(.init(endpoint: URL(string: "https://rpc.testnet.near.org")!), session: session)
    }

    func testValidatorsByEpochId() async throws {
        URLProtocolMock.handler = { req in
            let result = ["current_validators": [], "next_validators": [], "current_proposals": []]
            let out = ["jsonrpc": "2.0", "id": "1", "result": result]
            let body = try JSONSerialization.data(withJSONObject: out)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (resp, body)
        }
        _ = try await makeClient().validators(.byEpochId("epoch1"))
    }

    func testValidatorsCurrent() async throws {
        URLProtocolMock.handler = { req in
            let result = ["current_validators": [], "next_validators": [], "current_proposals": []]
            let out = ["jsonrpc": "2.0", "id": "1", "result": result]
            let body = try JSONSerialization.data(withJSONObject: out)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (resp, body)
        }
        _ = try await makeClient().validators(.current)
    }
}
