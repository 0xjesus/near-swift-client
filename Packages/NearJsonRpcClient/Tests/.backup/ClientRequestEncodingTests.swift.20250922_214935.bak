import XCTest
@testable import NearJsonRpcClient
import NearJsonRpcTypes

final class ClientRequestEncodingTests: XCTestCase {
    private func makeClient() -> NearJsonRpcClient {
        let cfg = NearJsonRpcClient.Config(endpoint: URL(string: "https://rpc.testnet.near.org")!)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: config)
        return NearJsonRpcClient(cfg, session: session)
    }

    func testBlockPostRootAndBody() async throws {
        let client = makeClient()

        URLProtocolMock.requestHandler = { req in
            XCTAssertEqual(req.url?.path, "/")
            XCTAssertEqual(req.httpMethod, "POST")
            let body = try XCTUnwrap(req.httpBody)
            let env = try JSONDecoder().decode(JsonRpcEnvelope<JSONValue>.self, from: body)
            XCTAssertEqual((try? JSONSerialization.jsonObject(with: body)).flatMap{ $0 as? [String:Any] }?["method"] as? String, "block")
            // Simula respuesta
            let respEnv = JsonRpcEnvelope<BlockView>(jsonrpc: "2.0", id: nil, result: BlockView(header: BlockHeader(height: 1, hash: "H", epochId: nil), author: "node", chunks: []), error: nil)
            let data = try JSONEncoder().encode(respEnv)
            let http = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"application/json"])!
            return (http, data)
        }

        let res = try await client.block(.init(finality: .final))
        XCTAssertEqual(res.header?.height, 1)
    }
}
