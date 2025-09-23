import XCTest
@testable import NearJsonRpcClient
@testable import NearJsonRpcTypes

final class NearJsonRpcClientTests: XCTestCase {
    
    func testClientInitialization() throws {
        let client = try NearJsonRpcClient(endpoint: "https://rpc.testnet.near.org")
        XCTAssertNotNil(client)
    }
    
    func testInvalidEndpoint() {
        XCTAssertThrows(try NearJsonRpcClient(endpoint: "not a valid url"))
    }
    
    func testErrorDescription() {
        let error1 = NearClientError.invalidEndpoint("test")
        XCTAssertEqual(error1.errorDescription, "Invalid endpoint: test")
        
        let error2 = NearClientError.httpError(404)
        XCTAssertEqual(error2.errorDescription, "HTTP error: 404")
        
        let error3 = NearClientError.rpcError(code: -32000, message: "Server error")
        XCTAssertEqual(error3.errorDescription, "RPC error -32000: Server error")
    }
    
    // Mock tests for network calls
    func testMockViewAccount() async throws {
        // This would use a mock URLSession in a real implementation
        let mockSession = MockURLSession()
        let client = try NearJsonRpcClient(
            endpoint: "https://rpc.testnet.near.org",
            session: mockSession
        )
        
        // Set up mock response
        mockSession.mockResponse = """
        {
            "jsonrpc": "2.0",
            "id": "test",
            "result": {
                "amount": "1000000000000000000000000",
                "locked_amount": "0",
                "code_hash": "11111111111111111111111111111111",
                "storage_usage": 500,
                "storage_paid_at": 0,
                "block_height": 100,
                "block_hash": "ABC123"
            }
        }
        """.data(using: .utf8)
        
        // Test would continue here with assertions
        // let account = try await client.viewAccount("test.near")
        // XCTAssertEqual(account.amount, "1000000000000000000000000")
    }
}

// Mock URLSession for testing
class MockURLSession: URLSession {
    var mockResponse: Data?
    var mockError: Error?
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        return (mockResponse ?? Data(), response)
    }
}
