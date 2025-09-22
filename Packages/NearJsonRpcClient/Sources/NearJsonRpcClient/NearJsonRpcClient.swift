import Foundation
import NearJsonRpcTypes

// MARK: - Envoltorios JSON-RPC
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
        public var headers: [String:String] = ["Content-Type": "application/json"]
        public var timeout: TimeInterval = 30
        public init(endpoint: URL, headers: [String:String] = [:], timeout: TimeInterval = 30) {
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

    // Lanza POST al root "/" SIEMPRE (path consolidado)
    public func call<Params: Encodable, Result: Decodable>(
        method: String,
        params: Params? = nil,
        requestId: String = UUID().uuidString
    ) async throws -> Result {
        var url = cfg.endpoint
        // Aseguramos path "/"
        if url.path.isEmpty { url.appendPathComponent("") }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = cfg.timeout
        for (k,v) in cfg.headers { req.addValue(v, forHTTPHeaderField: k) }
        let enc = JSONEncoder()
        let body = JsonRpcRequest(id: requestId, method: method, params: params)
        req.httpBody = try enc.encode(body)

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            throw URLError(.init(rawValue: http.statusCode))
        }
        let dec = JSONDecoder()
        let env = try dec.decode(JsonRpcEnvelope<Result>.self, from: data)
        if let e = env.error { throw e }
        guard let result = env.result else {
            throw URLError(.cannotParseResponse)
        }
        return result
    }
}

// MARK: - Parámetros & Tipos de ayuda
public enum Finality: String, Codable { case optimistic = "optimistic", final = "final" }

public enum BlockId: Codable, Equatable {
    case height(Int), hash(String)
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .height(let h): try c.encode(h)
        case .hash(let s): try c.encode(s)
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
    public init(finality: Finality) { self.finality = finality; self.block_id = nil }
    public init(blockId: BlockId) { self.block_id = blockId; self.finality = nil }
}

public struct ChunkParams: Encodable {
    public var chunk_id: String?
    public var block_id: BlockId?
    public var shard_id: Int?
    // chunk_id o (block_id+shard_id)
    public init(chunkId: String) { self.chunk_id = chunkId }
    public init(blockId: BlockId, shardId: Int) { self.block_id = blockId; self.shard_id = shardId }
}

public enum ValidatorsParams: Encodable {
    // current -> [null]
    case current
    case byEpochId(String)
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .current:
            try c.encode([JSONValue.null])
        case .byEpochId(let id):
            try c.encode(["epoch_id": id])
        }
    }
}

// send_tx / tx
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
        self.signed_tx_base64 = signedTxBase64
        self.wait_until = waitUntil
    }
}

public struct TxStatusParams: Encodable {
    public let tx_hash: String
    public let sender_account_id: String
    public var wait_until: WaitUntil?
    public init(txHash: String, senderAccountId: String, waitUntil: WaitUntil? = nil) {
        self.tx_hash = txHash
        self.sender_account_id = senderAccountId
        self.wait_until = waitUntil
    }
}

// query: view_* y cambios
public struct ViewAccountParams: Encodable {
    public let request_type = "view_account"
    public var finality: Finality?
    public var block_id: BlockId?
    public let account_id: String
    public init(accountId: String, finality: Finality) { self.account_id = accountId; self.finality = finality }
    public init(accountId: String, blockId: BlockId) { self.account_id = accountId; self.block_id = blockId }
}
public struct ViewCodeParams: Encodable {
    public let request_type = "view_code"
    public var finality: Finality?
    public var block_id: BlockId?
    public let account_id: String
    public init(accountId: String, finality: Finality) { self.account_id = accountId; self.finality = finality }
    public init(accountId: String, blockId: BlockId) { self.account_id = accountId; self.block_id = blockId }
}
public struct ViewStateParams: Encodable {
    public let request_type = "view_state"
    public var finality: Finality?
    public var block_id: BlockId?
    public let account_id: String
    public let prefix_base64: String
    public init(accountId: String, finality: Finality, prefixBase64: String) {
        self.account_id = accountId; self.finality = finality; self.prefix_base64 = prefixBase64
    }
    public init(accountId: String, blockId: BlockId, prefixBase64: String) {
        self.account_id = accountId; self.block_id = blockId; self.prefix_base64 = prefixBase64
    }
}
public struct ViewAccessKeyParams: Encodable {
    public let request_type = "view_access_key"
    public var finality: Finality?
    public var block_id: BlockId?
    public let account_id: String
    public let public_key: String
    public init(accountId: String, publicKey: String, finality: Finality) {
        self.account_id = accountId; self.public_key = publicKey; self.finality = finality
    }
}
public struct ViewAccessKeyListParams: Encodable {
    public let request_type = "view_access_key_list"
    public var finality: Finality?
    public var block_id: BlockId?
    public let account_id: String
    public init(accountId: String, finality: Finality) {
        self.account_id = accountId; self.finality = finality
    }
}
public struct ChangesAccountParams: Encodable {
    public let changes_type = "account_changes"
    public let account_ids: [String]
    public var finality: Finality?
    public var block_id: BlockId?
    public init(accountIds: [String], blockId: BlockId) { self.account_ids = accountIds; self.block_id = blockId }
    public init(accountIds: [String], finality: Finality) { self.account_ids = accountIds; self.finality = finality }
}

