@testable import NearJsonRpcClient
@testable import NearJsonRpcTypes
import XCTest

// Helper global para asserts async (accesible desde cualquier test file de este target)
@inline(__always)
func XCTAssertAsyncThrowsError(
    _ expression: @escaping () async throws -> some Any,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath, line: UInt = #line,
    _ errorHandler: (Error) -> Void = { _ in }
) async {
    do {
        _ = try await expression()
        XCTFail("Expected error. " + message(), file: file, line: line)
    } catch {
        errorHandler(error)
    }
}

/// Envelope simple para simular respuestas JSON-RPC 2.0
private struct Out<R: Encodable>: Encodable {
    let jsonrpc = "2.0"
    let id = "1"
    let result: R
}

final class ClientWrappersFullCoverageTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        URLProtocol.registerClass(URLProtocolMock.self)
    }

    override class func tearDown() {
        URLProtocol.unregisterClass(URLProtocolMock.self)
        super.tearDown()
    }

    private func makeClient(_ base: String = "https://rpc.testnet.near.org/ignored/path") -> NearJsonRpcClient {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: cfg)
        return NearJsonRpcClient(.init(endpoint: URL(string: base)!), session: session)
    }

    private func ok(_ req: URLRequest, body: Data) -> (HTTPURLResponse, Data) {
        XCTAssertEqual(URLComponents(url: req.url!, resolvingAgainstBaseURL: false)?.path, "/")
        XCTAssertEqual(req.httpMethod, "POST")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Accept"), "application/json")
        let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil,
                                   headerFields: ["Content-Type": "application/json"])!
        return (resp, body)
    }

    func test_wrappers_happy_path_cover_all() async throws {
        let client = makeClient()

        // 1) block (BlockView = Block) – requiere header/chunks completos
        let block = Block(
            author: "alice.testnet",
            header: BlockHeader(
                height: 1,
                epochId: "e",
                prevHash: "ph",
                prevStateRoot: "psr",
                timestamp: 0,
                timestampNanosec: "0",
                randomValue: "rv",
                gasPrice: "0",
                totalSupply: "0",
                challengesRoot: "cr"
            ),
            chunks: [
                ChunkHeader(
                    chunkHash: "ch",
                    prevBlockHash: "ph",
                    heightCreated: 1,
                    heightIncluded: 1,
                    shardId: 0,
                    gasUsed: 0,
                    gasLimit: 0
                ),
            ]
        )
        URLProtocolMock.handler = { req in
            let body = try JSONEncoder().encode(Out(result: block))
            return self.ok(req, body: body)
        }
        let b = try await client.block(.init(finality: .final))
        XCTAssertEqual(b.author, "alice.testnet")

        // 2) chunk → objeto vacío sirve (todo opcional)
        URLProtocolMock.handler = { req in
            let body = try JSONEncoder().encode(Out(result: ChunkView(header: nil, transactions: nil, receipts: nil)))
            return self.ok(req, body: body)
        }
        _ = try await client.chunk(.init(chunkId: "X"))

        // 3) validators (.current)
        URLProtocolMock.handler = { req in
            let body = try JSONEncoder().encode(Out(result: EpochValidatorInfo(
                currentValidators: nil, nextValidators: nil, currentProposals: nil, epochStartHeight: nil
            )))
            return self.ok(req, body: body)
        }
        _ = try await client.validators(.current)

        // 3b) validators (.byEpochId) para cubrir la otra rama de encoding
        URLProtocolMock.handler = { req in
            let body = try JSONEncoder().encode(Out(result: EpochValidatorInfo(
                currentValidators: nil, nextValidators: nil, currentProposals: nil, epochStartHeight: nil
            )))
            return self.ok(req, body: body)
        }
        _ = try await client.validators(.byEpochId("ep-1"))

        // 4) viewAccount → objeto vacío
        URLProtocolMock.handler = { req in
            let body = try JSONEncoder().encode(Out(result: ViewAccountResult(amount: nil, locked: nil, storagePaidAt: nil, storageUsage: nil)))
            return self.ok(req, body: body)
        }
        _ = try await client.viewAccount(.init(accountId: "alice", finality: .final))

        // 5) viewAccessKey
        URLProtocolMock.handler = { req in
            let body = try JSONEncoder().encode(Out(result: AccessKey(nonce: 1, permission: .fullAccess)))
            return self.ok(req, body: body)
        }
        _ = try await client.viewAccessKey(.init(accountId: "alice", publicKey: "ed25519:XYZ", finality: .final))

        // 6) viewAccessKeyList
        URLProtocolMock.handler = { req in
            let body = try JSONEncoder().encode(Out(result: ViewAccessKeyListResult(keys: [])))
            return self.ok(req, body: body)
        }
        _ = try await client.viewAccessKeyList(.init(accountId: "alice", finality: .final))

        // 7) viewCode
        URLProtocolMock.handler = { req in
            let body = try JSONEncoder().encode(Out(result: ViewCodeResult(codeBase64: "YQ==", hash: "0xHASH")))
            return self.ok(req, body: body)
        }
        _ = try await client.viewCode(.init(accountId: "alice", finality: .final))

        // 8) viewState
        URLProtocolMock.handler = { req in
            let body = try JSONEncoder().encode(Out(result: ViewStateResult(values: [], proof: nil)))
            return self.ok(req, body: body)
        }
        _ = try await client.viewState(.init(accountId: "alice", finality: .final, prefixBase64: ""))

        // 9) accountChanges
        URLProtocolMock.handler = { req in
            let body = try JSONEncoder().encode(Out(result: StateChangesResult(changes: [], blockHash: nil)))
            return self.ok(req, body: body)
        }
        _ = try await client.accountChanges(.init(accountIds: ["a"], finality: .final))

        // 10) getGenesisConfig
        URLProtocolMock.handler = { req in
            let body = try JSONEncoder().encode(Out(result: GenesisConfig(chainId: nil, protocolVersion: nil, validators: nil)))
            return self.ok(req, body: body)
        }
        _ = try await client.getGenesisConfig()

        // 11) getProtocolConfig
        URLProtocolMock.handler = { req in
            let body = try JSONEncoder().encode(Out(result: JSONValue.object([:])))
            return self.ok(req, body: body)
        }
        _ = try await client.getProtocolConfig(.init(finality: .final))

        // 12) sendTransaction
        URLProtocolMock.handler = { req in
            let body = try JSONEncoder().encode(Out(result: FinalExecutionOutcome(status: nil, transaction: nil, transactionOutcome: nil, receiptsOutcome: nil)))
            return self.ok(req, body: body)
        }
        _ = try await client.sendTransaction(.init(signedTxBase64: "AA"))

        // 13) broadcastTxAsync
        URLProtocolMock.handler = { req in
            let body = try JSONEncoder().encode(Out(result: "hash123"))
            return self.ok(req, body: body)
        }
        _ = try await client.broadcastTxAsync(base64: "AA")

        // 14) broadcastTxCommit
        URLProtocolMock.handler = { req in
            let body = try JSONEncoder().encode(Out(result: FinalExecutionOutcome(status: nil, transaction: nil, transactionOutcome: nil, receiptsOutcome: nil)))
            return self.ok(req, body: body)
        }
        _ = try await client.broadcastTxCommit(base64: "AA")

        // 15) txStatus
        URLProtocolMock.handler = { req in
            let body = try JSONEncoder().encode(Out(result: FinalExecutionOutcome(status: nil, transaction: nil, transactionOutcome: nil, receiptsOutcome: nil)))
            return self.ok(req, body: body)
        }
        _ = try await client.txStatus(.init(txHash: "0xH", senderAccountId: "alice"))

        // 16) lightClientProof
        URLProtocolMock.handler = { req in
            let body = try JSONEncoder().encode(Out(result: LightClientExecutionProof(proof: nil)))
            return self.ok(req, body: body)
        }
        _ = try await client.lightClientProof(.transaction(txHash: "tx", senderId: "alice", head: "head"))

        // 17) nextLightClientBlock (nil) con objeto → parsea objeto
        URLProtocolMock.handler = { req in
            let body = try JSONEncoder().encode(Out(result: JSONValue.object([:])))
            return self.ok(req, body: body)
        }
        _ = try await client.nextLightClientBlock(lastKnownHash: nil)

        // 18) nextLightClientBlock (no objeto) → debe dar nil
        URLProtocolMock.handler = { req in
            let body = try JSONEncoder().encode(Out(result: JSONValue.string("nope")))
            return self.ok(req, body: body)
        }
        let none = try await client.nextLightClientBlock(lastKnownHash: nil)
        XCTAssertNil(none)
    }

    func test_call_http_error_and_missing_result() async {
        let client = makeClient()

        // HTTP != 2xx → URLError(.badServerResponse)
        URLProtocolMock.handler = { req in
            let resp = HTTPURLResponse(url: req.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (resp, Data("{}".utf8))
        }
        await XCTAssertAsyncThrowsError {
            _ = try await client.viewState(.init(accountId: "a", finality: .final, prefixBase64: "")) as ViewStateResult
        }

        // { "result": null } sin "error" → cannotParseResponse
        URLProtocolMock.handler = { req in
            let body = Data(#"{"jsonrpc":"2.0","id":"1","result":null}"#.utf8)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (resp, body)
        }
        await XCTAssertAsyncThrowsError {
            _ = try await client.getGenesisConfig() as GenesisConfig
        }
    }
}
