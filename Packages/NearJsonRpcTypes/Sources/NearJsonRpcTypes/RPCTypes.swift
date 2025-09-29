import Foundation

// MARK: - Dynamic coding keys helpers

struct _AnyKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init?(intValue _: Int) { nil }
    init?(stringValue: String) { self.stringValue = stringValue }
}

extension KeyedDecodingContainer where Key == _AnyKey {
    func decode<T: Decodable>(_: T.Type, anyOf keys: [String]) throws -> T {
        for k in keys {
            if let key = _AnyKey(stringValue: k), let v = try decodeIfPresent(T.self, forKey: key) {
                return v
            }
        }
        throw DecodingError.keyNotFound(
            _AnyKey(stringValue: keys.first!)!,
            .init(codingPath: codingPath, debugDescription: "Neither \(keys.map { $0 }.joined(separator: "/")) present")
        )
    }
}

extension KeyedEncodingContainer where Key == _AnyKey {
    mutating func encode(_ value: some Encodable, forAnyOf keys: [String]) throws {
        guard let key = _AnyKey(stringValue: keys[0]) else { return }
        try encode(value, forKey: key)
    }
}

// MARK: - JSON-RPC request/response for Types target

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

// Generic AnyCodable used in error.data
public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let i = try? c.decode(Int.self) { value = i; return }
        if let s = try? c.decode(String.self) { value = s; return }
        if let b = try? c.decode(Bool.self) { value = b; return }
        if let d = try? c.decode(Double.self) { value = d; return }
        if let o = try? c.decode([String: AnyCodable].self) { value = o; return }
        if let a = try? c.decode([AnyCodable].self) { value = a; return }
        value = NSNull()
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case let i as Int: try c.encode(i)
        case let s as String: try c.encode(s)
        case let b as Bool: try c.encode(b)
        case let d as Double: try c.encode(d)
        default: try c.encodeNil()
        }
    }
}

// MARK: - Near primitive aliases (deberían estar ya en BasicTypes.swift)

// Aquí asumimos que ya existen en tu proyecto:
// public typealias Balance = String
// public typealias Hash = String
// public typealias BlockHeight = UInt64
// public typealias Gas = UInt64
// public typealias AccountId = String
// public typealias Base64String = String
// public typealias PublicKey = String
// public typealias CryptoHash = String
// public typealias U128 = String

// MARK: - Account

public struct Account: Codable {
    public let amount: Balance
    public let lockedAmount: Balance
    public let codeHash: Hash
    public let storageUsage: UInt64
    public let storagePaidAt: BlockHeight
    public let blockHeight: BlockHeight
    public let blockHash: Hash

    public init(
        amount: Balance,
        lockedAmount: Balance,
        codeHash: Hash,
        storageUsage: UInt64,
        storagePaidAt: BlockHeight,
        blockHeight: BlockHeight,
        blockHash: Hash
    ) {
        self.amount = amount
        self.lockedAmount = lockedAmount
        self.codeHash = codeHash
        self.storageUsage = storageUsage
        self.storagePaidAt = storagePaidAt
        self.blockHeight = blockHeight
        self.blockHash = blockHash
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: _AnyKey.self)
        amount = try c.decode(Balance.self, anyOf: ["amount"])
        // locked puede venir como "locked_amount" (snake), "locked" (legacy) o "lockedAmount" (camel)
        lockedAmount = (try? c.decode(Balance.self, anyOf: ["locked_amount", "locked", "lockedAmount"])) ?? "0"
        codeHash = try c.decode(Hash.self, anyOf: ["code_hash", "codeHash"])
        storageUsage = try c.decode(UInt64.self, anyOf: ["storage_usage", "storageUsage"])
        storagePaidAt = try c.decode(BlockHeight.self, anyOf: ["storage_paid_at", "storagePaidAt"])
        blockHeight = try c.decode(BlockHeight.self, anyOf: ["block_height", "blockHeight"])
        blockHash = try c.decode(Hash.self, anyOf: ["block_hash", "blockHash"])
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: _AnyKey.self)
        try c.encode(amount, forAnyOf: ["amount"])
        try c.encode(lockedAmount, forAnyOf: ["locked_amount"])
        try c.encode(codeHash, forAnyOf: ["code_hash"])
        try c.encode(storageUsage, forAnyOf: ["storage_usage"])
        try c.encode(storagePaidAt, forAnyOf: ["storage_paid_at"])
        try c.encode(blockHeight, forAnyOf: ["block_height"])
        try c.encode(blockHash, forAnyOf: ["block_hash"])
    }
}

// MARK: - Block / Headers / Chunks

public struct Block: Codable, Equatable {
    public let author: AccountId
    public let header: BlockHeader
    public let chunks: [ChunkHeader]

    public init(author: AccountId, header: BlockHeader, chunks: [ChunkHeader]) {
        self.author = author
        self.header = header
        self.chunks = chunks
    }
}

public struct BlockHeader: Codable, Equatable {
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

