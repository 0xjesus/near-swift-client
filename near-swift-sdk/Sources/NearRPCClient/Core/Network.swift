import Foundation

/// NEAR network configurations
public enum Network {
    case mainnet
    case testnet
    case betanet
    case localnet
    case custom(URL)
    
    /// The RPC endpoint URL for the network
    public var url: URL {
        switch self {
        case .mainnet:
            return URL(string: "https://rpc.mainnet.near.org")!
        case .testnet:
            return URL(string: "https://rpc.testnet.near.org")!
        case .betanet:
            return URL(string: "https://rpc.betanet.near.org")!
        case .localnet:
            return URL(string: "http://localhost:8332")!
        case .custom(let url):
            return url
        }
    }
    
    /// Network identifier
    public var chainId: String {
        switch self {
        case .mainnet:
            return "mainnet"
        case .testnet:
            return "testnet"
        case .betanet:
            return "betanet"
        case .localnet:
            return "localnet"
        case .custom:
            return "custom"
        }
    }
}
