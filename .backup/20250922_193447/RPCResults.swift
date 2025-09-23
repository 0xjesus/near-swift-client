import Foundation

public struct BlockHeader: Codable, Equatable {
    public let height: UInt64?
    public let epochId: String?
    public let hash: String?
    public init(height: UInt64? = nil, epochId: String? = nil, hash: String? = nil) {
        self.height = height; self.epochId = epochId; self.hash = hash
    }
}

public struct ChunkHeader: Codable, Equatable {
    public let chunkHash: String?
    public let heightCreated: UInt64?
    public init(chunkHash: String? = nil, heightCreated: UInt64? = nil) {
        self.chunkHash = chunkHash; self.heightCreated = heightCreated
    }
}

public struct BlockView: Codable, Equatable {
    public let author: AccountId?
    public let header: BlockHeader?
    public let chunks: [ChunkHeader]?
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

public struct ViewAccountResult: Codable, Equatable {
    public let amount: U128?
    public let locked: U128?
    public let storagePaidAt: UInt64?
    public let storageUsage: UInt64?
}

public struct AccessKey: Codable, Equatable {
    public let nonce: Nonce
    public let permission: JSONValue
}

public struct AccessKeyInfo: Codable, Equatable {
    public let publicKey: PublicKey
    public let accessKey: AccessKey
}

public typealias ViewAccessKeyResult = AccessKey

public struct ViewAccessKeyListResult: Codable, Equatable {
    public let keys: [AccessKeyInfo]
}

public struct ViewCodeResult: Codable, Equatable {
    public let codeBase64: Base64String
    public let hash: CryptoHash
}

public struct StateItem: Codable, Equatable {
    public let key: Base64String
    public let value: Base64String
}

public struct ViewStateResult: Codable, Equatable {
    public let values: [StateItem]
    public let proof: [JSONValue]?
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

public struct ProtocolConfig: Codable, Equatable {
    public let protocolVersion: UInt64?
    public let runtimeConfig: JSONValue?
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

public struct LightClientExecutionProof: Codable, Equatable {
    public let proof: JSONValue?
}

public struct LightClientBlockView: Codable, Equatable {
    public let hash: String?
    public let prevHash: String?
}
