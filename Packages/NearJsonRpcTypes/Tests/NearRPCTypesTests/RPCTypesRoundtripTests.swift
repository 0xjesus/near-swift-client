import XCTest
@testable import NearJsonRpcTypes

final class RPCTypesRoundtripTests: XCTestCase {

    func testJSONRPCRequestEncode() throws {
        let params = ViewAccountParams(accountId: "alice.testnet", finality: "optimistic", blockId: nil)
        let req = JSONRPCRequest(method: "query", params: params)
        let data = try JSONEncoder().encode(req)

        // Verificamos los nombres de llaves reales en el JSON emitido
        let objAny = try JSONSerialization.jsonObject(with: data, options: [])
        let obj = try XCTUnwrap(objAny as? [String: Any])

        XCTAssertEqual(obj["jsonrpc"] as? String, "2.0")
        XCTAssertEqual(obj["method"] as? String, "query")

        let paramsAny = try XCTUnwrap(obj["params"])
        let paramsDict = try XCTUnwrap(paramsAny as? [String: Any])
        XCTAssertEqual(paramsDict["request_type"] as? String, "view_account")
        XCTAssertEqual(paramsDict["account_id"] as? String, "alice.testnet")
        // "finality" suele ser "optimistic" por default
        XCTAssertEqual(paramsDict["finality"] as? String, "optimistic")
    }

    func testJSONRPCResponseSuccessAndErrorDecode() throws {
        // OK
        let okJSON = """
        {"jsonrpc":"2.0","id":"1","result":{
           "amount":"1","locked_amount":"0","code_hash":"h",
           "storage_usage":1,"storage_paid_at":1,
           "block_height":1,"block_hash":"bh"
        }}
        """.data(using: .utf8)!
        let ok = try JSONDecoder().decode(JSONRPCResponse<Account>.self, from: okJSON)
        XCTAssertNil(ok.error)
        XCTAssertEqual(ok.result?.amount, "1")
        XCTAssertEqual(ok.result?.codeHash, "h")

        // Error
        let errJSON = #"{"jsonrpc":"2.0","id":"1","error":{"code":-32000,"message":"boom"}}"#.data(using: .utf8)!
        let err = try JSONDecoder().decode(JSONRPCResponse<Account>.self, from: errJSON)
        XCTAssertNotNil(err.error)
        XCTAssertEqual(err.error?.code, -32000)
        XCTAssertEqual(err.error?.message, "boom")
        XCTAssertNil(err.result)
    }
}
