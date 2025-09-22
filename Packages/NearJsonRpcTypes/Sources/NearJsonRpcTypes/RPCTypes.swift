import Foundation

// MARK: - JSON-RPC Base Types
public struct JSONRPCRequest<T: Encodable>: Encodable {
    public let jsonrpc: String = "2.0"
    public let id: String
    public let method: String
    public let params: T
    
    public init(id: String = UUID().uuidString, method: String, params: T) {
        self.id = id
        self.method = method
        self.params = params
    }
}

public struct JSONRPCResponse<T: Decodable>: Decodable {
    public let jsonrpc: String
    public let id: String?
    public let result: T?
    public let error: JSONRPCError?
}

public struct JSONRPCError: Codable, Error {
    public let code: Int
    public let message: String
    public let data: AnyCodable?
}

// MARK: - Helper for Any Codable
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue
        } else {
            value = NSNull()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - View Account
public struct ViewAccountRequest: Encodable {
    public let requestType: String = "view_account"
    public let finality: String?
    public let blockId: BlockHeight?
    public let accountId: AccountId
    
    public init(accountId: AccountId, finality: String? = "optimistic", blockId: BlockHeight? = nil) {
        self.accountId = accountId
        self.finality = finality
        self.blockId = blockId
    }
    
    private enum CodingKeys: String, CodingKey {
        case requestType = "request_type"
        case finality
        case blockId = "block_id"
        case accountId = "account_id"
    }
}

public struct Account: Codable {
    public let amount: Balance
    public let lockedAmount: Balance
    public let codeHash: Hash
    public let storageUsage: UInt64
    public let storagePaidAt: BlockHeight
    public let blockHeight: BlockHeight
    public let blockHash: Hash
    
    private enum CodingKeys: String, CodingKey {
        case amount
        case lockedAmount = "locked_amount"
        case codeHash = "code_hash"
        case storageUsage = "storage_usage"
        case storagePaidAt = "storage_paid_at"
        case blockHeight = "block_height"
        case blockHash = "block_hash"
    }
}

// MARK: - Function Call
public struct FunctionCallRequest: Encodable {
    public let requestType: String = "call_function"
    public let finality: String?
    public let blockId: BlockHeight?
    public let accountId: AccountId
    public let methodName: String
    public let argsBase64: Base64String
    
    public init(accountId: AccountId, methodName: String, argsBase64: Base64String, finality: String? = "optimistic", blockId: BlockHeight? = nil) {
        self.accountId = accountId
        self.methodName = methodName
        self.argsBase64 = argsBase64
        self.finality = finality
        self.blockId = blockId
    }
    
    private enum CodingKeys: String, CodingKey {
        case requestType = "request_type"
        case finality
        case blockId = "block_id"
        case accountId = "account_id"
        case methodName = "method_name"
        case argsBase64 = "args_base64"
    }
}

public struct FunctionCallResult: Codable {
    public let result: [UInt8]
    public let logs: [String]
    public let blockHeight: BlockHeight
    public let blockHash: Hash
    
    private enum CodingKeys: String, CodingKey {
        case result
        case logs
        case blockHeight = "block_height"
        case blockHash = "block_hash"
    }
}

// MARK: - Transaction Status
public struct TxStatusRequest: Encodable {
    public let txHash: Hash
    public let senderId: AccountId
    
    public init(txHash: Hash, senderId: AccountId) {
        self.txHash = txHash
        self.senderId = senderId
    }
    
    private enum CodingKeys: String, CodingKey {
        case txHash = "tx_hash"
        case senderId = "sender_id"
    }
}

// MARK: - Block
public struct BlockRequest: Encodable {
    public let finality: String?
    public let blockId: BlockHeight?
    
    public init(finality: String? = "final", blockId: BlockHeight? = nil) {
        self.finality = finality
        self.blockId = blockId
    }
    
    private enum CodingKeys: String, CodingKey {
        case finality
        case blockId = "block_id"
    }
}

public struct Block: Codable {
    public let author: AccountId
    public let header: BlockHeader
    public let chunks: [ChunkHeader]
}

public struct BlockHeader: Codable {
    public let height: BlockHeight
    public let epochId: String
    public let prevHash: Hash
    public let prevStateRoot: Hash
    public let timestamp: UInt64
    public let timestampNanosec: String
    public let randomValue: String
    public let gasPrice: Balance
    public let totalSupply: Balance
    public let challengesRoot: String
    
    private enum CodingKeys: String, CodingKey {
        case height
        case epochId = "epoch_id"
        case prevHash = "prev_hash"
        case prevStateRoot = "prev_state_root"
        case timestamp
        case timestampNanosec = "timestamp_nanosec"
        case randomValue = "random_value"
        case gasPrice = "gas_price"
        case totalSupply = "total_supply"
        case challengesRoot = "challenges_root"
    }
}

public struct ChunkHeader: Codable {
    public let chunkHash: Hash
    public let prevBlockHash: Hash
    public let heightCreated: BlockHeight
    public let heightIncluded: BlockHeight
    public let shardId: UInt64
    public let gasUsed: Gas
    public let gasLimit: Gas
    
    private enum CodingKeys: String, CodingKey {
        case chunkHash = "chunk_hash"
        case prevBlockHash = "prev_block_hash"
        case heightCreated = "height_created"
        case heightIncluded = "height_included"
        case shardId = "shard_id"
        case gasUsed = "gas_used"
        case gasLimit = "gas_limit"
    }
}
