import Foundation

public struct ViewAccountResult: Codable, Equatable {
    public let amount: U128?
    public let locked: U128?
    public let storagePaidAt: Int?
    public let storageUsage: Int?
    public let blockHash: String?
    public let blockHeight: Int?
    enum CodingKeys: String, CodingKey {
        case amount, locked
        case storagePaidAt = "storage_paid_at"
        case storageUsage = "storage_usage"
        case blockHash = "block_hash"
        case blockHeight = "block_height"
    }
}

public struct ViewCodeResult: Codable, Equatable {
    public let codeBase64: String?
    public let hash: String?
    public let blockHash: String?
    public let blockHeight: Int?
    enum CodingKeys: String, CodingKey {
        case codeBase64 = "code_base64"
        case hash
        case blockHash = "block_hash"
        case blockHeight = "block_height"
    }
}

public struct ViewStateItem: Codable, Equatable {
    public let key: String
    public let value: String
    public let proof: JSONValue?
}
public struct ViewStateResult: Codable, Equatable {
    public let values: [ViewStateItem]
    public let blockHash: String?
    public let blockHeight: Int?
    public let proof: JSONValue?
    enum CodingKeys: String, CodingKey {
        case values
        case blockHash = "block_hash"
        case blockHeight = "block_height"
        case proof
    }
}

// Access keys
public struct AccessKeyPermission: Codable, Equatable {
    public let permission: JSONValue // FullAccess | { FunctionCall { allowance, method_names, receiver_id } }
}
public struct ViewAccessKeyResult: Codable, Equatable {
    public let blockHash: String?
    public let blockHeight: Int?
    public let nonce: Int?
    public let permission: JSONValue?
    enum CodingKeys: String, CodingKey {
        case blockHash = "block_hash"
        case blockHeight = "block_height"
        case nonce, permission
    }
}
public struct AccessKeyItem: Codable, Equatable {
    public let publicKey: String
    public let accessKey: JSONValue
    enum CodingKeys: String, CodingKey {
        case publicKey = "public_key"
        case accessKey = "access_key"
    }
}
public struct ViewAccessKeyListResult: Codable, Equatable {
    public let blockHash: String?
    public let blockHeight: Int?
    public let keys: [AccessKeyItem]
    enum CodingKeys: String, CodingKey {
        case blockHash = "block_hash"
        case blockHeight = "block_height"
        case keys
    }
}
