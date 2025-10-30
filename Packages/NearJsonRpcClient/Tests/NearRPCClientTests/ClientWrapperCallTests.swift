@testable import NearJsonRpcClient
@testable import NearJsonRpcTypes
import XCTest

final class ClientWrapperCallTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        URLProtocol.registerClass(URLProtocolMock.self)
    }

    override class func tearDown() {
        URLProtocol.unregisterClass(URLProtocolMock.self)
        super.tearDown()
    }

    func testBlockFinality() async throws {
        let client = NearJsonRpcClient(.init(endpoint: URL(string: "https://rpc.testnet.near.org")!))

        let mockResponse = """
        {
            "jsonrpc": "2.0",
            "id": "1",
            "result": {
                "author": "test.near",
                "header": {
                    "height": 12345,
                    "hash": "GwNz3nssn1ZPnJGRyufdHpAQ32Bq2j5t2hS2CtJt3g9S",
                    "timestamp": 1629825600000000000
                },
                "chunks": []
            }
        }
        """

        URLProtocolMock.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, mockResponse.data(using: .utf8)!)
        }

        let block = try await client.block(blockReference: .finality(.final))
        XCTAssertEqual(block.header.height, 12345)
        XCTAssertEqual(block.header.hash, "GwNz3nssn1ZPnJGRyufdHpAQ32Bq2j5t2hS2CtJt3g9S")
    }

    func testBlockId() async throws {
        let client = NearJsonRpcClient(.init(endpoint: URL(string: "https://rpc.testnet.near.org")!))

        let mockResponse = """
        {
            "jsonrpc": "2.0",
            "id": "1",
            "result": {
                "author": "test.near",
                "header": {
                    "height": 12345,
                    "hash": "GwNz3nssn1ZPnJGRyufdHpAQ32Bq2j5t2hS2CtJt3g9S",
                    "timestamp": 1629825600000000000
                },
                "chunks": []
            }
        }
        """

        URLProtocolMock.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, mockResponse.data(using: .utf8)!)
        }

        let block = try await client.block(blockReference: .blockId(12345))
        XCTAssertEqual(block.header.height, 12345)
    }

    func testViewAccount() async throws {
        let client = NearJsonRpcClient(.init(endpoint: URL(string: "https://rpc.testnet.near.org")!))

        let mockResponse = """
        {
            "jsonrpc": "2.0",
            "id": "1",
            "result": {
                "amount": "10000000000000000000000000",
                "locked": "0",
                "code_hash": "11111111111111111111111111111111",
                "storage_usage": 123,
                "storage_paid_at": 0,
                "block_height": 12345,
                "block_hash": "GwNz3nssn1ZPnJGRyufdHpAQ32Bq2j5t2hS2CtJt3g9S"
            }
        }
        """

        URLProtocolMock.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, mockResponse.data(using: .utf8)!)
        }

        let account = try await client.viewAccount(accountId: "test.near")
        XCTAssertEqual(account.amount, "10000000000000000000000000")
        XCTAssertEqual(account.blockHeight, 12345)
    }

    func testServerError() async throws {
        let client = NearJsonRpcClient(.init(endpoint: URL(string: "https://rpc.testnet.near.org")!))

        URLProtocolMock.handler = { request in
            let body = #"{"jsonrpc":"2.0","id":"1","error":{"code":-32000,"message":"Server error","data":"Something went wrong"}}"#.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, body)
        }

        await XCTAssertThrowsError(try await client.status())
    }
}
