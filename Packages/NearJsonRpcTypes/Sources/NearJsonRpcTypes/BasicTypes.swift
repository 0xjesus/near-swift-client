import Foundation

// MARK: - Basic NEAR Types
public typealias AccountId = String
public typealias PublicKey = String
public typealias BlockHeight = UInt64
public typealias Nonce = UInt64
public typealias Gas = UInt64
public typealias Balance = String // U128 as String
public typealias Hash = String
public typealias Base64String = String
public typealias Base58String = String

// MARK: - U128 Type
public struct U128: Codable, Equatable {
    public let value: String
    
    public init(_ value: String) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(String.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - U64 Type
public struct U64: Codable, Equatable {
    public let value: String
    
    public init(_ value: String) {
        self.value = value
    }
}

// MARK: - Block Reference
public enum BlockReference: Codable, Equatable {
    case blockId(BlockId)
    case finality(Finality)
    
    public enum Finality: String, Codable {
        case final
        case optimistic
    }
    
    public enum BlockId: Codable, Equatable {
        case height(BlockHeight)
        case hash(Hash)
    }
}

// MARK: - Action Types
public enum Action: Codable, Equatable {
    case createAccount
    case deployContract(DeployContractAction)
    case functionCall(FunctionCallAction)
    case transfer(TransferAction)
    case stake(StakeAction)
    case addKey(AddKeyAction)
    case deleteKey(DeleteKeyAction)
    case deleteAccount(DeleteAccountAction)
}

public struct DeployContractAction: Codable, Equatable {
    public let code: Base64String
}

public struct FunctionCallAction: Codable, Equatable {
    public let methodName: String
    public let args: Base64String
    public let gas: Gas
    public let deposit: Balance
}

public struct TransferAction: Codable, Equatable {
    public let deposit: Balance
}

public struct StakeAction: Codable, Equatable {
    public let stake: Balance
    public let publicKey: PublicKey
}

public struct AddKeyAction: Codable, Equatable {
    public let publicKey: PublicKey
    public let accessKey: AccessKey
}

public struct DeleteKeyAction: Codable, Equatable {
    public let publicKey: PublicKey
}

public struct DeleteAccountAction: Codable, Equatable {
    public let beneficiaryId: AccountId
}

// MARK: - Access Key
public struct AccessKey: Codable, Equatable {
    public let nonce: Nonce
    public let permission: Permission
    
    public enum Permission: Codable, Equatable {
        case fullAccess
        case functionCall(FunctionCallPermission)
    }
}

public struct FunctionCallPermission: Codable, Equatable {
    public let allowance: Balance?
    public let receiverId: AccountId
    public let methodNames: [String]
}
