import Foundation

public struct ValidatorStake: Codable, Equatable {
    public let accountId: String
    public let publicKey: String
    public let stake: U128
    enum CodingKeys: String, CodingKey {
        case accountId = "account_id"
        case publicKey = "public_key"
        case stake
    }
}
public struct EpochValidatorInfo: Codable, Equatable {
    public let epochHeight: Int?
    public let currentValidators: [JSONValue]?
    public let nextValidators: [JSONValue]?
    enum CodingKeys: String, CodingKey {
        case epochHeight = "epoch_height"
        case currentValidators = "current_validators"
        case nextValidators = "next_validators"
    }
}

// Light client
public struct LightClientBlockView: Codable, Equatable {
    public let prevStateRoot: String?
    public let outcomeRoot: String?
    public let nextBpHash: String?
    public let blockMerkleRoot: String?
    public let timestamp: UInt64?
    enum CodingKeys: String, CodingKey {
        case prevStateRoot = "prev_state_root"
        case outcomeRoot = "outcome_root"
        case nextBpHash = "next_bp_hash"
        case blockMerkleRoot = "block_merkle_root"
        case timestamp
    }
}

public struct LightClientExecutionProof: Codable, Equatable {
    public let proof: JSONValue?
}
