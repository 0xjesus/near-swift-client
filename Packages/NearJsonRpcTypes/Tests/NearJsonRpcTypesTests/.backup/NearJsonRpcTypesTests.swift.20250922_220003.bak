import XCTest
@testable import NearJsonRpcTypes

final class NearJsonRpcTypesTests: XCTestCase {
    
    func testBasicTypes() {
        let accountId: AccountId = "test.near"
        XCTAssertEqual(accountId, "test.near")
        
        let u128 = U128("1000000000000000000000000")
        XCTAssertEqual(u128.value, "1000000000000000000000000")
    }
    
    func testCaseConversion() {
        XCTAssertEqual("snake_case_string".camelCased, "snakeCaseString")
        XCTAssertEqual("camelCaseString".snakeCased, "camel_case_string")
        XCTAssertEqual("already_correct".camelCased, "alreadyCorrect")
    }
    
    func testJSONEncoding() throws {
        struct TestStruct: Codable {
            let myField: String
            let anotherField: Int
        }
        
        let test = TestStruct(myField: "test", anotherField: 42)
        let encoder = NearJSONEncoder()
        let data = try encoder.encode(test)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        XCTAssertEqual(json["my_field"] as? String, "test")
        XCTAssertEqual(json["another_field"] as? Int, 42)
    }
    
    func testJSONDecoding() throws {
        let json = """
        {
            "my_field": "test",
            "another_field": 42
        }
        """.data(using: .utf8)!
        
        struct TestStruct: Codable, Equatable {
            let myField: String
            let anotherField: Int
        }
        
        let decoder = NearJSONDecoder()
        let decoded = try decoder.decode(TestStruct.self, from: json)
        
        XCTAssertEqual(decoded.myField, "test")
        XCTAssertEqual(decoded.anotherField, 42)
    }
    
    func testBlockReference() throws {
        let finalityRef = BlockReference.finality(.final)
        let heightRef = BlockReference.blockId(.height(1000))
        let hashRef = BlockReference.blockId(.hash("ABC123"))
        
        let encoder = JSONEncoder()
        _ = try encoder.encode(finalityRef)
        _ = try encoder.encode(heightRef)
        _ = try encoder.encode(hashRef)
    }
    
    func testActions() throws {
        let transfer = Action.transfer(TransferAction(deposit: "1000000000000000000000000"))
        let functionCall = Action.functionCall(FunctionCallAction(
            methodName: "test",
            args: "eyJ0ZXN0IjoidmFsdWUifQ==",
            gas: 100000000000000,
            deposit: "0"
        ))
        
        let encoder = JSONEncoder()
        _ = try encoder.encode(transfer)
        _ = try encoder.encode(functionCall)
    }
    
    func testViewAccountRequest() throws {
        let request = ViewAccountRequest(accountId: "test.near")
        XCTAssertEqual(request.accountId, "test.near")
        XCTAssertEqual(request.requestType, "view_account")
        XCTAssertEqual(request.finality, "optimistic")
    }
    
    func testFunctionCallRequest() throws {
        let request = FunctionCallRequest(
            accountId: "contract.near",
            methodName: "get_balance",
            argsBase64: "e30="
        )
        XCTAssertEqual(request.accountId, "contract.near")
        XCTAssertEqual(request.methodName, "get_balance")
        XCTAssertEqual(request.requestType, "call_function")
    }
    
    func testJSONRPCRequest() throws {
        let request = JSONRPCRequest(
            id: "test-123",
            method: "query",
            params: ["test": "value"]
        )
        
        XCTAssertEqual(request.jsonrpc, "2.0")
        XCTAssertEqual(request.id, "test-123")
        XCTAssertEqual(request.method, "query")
    }
    
    func testAnyCodable() throws {
        let intValue = AnyCodable(42)
        let stringValue = AnyCodable("test")
        let boolValue = AnyCodable(true)
        let dictValue = AnyCodable(["key": "value"])
        
        let encoder = JSONEncoder()
        _ = try encoder.encode(intValue)
        _ = try encoder.encode(stringValue)
        _ = try encoder.encode(boolValue)
        _ = try encoder.encode(dictValue)
    }
}
