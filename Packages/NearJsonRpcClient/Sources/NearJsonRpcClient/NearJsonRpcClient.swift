import Foundation
import NearJsonRpcTypes

// MARK: - Envoltorios JSON-RPC (lado cliente; distintos a los de Types)

public struct JsonRpcRequest<Params: Encodable>: Encodable {
    public let jsonrpc = "2.0"
    public var id: String
    public let method: String
    public let params: Params?

    public init(id: String = UUID().uuidString, method: String, params: Params?) {
        self.id = id
        self.method = method
        self.params = params
    }
}

public struct JsonRpcErrorObject: Decodable, Error {
    public let code: Int
    public let message: String
    public let data: JSONValue?
}

public struct JsonRpcEnvelope<Result: Decodable>: Decodable {
    public let jsonrpc: String
    public let id: JSONValue?
    public let result: Result?
    public let error: JsonRpcErrorObject?
}

// MARK: - Cliente

public final class NearJsonRpcClient {
    public struct Config {
        public let endpoint: URL
        public var headers: [String: String] = ["Content-Type": "application/json"]
        public var timeout: TimeInterval = 30
        public init(endpoint: URL, headers: [String: String] = [:], timeout: TimeInterval = 30) {
            self.endpoint = endpoint
            self.headers.merge(headers, uniquingKeysWith: { _, new in new })
            self.timeout = timeout
        }
    }

    private let cfg: Config
    private let session: URLSession

    public init(_ cfg: Config, session: URLSession = .shared) {
        self.cfg = cfg
        self.session = session
    }

    // MARK: - Core call

    public func call<Result: Decodable>(
        method: String,
        params: (some Encodable)? = nil,
        requestId: String = UUID().uuidString
    ) async throws -> Result {
        // Fuerza path raíz "/"
        var comps = URLComponents(url: cfg.endpoint, resolvingAgainstBaseURL: false)!
        comps.path = "/" // <- REQUERIMIENTO tests: siempre "/"
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "POST"
        req.timeoutInterval = cfg.timeout

        // Headers por defecto y merge de custom
        if req.value(forHTTPHeaderField: "Content-Type") == nil {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if req.value(forHTTPHeaderField: "Accept") == nil {
            req.setValue("application/json", forHTTPHeaderField: "Accept")
        }
        for (k, v) in cfg.headers {
            req.setValue(v, forHTTPHeaderField: k)
        }

        // Encode envelope
        let enc = JSONEncoder()
        let envelope = JsonRpcRequest(id: requestId, method: method, params: params)
        req.httpBody = try enc.encode(envelope)

        // Red
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw URLError(.init(rawValue: http.statusCode))
        }

        // Decode tolerante snake/camel
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        let env = try dec.decode(JsonRpcEnvelope<Result>.self, from: data)

        if let e = env.error { throw e }
        guard let result = env.result else { throw URLError(.cannotParseResponse) }
        return result
    }

    // MARK: - Raw JSON-RPC (para power users / tests)

    public func rawCall<R: Decodable>(
        method: String,
        params: some Encodable,
        decode _: R.Type = R.self
    ) async throws -> R {
        // 1) Envelope
        let encoder = JSONEncoder()
        let envelope = JsonRpcRequest(id: UUID().uuidString, method: method, params: params)
        let body = try encoder.encode(envelope)

        // 2) Request con slash raíz y headers
        var comps = URLComponents(url: cfg.endpoint, resolvingAgainstBaseURL: false)!
        comps.path = "/"
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "POST"
        req.httpBody = body
        req.timeoutInterval = cfg.timeout
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (k, v) in cfg.headers {
            req.setValue(v, forHTTPHeaderField: k)
        }

        // 3) Red
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        // 4) Decode envelope
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let env = try decoder.decode(JsonRpcEnvelope<R>.self, from: data)
        if let r = env.result { return r }
        if let e = env.error { throw e }
        throw URLError(.cannotDecodeRawData)
    }
}

// MARK: - Parámetros & Tipos helpers (idénticos a los de Types)

public enum Finality: String, Codable { case optimistic, final }

