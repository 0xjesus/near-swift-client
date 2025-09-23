import XCTest
@testable import NearJsonRpcClient
import NearJsonRpcTypes

final class ClientConcurrencyAndErrorsTests: XCTestCase {
    func testConcurrentCalls() async throws {
        let cfg = NearJsonRpcClient.Config(endpoint: URL(string: "https://rpc.testnet.near.org")!)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: config)
        let client = NearJsonRpcClient(cfg, session: session)

        URLProtocolMock.requestHandler = { req in
            let ok = JsonRpcEnvelope<BlockView>(jsonrpc: "2.0", id: nil,
                result: BlockView(header: BlockHeader(height: 42, hash: "H", epochId: nil), author: "node", chunks: []),
                error: nil)
            let data = try JSONEncoder().encode(ok)
            let http = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"application/json"])!
            return (http, data)
        }

        try await withThrowingTaskGroup(of: Void.self) { tg in
            for _ in 0..<20 {
                tg.addTask {
                    let _ = try await client.block(.init(finality: .final))
                }
            }
            try await tg.waitForAll()
        }
    }

    func testPropagatesJsonRpcError() async throws {
        let cfg = NearJsonRpcClient.Config(endpoint: URL(string: "https://rpc.testnet.near.org")!)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: config)
        let client = NearJsonRpcClient(cfg, session: session)

        URLProtocolMock.requestHandler = { req in
            let err = JsonRpcErrorObject(code: -32000, message: "Method not found", data: nil)
            let env = JsonRpcEnvelope<JSONValue>(jsonrpc: "2.0", id: nil, result: nil, error: err)
            let data = try JSONEncoder().encode(env)
            let http = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"application/json"])!
            return (http, data)
        }

        do {
            let _: JSONValue = try await client.call(method: "does_not_exist", params: Optional<Int>.none)
            XCTFail("Expected throw")
        } catch let e as JsonRpcErrorObject {
            XCTAssertEqual(e.code, -32000)
        }
    }
}