    public init(
        height: BlockHeight,
        epochId: String,
        prevHash: Hash,
        prevStateRoot: Hash,
        timestamp: UInt64,
        timestampNanosec: String,
        randomValue: String,
        gasPrice: Balance,
        totalSupply: Balance,
        challengesRoot: String
    ) {
        self.height = height
        self.epochId = epochId
        self.prevHash = prevHash
        self.prevStateRoot = prevStateRoot
        self.timestamp = timestamp
        self.timestampNanosec = timestampNanosec
        self.randomValue = randomValue
        self.gasPrice = gasPrice
        self.totalSupply = totalSupply
        self.challengesRoot = challengesRoot
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: _AnyKey.self)
        height = try c.decode(BlockHeight.self, anyOf: ["height"])
        epochId = try c.decode(String.self, anyOf: ["epoch_id", "epochId"])
        prevHash = try c.decode(Hash.self, anyOf: ["prev_hash", "prevHash"])
        prevStateRoot = try c.decode(Hash.self, anyOf: ["prev_state_root", "prevStateRoot"])
        timestamp = try c.decode(UInt64.self, anyOf: ["timestamp"])
        timestampNanosec = try c.decode(String.self, anyOf: ["timestamp_nanosec", "timestampNanosec"])
        randomValue = try c.decode(String.self, anyOf: ["random_value", "randomValue"])
        gasPrice = try c.decode(Balance.self, anyOf: ["gas_price", "gasPrice"])
        totalSupply = try c.decode(Balance.self, anyOf: ["total_supply", "totalSupply"])
        challengesRoot = try c.decode(String.self, anyOf: ["challenges_root", "challengesRoot"])
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: _AnyKey.self)
        try c.encode(height, forAnyOf: ["height"])
        try c.encode(epochId, forAnyOf: ["epoch_id"])
        try c.encode(prevHash, forAnyOf: ["prev_hash"])
        try c.encode(prevStateRoot, forAnyOf: ["prev_state_root"])
        try c.encode(timestamp, forAnyOf: ["timestamp"])
        try c.encode(timestampNanosec, forAnyOf: ["timestamp_nanosec"])
        try c.encode(randomValue, forAnyOf: ["random_value"])
        try c.encode(gasPrice, forAnyOf: ["gas_price"])
        try c.encode(totalSupply, forAnyOf: ["total_supply"])
        try c.encode(challengesRoot, forAnyOf: ["challenges_root"])
    }
}

// MARK: - ChunkHeader (tolerante + Equatable)

public struct ChunkHeader: Codable, Equatable {
    public let chunkHash: Hash?
    public let prevBlockHash: Hash?
    public let heightCreated: BlockHeight?
    public let heightIncluded: BlockHeight?
    public let shardId: UInt64?
    public let gasUsed: Gas?
    public let gasLimit: Gas?

    public init(
        chunkHash: Hash? = nil,
        prevBlockHash: Hash? = nil,
        heightCreated: BlockHeight? = nil,
        heightIncluded: BlockHeight? = nil,
        shardId: UInt64? = nil,
        gasUsed: Gas? = nil,
        gasLimit: Gas? = nil
    ) {
        self.chunkHash = chunkHash
        self.prevBlockHash = prevBlockHash
        self.heightCreated = heightCreated
        self.heightIncluded = heightIncluded
        self.shardId = shardId
        self.gasUsed = gasUsed
        self.gasLimit = gasLimit
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: _AnyKey.self)
        chunkHash = try c.decodeIfPresent(Hash.self, forKey: _AnyKey(stringValue: "chunk_hash")!)
        prevBlockHash = try c.decodeIfPresent(Hash.self, forKey: _AnyKey(stringValue: "prev_block_hash")!)
        heightCreated = try c.decodeIfPresent(BlockHeight.self, forKey: _AnyKey(stringValue: "height_created")!)
        heightIncluded = try c.decodeIfPresent(BlockHeight.self, forKey: _AnyKey(stringValue: "height_included")!)
        shardId = try c.decodeIfPresent(UInt64.self, forKey: _AnyKey(stringValue: "shard_id")!)
        gasUsed = try c.decodeIfPresent(Gas.self, forKey: _AnyKey(stringValue: "gas_used")!)
        gasLimit = try c.decodeIfPresent(Gas.self, forKey: _AnyKey(stringValue: "gas_limit")!)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: _AnyKey.self)
        try c.encodeIfPresent(chunkHash, forKey: _AnyKey(stringValue: "chunk_hash")!)
        try c.encodeIfPresent(prevBlockHash, forKey: _AnyKey(stringValue: "prev_block_hash")!)
        try c.encodeIfPresent(heightCreated, forKey: _AnyKey(stringValue: "height_created")!)
        try c.encodeIfPresent(heightIncluded, forKey: _AnyKey(stringValue: "height_included")!)
        try c.encodeIfPresent(shardId, forKey: _AnyKey(stringValue: "shard_id")!)
        try c.encodeIfPresent(gasUsed, forKey: _AnyKey(stringValue: "gas_used")!)
        try c.encodeIfPresent(gasLimit, forKey: _AnyKey(stringValue: "gas_limit")!)
    }
}