public enum BlockId: Codable, Equatable {
    case height(Int), hash(String)
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case let .height(h): try c.encode(h)
        case let .hash(s): try c.encode(s)
        }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let i = try? c.decode(Int.self) { self = .height(i); return }
        if let s = try? c.decode(String.self) { self = .hash(s); return }
        throw DecodingError.typeMismatch(BlockId.self, .init(codingPath: decoder.codingPath, debugDescription: "Not a height/hash"))
    }
}

public struct BlockParams: Encodable {
    public var finality: Finality?
    public var block_id: BlockId?
    public init(finality: Finality) { self.finality = finality; block_id = nil }
    public init(blockId: BlockId) { block_id = blockId; finality = nil }
}

public struct ChunkParams: Encodable {
    public var chunk_id: String?
    public var block_id: BlockId?
    public var shard_id: Int?
    public init(chunkId: String) { chunk_id = chunkId }
    public init(blockId: BlockId, shardId: Int) { block_id = blockId; shard_id = shardId }
}

public enum ValidatorsParams: Encodable {
    case current
    case byEpochId(String)
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .current:
            try c.encode([JSONValue.null]) // tests esperan [null]
        case let .byEpochId(id):
            try c.encode(["epoch_id": id])
        }
    }
}

public enum WaitUntil: String, Codable {
    case none = "NONE"
    case includedOptimistic = "INCLUDED_OPTIMISTIC"
    case executedOptimistic = "EXECUTED_OPTIMISTIC" // default
    case includedFinal = "INCLUDED_FINAL"
    case executed = "EXECUTED"
    case final = "FINAL"
}

public struct SendTxParams: Encodable {
    public let signed_tx_base64: String
    public var wait_until: WaitUntil?
    public init(signedTxBase64: String, waitUntil: WaitUntil? = nil) {
        signed_tx_base64 = signedTxBase64
        wait_until = waitUntil
    }
}

public struct TxStatusParams: Encodable {
    public let tx_hash: String
    public let sender_account_id: String
    public var wait_until: WaitUntil?
    public init(txHash: String, senderAccountId: String, waitUntil: WaitUntil? = nil) {
        tx_hash = txHash
        sender_account_id = senderAccountId
        wait_until = waitUntil
    }
}

// Query params
public struct ViewAccountParams: Encodable {
    public let request_type = "view_account"
    public var finality: Finality?
    public var block_id: BlockId?
    public let account_id: String
    public init(accountId: String, finality: Finality) { account_id = accountId; self.finality = finality }
    public init(accountId: String, blockId: BlockId) { account_id = accountId; block_id = blockId }
}

public struct ViewCodeParams: Encodable {
    public let request_type = "view_code"
    public var finality: Finality?
    public var block_id: BlockId?
    public let account_id: String
    public init(accountId: String, finality: Finality) { account_id = accountId; self.finality = finality }
    public init(accountId: String, blockId: BlockId) { account_id = accountId; block_id = blockId }
}

public struct ViewStateParams: Encodable {
    public let request_type = "view_state"
    public var finality: Finality?
    public var block_id: BlockId?
    public let account_id: String
    public let prefix_base64: String
    public init(accountId: String, finality: Finality, prefixBase64: String) {
        account_id = accountId; self.finality = finality; prefix_base64 = prefixBase64
    }

    public init(accountId: String, blockId: BlockId, prefixBase64: String) {
        account_id = accountId; block_id = blockId; prefix_base64 = prefixBase64
    }
}

public struct ViewAccessKeyParams: Encodable {
    public let request_type = "view_access_key"
    public var finality: Finality?
    public var block_id: BlockId?
    public let account_id: String
    public let public_key: String
    public init(accountId: String, publicKey: String, finality: Finality) {
        account_id = accountId; public_key = publicKey; self.finality = finality
    }
}

public struct ViewAccessKeyListParams: Encodable {
    public let request_type = "view_access_key_list"
    public var finality: Finality?
    public var block_id: BlockId?
    public let account_id: String
    public init(accountId: String, finality: Finality) {
        account_id = accountId; self.finality = finality
    }
}

public struct ChangesAccountParams: Encodable {
    public let changes_type = "account_changes"
    public let account_ids: [String]
    public var finality: Finality?
    public var block_id: BlockId?
    public init(accountIds: [String], blockId: BlockId) { account_ids = accountIds; block_id = blockId }
    public init(accountIds: [String], finality: Finality) { account_ids = accountIds; self.finality = finality }
}