// Protocol / Genesis
public struct ProtocolConfigParams: Encodable {
    public var finality: Finality?
    public var block_id: BlockId?
    public init(finality: Finality) { self.finality = finality }
    public init(blockId: BlockId) { self.block_id = blockId }
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
    func block(_ p: BlockParams) async throws -> BlockView { try await call(method: "block", params: p) } // docs: block. :contentReference[oaicite:5]{index=5}
    func chunk(_ p: ChunkParams) async throws -> ChunkView { try await call(method: "chunk", params: p) } // docs: chunk. :contentReference[oaicite:6]{index=6}
    func validators(_ p: ValidatorsParams = .current) async throws -> EpochValidatorInfo { try await call(method: "validators", params: p) } // docs: validators. :contentReference[oaicite:7]{index=7}

    // Query / Accounts / Contracts
    func viewAccount(_ p: ViewAccountParams) async throws -> ViewAccountResult {
        try await call(method: "query", params: p) // docs: query.view_account. :contentReference[oaicite:8]{index=8}
    }
    func viewAccessKey(_ p: ViewAccessKeyParams) async throws -> ViewAccessKeyResult {
        try await call(method: "query", params: p) // docs: view_access_key. :contentReference[oaicite:9]{index=9}
    }
    func viewAccessKeyList(_ p: ViewAccessKeyListParams) async throws -> ViewAccessKeyListResult {
        try await call(method: "query", params: p) // docs: view_access_key_list. :contentReference[oaicite:10]{index=10}
    }
    func viewCode(_ p: ViewCodeParams) async throws -> ViewCodeResult {
        try await call(method: "query", params: p) // docs: view_code. :contentReference[oaicite:11]{index=11}
    }
    func viewState(_ p: ViewStateParams) async throws -> ViewStateResult {
        try await call(method: "query", params: p) // docs: view_state. :contentReference[oaicite:12]{index=12}
    }
    func accountChanges(_ p: ChangesAccountParams) async throws -> StateChangesResult {
        try await call(method: "changes", params: p) // docs: changes.account_changes. :contentReference[oaicite:13]{index=13}
    }

    // Protocolo / Génesis
    func getGenesisConfig() async throws -> GenesisConfig { try await call(method: "EXPERIMENTAL_genesis_config", params: Optional<Int>.none) } // docs. :contentReference[oaicite:14]{index=14}
    func getProtocolConfig(_ p: ProtocolConfigParams) async throws -> ProtocolConfig { try await call(method: "EXPERIMENTAL_protocol_config", params: p) } // docs. :contentReference[oaicite:15]{index=15}

    // Transacciones
    func sendTransaction(_ p: SendTxParams) async throws -> FinalExecutionOutcome { try await call(method: "send_tx", params: p) } // docs. :contentReference[oaicite:16]{index=16}
    // Compatibilidad legacy (deprecados)
    func broadcastTxAsync(base64: String) async throws -> String {
        try await call(method: "broadcast_tx_async", params: [base64]) // devuelve hash; deprecado. :contentReference[oaicite:17]{index=17}
    }
    func broadcastTxCommit(base64: String) async throws -> FinalExecutionOutcome {
        try await call(method: "broadcast_tx_commit", params: [base64]) // deprecado. :contentReference[oaicite:18]{index=18}
    }
    func txStatus(_ p: TxStatusParams) async throws -> FinalExecutionOutcome {
        try await call(method: "tx", params: p) // docs: tx. :contentReference[oaicite:19]{index=19}
    }

    // Light Client
    func lightClientProof(_ p: LightClientProofParams) async throws -> LightClientExecutionProof {
        try await call(method: "EXPERIMENTAL_light_client_proof", params: p) // spec nomicon. :contentReference[oaicite:20]{index=20}
    }
    func nextLightClientBlock(lastKnownHash: String?) async throws -> LightClientBlockView? {
        // params: [<last known hash>] o []
        if let h = lastKnownHash {
            let res: JSONValue = try await call(method: "next_light_client_block", params: [h])
            if case let .object(o) = res { return try JSONDecoder().decode(LightClientBlockView.self, from: JSONSerialization.data(withJSONObject: o)) }
            return nil
        } else {
            let res: JSONValue = try await call(method: "next_light_client_block", params: [JSONValue]())
            if case let .object(o) = res { return try JSONDecoder().decode(LightClientBlockView.self, from: JSONSerialization.data(withJSONObject: o)) }
            return nil
        }
    }
}
