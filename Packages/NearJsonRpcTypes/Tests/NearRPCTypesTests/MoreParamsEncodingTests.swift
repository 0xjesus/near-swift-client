@testable import NearJsonRpcTypes
import XCTest

final class MoreParamsEncodingTests: XCTestCase {
    private func encodeToString(_ v: some Encodable) throws -> String {
        let enc = JSONEncoder(); enc.keyEncodingStrategy = .convertToSnakeCase
        return try String(data: enc.encode(v), encoding: .utf8)!
    }

    func testBlockParamsEncode() throws {
        let s = try encodeToString(BlockParams(blockId: .string("abc"), finality: .final))
        XCTAssertTrue(s.contains("\"block_id\":\"abc\""))
        XCTAssertTrue(s.contains("\"finality\":\"final\""))
    }

    func testChunkParamsEncode() throws {
        let s = try encodeToString(ChunkParams(chunkId: .string("ch"), blockId: .number(1)))
        XCTAssertTrue(s.contains("\"chunk_id\":\"ch\""))
        XCTAssertTrue(s.contains("\"block_id\":1"))
    }

    func testValidatorsCurrentEncode() throws {
        let s = try encodeToString(ValidatorsParams.current)
        XCTAssertFalse(s.contains("epoch_id"))
        XCTAssertFalse(s.contains("block_id"))
    }

    func testViewAccessKeyParamsEncode() throws {
        let s = try encodeToString(ViewAccessKeyParams(accountId: "alice", publicKey: "ed25519:XYZ"))
        XCTAssertTrue(s.contains("\"request_type\":\"view_access_key\""))
        XCTAssertTrue(s.contains("\"account_id\":\"alice\""))
        XCTAssertTrue(s.contains("\"public_key\":\"ed25519:XYZ\""))
    }

    func testViewAccessKeyListParamsEncode() throws {
        let s = try encodeToString(ViewAccessKeyListParams(accountId: "alice"))
        XCTAssertTrue(s.contains("\"request_type\":\"view_access_key_list\""))
    }

    func testViewCodeParamsEncode() throws {
        let s = try encodeToString(ViewCodeParams(accountId: "alice"))
        XCTAssertTrue(s.contains("\"request_type\":\"view_code\""))
    }

    func testViewStateParamsEncode() throws {
        let s = try encodeToString(ViewStateParams(accountId: "alice", prefixBase64: "YQ=="))
        XCTAssertTrue(s.contains("\"request_type\":\"view_state\""))
        XCTAssertTrue(s.contains("\"prefix_base64\":\"YQ==\""))
    }

    func testChangesAccountParamsEncode() throws {
        let s = try encodeToString(ChangesAccountParams(accountIds: ["a", "b"]))
        XCTAssertTrue(s.contains("\"changes_type\":\"account_changes\""))
        XCTAssertTrue(s.contains("\"account_ids\":[\"a\",\"b\"]"))
    }

    func testProtocolConfigParamsEncode() throws {
        let s = try encodeToString(ProtocolConfigParams(finality: .final))
        XCTAssertTrue(s.contains("\"finality\":\"final\""))
    }

    func testSendTxParamsEncode() throws {
        let s = try encodeToString(SendTxParams(signedTxBase64: "BASE64"))
        XCTAssertTrue(s.contains("\"signed_tx_base64\":\"BASE64\""))
    }

    func testTxStatusParamsEncode() throws {
        let s = try encodeToString(TxStatusParams(txHash: "0xAA", senderId: "alice"))
        XCTAssertTrue(s.contains("\"tx_hash\":\"0xAA\""))
        XCTAssertTrue(s.contains("\"sender_id\":\"alice\""))
    }

    func testLightClientProofParamsEncode() throws {
        let s = try encodeToString(LightClientProofParams(outcomeId: "o", lightClientHead: "h"))
        XCTAssertTrue(s.contains("\"outcome_id\":\"o\""))
        XCTAssertTrue(s.contains("\"light_client_head\":\"h\""))
    }
}