// Protocol / Genesis
public struct ProtocolConfigParams: Encodable {
    public var finality: Finality?
    public var block_id: BlockId?
    public init(finality: Finality) { self.finality = finality }
    public init(blockId: BlockId) { block_id = blockId }
}

// Light client
public struct LightClientProofParams: Encodable {
    public enum ProofType: String, Codable { case transaction, receipt }
    public let type: ProofType
    public let transaction_hash: String?
    public let sender_id: String?
    public let receipt_id: String?
    public let light_client_head: String
    public static func transaction(txHash: String, senderId: String, head: String) -> Self {
        .init(type: .transaction, transaction_hash: txHash, sender_id: senderId, receipt_id: nil, light_client_head: head)
    }

    public static func receipt(receiptId: String, head: String) -> Self {
        .init(type: .receipt, transaction_hash: nil, sender_id: nil, receipt_id: receiptId, light_client_head: head)
    }
}

// MARK: - Métodos tipados

public extension NearJsonRpcClient {
    // Bloques / Chunks / Validadores
    func block(_ p: BlockParams) async throws -> BlockView { try await call(method: "block", params: p) }
    func chunk(_ p: ChunkParams) async throws -> ChunkView { try await call(method: "chunk", params: p) }
    func validators(_ p: ValidatorsParams = .current) async throws -> EpochValidatorInfo { try await call(method: "validators", params: p) }

    // Query / Accounts / Contracts
    func viewAccount(_ p: ViewAccountParams) async throws -> ViewAccountResult { try await call(method: "query", params: p) }
    func viewAccessKey(_ p: ViewAccessKeyParams) async throws -> ViewAccessKeyResult { try await call(method: "query", params: p) }
    func viewAccessKeyList(_ p: ViewAccessKeyListParams) async throws -> ViewAccessKeyListResult { try await call(method: "query", params: p) }
    func viewCode(_ p: ViewCodeParams) async throws -> ViewCodeResult { try await call(method: "query", params: p) }
    func viewState(_ p: ViewStateParams) async throws -> ViewStateResult { try await call(method: "query", params: p) }
    func accountChanges(_ p: ChangesAccountParams) async throws -> StateChangesResult { try await call(method: "changes", params: p) }

    // Protocolo / Génesis
    func getGenesisConfig() async throws -> GenesisConfig { try await call(method: "EXPERIMENTAL_genesis_config", params: Int?.none) }
    func getProtocolConfig(_ p: ProtocolConfigParams) async throws -> ProtocolConfig { try await call(method: "EXPERIMENTAL_protocol_config", params: p) }

    // Transacciones
    func sendTransaction(_ p: SendTxParams) async throws -> FinalExecutionOutcome { try await call(method: "send_tx", params: p) }
    func broadcastTxAsync(base64: String) async throws -> String { try await call(method: "broadcast_tx_async", params: [base64]) }
    func broadcastTxCommit(base64: String) async throws -> FinalExecutionOutcome { try await call(method: "broadcast_tx_commit", params: [base64]) }
    func txStatus(_ p: TxStatusParams) async throws -> FinalExecutionOutcome { try await call(method: "tx", params: p) }

    // Light Client
    func lightClientProof(_ p: LightClientProofParams) async throws -> LightClientExecutionProof {
        try await call(method: "EXPERIMENTAL_light_client_proof", params: p)
    }

    func nextLightClientBlock(lastKnownHash: String?) async throws -> LightClientBlockView? {
        if let h = lastKnownHash {
            let res: JSONValue = try await call(method: "next_light_client_block", params: [h])
            if case let .object(o) = res {
                let data = try JSONEncoder().encode(JSONValue.object(o))
                let dec = JSONDecoder(); dec.keyDecodingStrategy = .convertFromSnakeCase
                return try dec.decode(LightClientBlockView.self, from: data)
            }
            return nil
        } else {
            let res: JSONValue = try await call(method: "next_light_client_block", params: [JSONValue]())
            if case let .object(o) = res {
                let data = try JSONEncoder().encode(JSONValue.object(o))
                let dec = JSONDecoder(); dec.keyDecodingStrategy = .convertFromSnakeCase
                return try dec.decode(LightClientBlockView.self, from: data)
            }
            return nil
        }
    }
}
