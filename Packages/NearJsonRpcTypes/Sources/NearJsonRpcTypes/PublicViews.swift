import Foundation

/// Resultado flexible para `gas_price`.
/// Campos opcionales para tolerar variaciones del nodo.
public struct NearGasPriceView: Codable, Equatable {
    public let gasPrice: String?
    public let blockHeight: UInt64?
    public let blockHash: String?

    public init(gasPrice: String?, blockHeight: UInt64? = nil, blockHash: String? = nil) {
        self.gasPrice = gasPrice
        self.blockHeight = blockHeight
        self.blockHash = blockHash
    }

    private enum CodingKeys: String, CodingKey {
        case gasPrice = "gas_price"
        case blockHeight = "block_height"
        case blockHash = "block_hash"
    }
}

/// Resultado flexible para `validators`.
/// Usa JSONValue en los subárboles volátiles (listas de validadores, proposals, kickouts, etc.).
public struct NearEpochValidatorInfo: Codable, Equatable {
    public let epochHeight: UInt64?
    public let epochStartHeight: UInt64?
    public let currentValidators: JSONValue?
    public let nextValidators: JSONValue?
    public let currentProposals: JSONValue?
    public let prevEpochKickout: JSONValue?

    public init(
        epochHeight: UInt64? = nil,
        epochStartHeight: UInt64? = nil,
        currentValidators: JSONValue? = nil,
        nextValidators: JSONValue? = nil,
        currentProposals: JSONValue? = nil,
        prevEpochKickout: JSONValue? = nil
    ) {
        self.epochHeight = epochHeight
        self.epochStartHeight = epochStartHeight
        self.currentValidators = currentValidators
        self.nextValidators = nextValidators
        self.currentProposals = currentProposals
        self.prevEpochKickout = prevEpochKickout
    }

    private enum CodingKeys: String, CodingKey {
        case epochHeight = "epoch_height"
        case epochStartHeight = "epoch_start_height"
        case currentValidators = "current_validators"
        case nextValidators = "next_validators"
        case currentProposals = "current_proposals"
        case prevEpochKickout = "prev_epoch_kickout"
    }
}
