import Foundation

public struct GenesisConfig: Codable, Equatable {
    public let chainId: String?
    public let protocolVersion: Int?
    public let epochLength: Int?
    public let genesisTime: String?
    public let validators: [ValidatorStake]?
    enum CodingKeys: String, CodingKey {
        case chainId = "chain_id"
        case protocolVersion = "protocol_version"
        case epochLength = "epoch_length"
        case genesisTime = "genesis_time"
        case validators
    }
}
public struct ProtocolConfig: Codable, Equatable {
    public let chainId: String?
    public let genesisHeight: Int?
    public let gasLimit: UInt64?
    public let minGasPrice: String?
    enum CodingKeys: String, CodingKey {
        case chainId = "chain_id"
        case genesisHeight = "genesis_height"
        case gasLimit = "gas_limit"
        case minGasPrice = "min_gas_price"
    }
}
