@testable import NearJsonRpcTypes
import XCTest

final class RPCTypesRoundtripTests: XCTestCase {
    func testJSONRPCRequestEncode() throws {
        // request_type usa snake_case en JSON
        let params = ViewAccountParams(accountId: "alice.testnet", finality: "optimistic", blockId: nil)

        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase

        let req = JSONRPCRequest(method: "query", params: params)
        let data = try enc.encode(req)
        let s = String(data: data, encoding: .utf8)!

        XCTAssertTrue(s.contains("\"method\":\"query\""))
        XCTAssertTrue(s.contains("\"request_type\":\"view_account\""))
        XCTAssertTrue(s.contains("\"account_id\":\"alice.testnet\""))
    }

    func testJSONRPCResponseSuccessAndErrorDecode() throws {
        // ⚠️ Account tiene campos NO opcionales → incluimos todos en el JSON
        let okJSON = """
          {"jsonrpc":"2.0","id":"1","result":{
            "amount":"1",
            "locked_amount":"0",
            "code_hash":"11111111111111111111111111111111",
            "storage_usage":0,
            "storage_paid_at":0,
            "block_height":1,
            "block_hash":"22222222222222222222222222222222"
          }}
        """.data(using: .utf8)!

        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase

        let ok = try dec.decode(JSONRPCResponse<Account>.self, from: okJSON)
        XCTAssertNotNil(ok.result)
        XCTAssertNil(ok.error)

        let errJSON = """
        {"jsonrpc":"2.0","id":"1","error":{"code":-32000,"message":"boom"}}
        """.data(using: .utf8)!

        let err = try dec.decode(JSONRPCResponse<Account>.self, from: errJSON)
        XCTAssertNil(err.result)
        XCTAssertEqual(err.error?.code, -32000)
        XCTAssertEqual(err.error?.message, "boom")
    }
}
