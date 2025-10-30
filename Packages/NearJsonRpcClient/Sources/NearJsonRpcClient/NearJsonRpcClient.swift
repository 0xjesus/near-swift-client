import Foundation
import NearJsonRpcTypes

public typealias GasPriceView = NearGasPriceView
public typealias BlockView = NearJsonRpcTypes.Block
public typealias ChunkView = NearJsonRpcTypes.JSONValue
public typealias ViewStateResult = NearJsonRpcTypes.ViewStateResult
public typealias ProtocolConfig = NearJsonRpcTypes.ProtocolConfig
public typealias GenesisConfig = NearJsonRpcTypes.GenesisConfig
public typealias FinalExecutionOutcome = NearJsonRpcTypes.FinalExecutionOutcome
public typealias StateChangesResult = NearJsonRpcTypes.JSONValue
public typealias Account = NearJsonRpcTypes.Account
public typealias EpochValidatorInfo = NearJsonRpcTypes.EpochValidatorInfo
public typealias LightClientProof = NearJsonRpcTypes.JSONValue
public typealias LightClientBlockView = NearJsonRpcTypes.JSONValue

public enum BlockReference {
    case blockId(UInt64)
    case blockHash(String)
    case finality(Finality)

    public enum Finality: String, Codable {
        case final
        case optimistic
    }
}

extension BlockReference {
    var asBlockReference: RpcBlockReference {
        switch self {
        case let .blockId(blockId):
            .init(value1: .init(block_id: .init(value1: .init(value1: blockId))))
        case let .blockHash(blockHash):
            .init(value1: .init(block_id: .init(value2: .init(value1: blockHash))))
        case let .finality(finality):
            .init(value1: .init(finality: finality.rawValue))
        }
    }
}

public final class NearJsonRpcClient {
    public struct Config {
        public let endpoint: URL
        public let headers: [String: String]
        private let timeoutSeconds: TimeInterval

        public init(endpoint: URL, headers: [String: String] = ["Content-Type": "application/json"], timeoutSeconds: TimeInterval = 30) {
            self.endpoint = endpoint
            self.headers = headers
            self.timeoutSeconds = timeoutSeconds
        }

        public var timeout: TimeInterval { timeoutSeconds }
        public init(endpoint: URL, headers: [String: String] = ["Content-Type": "application/json"], timeout: TimeInterval) {
            self.init(endpoint: endpoint, headers: headers, timeoutSeconds: timeout)
        }
    }

    public enum EpochReference {
        case latest
        case epochId(String)
        case blockId(JSONValue)

        public static var current: Self { .latest }
        public static func byEpochId(_ id: String) -> Self { .epochId(id) }
    }

    private let config: Config
    private let session: URLSession
    private var requestId = 0

