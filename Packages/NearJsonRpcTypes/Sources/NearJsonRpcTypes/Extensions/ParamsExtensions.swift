import Foundation

public struct BlockParams: Encodable {
    public let blockId: JSONValue?
    public let finality: String?
    public init(blockId: JSONValue? = nil, finality: String? = "final") {
        self.blockId = blockId; self.finality = finality
    }
}

public struct ChunkParams: Encodable {
    public let chunkId: String?
    public let blockId: JSONValue?
    public init(chunkId: String? = nil, blockId: JSONValue? = nil) {
        self.chunkId = chunkId; self.blockId = blockId
    }
}

public struct ValidatorsParams: Encodable {
    public let epochId: String?
    public let blockId: JSONValue?
    public init(epochId: String? = nil, blockId: JSONValue? = nil) {
        self.epochId = epochId; self.blockId = blockId
    }

    public static let current = ValidatorsParams()
}

public struct ViewAccountParams: Encodable {
    public let requestType: String = "view_account"
    public let accountId: AccountId
    public let finality: String?
    public let blockId: JSONValue?
    public init(accountId: AccountId, finality: String? = "optimistic", blockId: JSONValue? = nil) {
        self.accountId = accountId; self.finality = finality; self.blockId = blockId
    }
}

public struct ViewAccessKeyParams: Encodable {
    public let requestType: String = "view_access_key"
    public let accountId: AccountId
    public let publicKey: PublicKey
    public init(accountId: AccountId, publicKey: PublicKey) {
        self.accountId = accountId; self.publicKey = publicKey
    }
}

public struct ViewAccessKeyListParams: Encodable {
    public let requestType: String = "view_access_key_list"
    public let accountId: AccountId
    public init(accountId: AccountId) { self.accountId = accountId }
}

public struct ViewCodeParams: Encodable {
    public let requestType: String = "view_code"
    public let accountId: AccountId
    public init(accountId: AccountId) { self.accountId = accountId }
}

public struct ViewStateParams: Encodable {
    public let requestType: String = "view_state"
    public let accountId: AccountId
    public let prefixBase64: Base64String
    public let finality: String?
    public let blockId: JSONValue?
    public init(accountId: AccountId, prefixBase64: Base64String, finality: String? = "optimistic", blockId: JSONValue? = nil) {
        self.accountId = accountId; self.prefixBase64 = prefixBase64; self.finality = finality; self.blockId = blockId
    }
}

public struct ChangesAccountParams: Encodable {
    public let changesType: String = "account_changes"
    public let accountIds: [AccountId]
    public let finality: String?
    public let blockId: JSONValue?
    public init(accountIds: [AccountId], finality: String? = "final", blockId: JSONValue? = nil) {
        self.accountIds = accountIds; self.finality = finality; self.blockId = blockId
    }
}

public struct ProtocolConfigParams: Encodable {
    public let finality: String?
    public let blockId: JSONValue?
    public init(finality: String? = "final", blockId: JSONValue? = nil) {
        self.finality = finality; self.blockId = blockId
    }
}

public struct SendTxParams: Encodable {
    public let signedTxBase64: String
    public init(signedTxBase64: String) { self.signedTxBase64 = signedTxBase64 }
}

public struct TxStatusParams: Encodable {
    public let txHash: String
    public let senderId: AccountId
    public init(txHash: String, senderId: AccountId) { self.txHash = txHash; self.senderId = senderId }
}

public struct LightClientProofParams: Encodable {
    public let outcomeId: String
    public let lightClientHead: String
    public init(outcomeId: String, lightClientHead: String) {
        self.outcomeId = outcomeId; self.lightClientHead = lightClientHead
    }
}
