import Foundation

public typealias BlockView = Block

// --- helper local para decodificar con varias claves ---
private struct _NK: CodingKey {
    var stringValue: String; init?(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int? { nil }; init?(intValue _: Int) { nil }
}

private extension KeyedDecodingContainer where Key == _NK {
    func decodeIfPresent<T: Decodable>(_: T.Type, anyOf keys: [String]) throws -> T? {
        for k in keys {
            if let kk = _NK(stringValue: k), let v = try decodeIfPresent(T.self, forKey: kk) { return v }
        }
        return nil
    }
}

// -------------------------------------------------------

// ViewAccountResult ligero y tolerante (lo usan los wrappers del cliente)
public struct ViewAccountResult: Codable, Equatable {
    public let amount: U128?
    public let locked: U128?
    public let storagePaidAt: UInt64?
    public let storageUsage: UInt64?

    public init(amount: U128? = nil, locked: U128? = nil, storagePaidAt: UInt64? = nil, storageUsage: UInt64? = nil) {
        self.amount = amount
        self.locked = locked
        self.storagePaidAt = storagePaidAt
        self.storageUsage = storageUsage
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: _NK.self)
        amount = try c.decodeIfPresent(U128.self, anyOf: ["amount"])
        locked = try c.decodeIfPresent(U128.self, anyOf: ["locked", "locked_amount", "lockedAmount"])
        storagePaidAt = try c.decodeIfPresent(UInt64.self, anyOf: ["storage_paid_at", "storagePaidAt"])
        storageUsage = try c.decodeIfPresent(UInt64.self, anyOf: ["storage_usage", "storageUsage"])
    }
}

public struct ChunkView: Codable, Equatable {
    public let header: ChunkHeader?
    public let transactions: [JSONValue]?
    public let receipts: [JSONValue]?
}

public struct ValidatorStake: Codable, Equatable {
    public let accountId: String
    public let publicKey: String
    public let stake: U128
}

public struct EpochValidatorInfo: Codable, Equatable {
    public let currentValidators: [ValidatorStake]?
    public let nextValidators: [ValidatorStake]?
    public let currentProposals: [JSONValue]?
    public let epochStartHeight: UInt64?
}

public struct AccessKeyInfo: Codable, Equatable {
    public let publicKey: PublicKey
    public let accessKey: AccessKey
}

public typealias ViewAccessKeyResult = AccessKey

public struct ViewAccessKeyListResult: Codable, Equatable {
    public let keys: [AccessKeyInfo]
}

public struct StateItem: Codable, Equatable {
    public let key: Base64String
    public let value: Base64String
}

public struct ViewStateResult: Codable, Equatable {
    public let values: [StateItem]
    public let proof: [JSONValue]?
}

public struct ViewCodeResult: Codable, Equatable {
    public let codeBase64: Base64String
    public let hash: CryptoHash
}

public struct StateChangesResult: Codable, Equatable {
    public let changes: [JSONValue]
    public let blockHash: CryptoHash?
}

public struct GenesisConfig: Codable, Equatable {
    public let chainId: String?
    public let protocolVersion: UInt64?
    public let validators: [ValidatorStake]?
}

public struct ExecutionOutcome: Codable, Equatable {
    public let logs: [String]?
    public let receiptIds: [String]?
    public let gasBurnt: UInt64?
    public let tokensBurnt: U128?
    public let executorId: AccountId?
    public let status: JSONValue?
}

public struct FinalExecutionOutcome: Codable, Equatable {
    public let status: JSONValue?
    public let transaction: JSONValue?
    public let transactionOutcome: ExecutionOutcome?
    public let receiptsOutcome: [ExecutionOutcome]?
}

public struct LightClientExecutionProof: Codable, Equatable { public let proof: JSONValue? }
public struct LightClientBlockView: Codable, Equatable { public let hash: String?; public let prevHash: String? }
public typealias ProtocolConfig = JSONValue