    public init(_ config: Config, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    public func status() async throws -> JSONValue {
        try await call(method: "status", params: nil as Int?)
    }

    public func networkInfo() async throws -> JSONValue {
        try await call(method: "network_info", params: [] as [String])
    }

    public func validators(_ ref: EpochReference) async throws -> EpochValidatorInfo {
        let params: ClientRPCParams
        switch ref {
        case .latest:
            params = .array([.null])
        case let .epochId(id):
            params = .array([.string(id)])
        case let .blockId(val):
            let lit = try _encodeToClientRPCLiteral(val)
            params = .array([lit])
        }
        let data = try await _rpcInvokeRawResult(method: "validators", params: params)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(EpochValidatorInfo.self, from: data)
    }

    public func block(blockReference: BlockReference) async throws -> BlockView {
        let params: Components.Schemas.RpcBlockRequest = switch blockReference {
        case let .blockId(blockId):
            .init(value1: .init(block_id: .init(value1: .init(value1: blockId))))
        case let .blockHash(blockHash):
            .init(value1: .init(block_id: .init(value2: .init(value1: blockHash))))
        case let .finality(finality):
            .init(value1: .init(finality: finality.rawValue))
        }
        return try await call(method: "block", params: params)
    }

    public func chunk(_ params: Components.Schemas.RpcChunkRequest) async throws -> ChunkView {
        try await call(method: "chunk", params: params)
    }

    public func viewAccount(accountId: String, blockReference: BlockReference = .finality(.final)) async throws -> ViewAccountResult {
        let params = RpcQueryRequest(
            blockReference: blockReference.asBlockReference,
            request: .viewAccount(.init(accountId: accountId))
        )
        return try await call(method: "query", params: params)
    }

    public func viewAccessKey(_ params: Components.Schemas.RpcQueryRequest) async throws -> JSONValue {
        try await call(method: "query", params: params)
    }

    public func viewAccessKeyList(_ params: Components.Schemas.RpcQueryRequest) async throws -> ViewAccessKeyListResult {
        try await call(method: "query", params: params)
    }

    public func viewCode(_ params: Components.Schemas.RpcQueryRequest) async throws -> ViewCodeResult {
        try await call(method: "query", params: params)
    }

    public func viewState(_ params: Components.Schemas.RpcQueryRequest) async throws -> ViewStateResult {
        try await call(method: "query", params: params)
    }

    public func gasPrice(blockId: JSONValue? = nil) async throws -> GasPriceView {
        let params: ClientRPCParams
        if let blockId {
            let lit = try _encodeToClientRPCLiteral(blockId)
            params = .array([lit])
        } else {
            params = .array([.null])
        }
        let data = try await _rpcInvokeRawResult(method: "gas_price", params: params)
        return try JSONDecoder().decode(GasPriceView.self, from: data)
    }

    private func nextId() -> Int {
        requestId += 1
        return requestId
    }

    func _rpcInvokeRawResult(method: String, params: ClientRPCParams) async throws -> Data {
        let bodyObject: [String: Any] = [
            "jsonrpc": "2.0",
            "id": nextId(),
            "method": method,
            "params": _serialize(params),
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: bodyObject)

        var request = URLRequest(url: config.endpoint)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        for (k, v) in config.headers {
            request.setValue(v, forHTTPHeaderField: k)
        }
        request.timeoutInterval = config.timeout

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "RPC", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
        }

        if let error = json["error"] {
            let errorData = try JSONSerialization.data(withJSONObject: error)
            throw NSError(domain: "RPC", code: -1, userInfo: [NSLocalizedDescriptionKey: String(data: errorData, encoding: .utf8) ?? "RPC Error"])
        }

        guard let result = json["result"] else {
            throw NSError(domain: "RPC", code: -2, userInfo: [NSLocalizedDescriptionKey: "No result in response"])
        }

        if JSONSerialization.isValidJSONObject(result) {
            return try JSONSerialization.data(withJSONObject: result)
        } else {
            if result is NSNull {
                return Data("null".utf8)
            } else if let str = result as? String {
                let escaped = str.replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                return Data("\"\(escaped)\"".utf8)
            } else if let num = result as? NSNumber {
                return Data("\(num)".utf8)
            } else {
                let wrapper = try JSONSerialization.data(withJSONObject: [result])
                var str = String(data: wrapper, encoding: .utf8)!
                str.removeFirst()
                str.removeLast()
                return Data(str.utf8)
            }
        }
    }

    private func _serialize(_ params: ClientRPCParams) -> Any {
        switch params {
        case let .array(arr):
            return arr.map(_serialize)
        case let .object(obj):
            var out: [String: Any] = [:]
            for (k, v) in obj {
                out[k] = _serialize(v)
            }
            return out
        }
    }

    private func _serialize(_ literal: ClientRPCLiteral) -> Any {
        switch literal {
        case let .int(i): i
        case let .double(d): d
        case let .bool(b): b
        case let .string(s): s
        case let .object(o): o.mapValues { _serialize($0) }
        case let .array(a): a.map { _serialize($0) }
        case .null: NSNull()
        }
    }

    func _encodeToClientRPCLiteral(_ value: Encodable) throws -> ClientRPCLiteral {
        let data = try JSONEncoder().encode(value)
        let json = try JSONSerialization.jsonObject(with: data)
        return _jsonToLiteral(json)
    }

