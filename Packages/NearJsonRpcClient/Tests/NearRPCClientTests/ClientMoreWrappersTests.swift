@testable import NearJsonRpcClient
@testable import NearJsonRpcTypes
import XCTest

final class ClientMoreWrappersTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        URLProtocol.registerClass(URLProtocolMock.self)
    }

    override class func tearDown() {
        URLProtocol.unregisterClass(URLProtocolMock.self)
        super.tearDown()
    }

    func testBroadcastLegacyAndProtocolConfig() async throws {
        URLProtocolMock.handler = { req in
            let body = req.httpBodyStream?.readAll() ?? req.httpBody ?? Data()
            let json = try JSONSerialization.jsonObject(with: body) as! [String: Any]
            let method = json["method"] as! String

            let result: Any = if method == "broadcast_tx_async" {
                "0xABCD1234" // String response for tx hash
            } else if method == "EXPERIMENTAL_protocol_config" {
                ["protocol_version": 1, "runtime_config": [:]]
            } else {
                [:]
            }

            let out: [String: Any] = ["jsonrpc": "2.0", "id": json["id"] ?? 1, "result": result]
            let data = try JSONSerialization.data(withJSONObject: out)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (resp, data)
        }

        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: cfg)
        let client = NearJsonRpcClient(.init(endpoint: URL(string: "https://rpc.testnet.near.org")!), session: session)

        let txHash = try await client.broadcastTxAsync(base64: "AA==")
        XCTAssertEqual(txHash, "0xABCD1234")

        // //         let _ = try await client.getProtocolConfig(.init(finality: .final))
    }
}