    private func _jsonToLiteral(_ obj: Any) -> ClientRPCLiteral {
        if obj is NSNull { return .null }
        if let b = obj as? Bool { return .bool(b) }
        if let i = obj as? Int { return .int(i) }
        if let d = obj as? Double { return .double(d) }
        if let s = obj as? String { return .string(s) }
        if let arr = obj as? [Any] { return .array(arr.map(_jsonToLiteral)) }
        if let dict = obj as? [String: Any] {
            return .object(dict.mapValues { _jsonToLiteral($0) })
        }
        return .null
    }

    public func call<T: Decodable>(method: String, params: Encodable?) async throws -> T {
        let literal: ClientRPCLiteral
        if let p = params {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let data = try encoder.encode(p)
            let json = try JSONSerialization.jsonObject(with: data)
            literal = _jsonToLiteral(json)
        } else {
            literal = .null
        }
        let rpcParams = ClientRPCParams.array([literal])
        let resultData = try await _rpcInvokeRawResult(method: method, params: rpcParams)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: resultData)
    }

    public func accountChanges(_ params: Components.Schemas.RpcStateChangesInBlockByTypeRequest) async throws -> StateChangesResult {
        try await call(method: "EXPERIMENTAL_changes", params: params)
    }

    public func getGenesisConfig() async throws -> GenesisConfig {
        let params = ClientRPCParams.array([])
        let data = try await _rpcInvokeRawResult(method: "EXPERIMENTAL_genesis_config", params: params)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(GenesisConfig.self, from: data)
    }

    public func getProtocolConfig(_ params: Components.Schemas.RpcProtocolConfigRequest) async throws -> JSONValue {
        try await call(method: "EXPERIMENTAL_protocol_config", params: params)
    }

//     public func sendTransaction(_ params: Components.Schemas.RpcBroadcastTxAsyncRequest) async throws -> FinalExecutionOutcome {
//         try await call(method: "broadcast_tx_commit", params: params)
//     }

    public func broadcastTxAsync(base64: String) async throws -> String {
        let params = ClientRPCParams.array([.string(base64)])
        let data = try await _rpcInvokeRawResult(method: "broadcast_tx_async", params: params)
        let decoder = JSONDecoder()
        return try decoder.decode(String.self, from: data)
    }

    public func broadcastTxCommit(base64: String) async throws -> FinalExecutionOutcome {
        let params = ClientRPCParams.array([.string(base64)])
        let data = try await _rpcInvokeRawResult(method: "broadcast_tx_commit", params: params)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(FinalExecutionOutcome.self, from: data)
    }

    public func txStatus(_ params: Components.Schemas.RpcTransactionStatusRequest) async throws -> FinalExecutionOutcome {
        try await call(method: "tx", params: params)
    }

    public func lightClientProof(_ params: Components.Schemas.RpcLightClientExecutionProofRequest) async throws -> LightClientProof {
        try await call(method: "light_client_proof", params: params)
    }

    public func nextLightClientBlock(lastKnownHash: String?) async throws -> LightClientBlockView? {
        let params: ClientRPCParams = if let hash = lastKnownHash {
            .array([.string(hash)])
        } else {
            .array([])
        }
        let data = try await _rpcInvokeRawResult(method: "next_light_client_block", params: params)
        let decoder = JSONDecoder()
        let result = try decoder.decode(JSONValue.self, from: data)
        if case .object = result { return result }
        return nil
    }

    // Legacy alias for compatibility with old tests
    public func rawCall<T: Decodable>(method: String, params: Encodable?, decode _: T.Type = T.self) async throws -> T {
        try await call(method: method, params: params)
    }
}

public enum ClientRPCParams {
    case array([ClientRPCLiteral])
    case object([String: ClientRPCLiteral])
}

public enum ClientRPCLiteral {
    case int(Int)
    case double(Double)
    case bool(Bool)
    case string(String)
    case array([ClientRPCLiteral])
    case object([String: ClientRPCLiteral])
    case null
}
